/// Loads and validates the versioned `pasweave.json` project configuration.
///
/// The configuration is strictly declarative: unknown keys, wrong types,
/// unsupported versions, absolute paths, and parent traversal that escapes the
/// configuration directory are rejected with a descriptive error. Relative
/// paths are resolved against the configuration file's directory by the
/// caller, so the effective configuration stays reproducible across machines.
unit PasWeave.Config;

{$mode objfpc}{$H+}{$J+}

interface

uses
  Classes, SysUtils, PasWeave.Comments, PasWeave.Diagnostics, PasWeave.Model;

const
  /// Supported `version` value in `pasweave.json`.
  ProjectConfigVersion = 1;
  /// Default configuration filename used with `--config` discovery.
  ProjectConfigFilename = 'pasweave.json';

type
  /// Raised for any invalid, unreadable, or unsupported configuration.
  EProjectConfigError = class(Exception);

  /// Parsed and validated `pasweave.json` contents.
  TProjectConfig = class
  public
    /// Absolute path of the loaded file.
    Filename: string;
    /// Directory used as the base for every relative path.
    Directory: string;
    /// Relative source input (`source`).
    SourcePath: string;
    /// Relative output directory (`output`).
    OutputPath: string;
    /// Project title (`project.name`).
    ProjectName: string;
    /// Header brand mark (`project.mark`).
    ProjectMark: string;
    /// Repository origin (`project.repositoryUrl`).
    RepositoryURL: string;
    /// Repository-relative line template (`project.sourceLinkTemplate`).
    SourceLinkTemplate: string;
    /// Primary accent color (`project.theme.accent`).
    ThemeAccent: string;
    /// Secondary accent color (`project.theme.accent2`).
    ThemeAccentAlt: string;
    /// Body font family (`project.theme.font`).
    ThemeFont: string;
    /// Documentation comment styles (`comments`); default `slash`.
    Comments: TDocumentationCommentStyles;
    /// True when `comments` was present.
    HasComments: Boolean;
    /// Declaration visibility policy (`visibility`).
    Visibility: TRenderVisibilityPolicy;
    /// Recursive discovery (`discovery.recursive`).
    Recursive: Boolean;
    /// Owned include/exclude globs (`discovery.include`/`exclude`).
    IncludePatterns: TStringList;
    ExcludePatterns: TStringList;
    /// Owned compiler search paths and defines.
    UnitPaths: TStringList;
    IncludePaths: TStringList;
    Defines: TStringList;
    PackagePaths: TStringList;
    /// Normalized target selection (`compiler.targetOs`/`targetCpu`).
    TargetOS: string;
    TargetCPU: string;
    /// Lazarus build mode (`compiler.buildMode`).
    BuildMode: string;
    /// Documentation coverage minimum (`coverage.minimum`).
    MinimumCoverage: Integer;
    /// True when `coverage.minimum` was present.
    HasMinimumCoverage: Boolean;
    /// Failure threshold (`coverage.failOn`); empty uses the default.
    FailOn: string;
    constructor Create;
    destructor Destroy; override;
  end;

/// Loads and validates one configuration file.
///
/// @param AFilename Path to `pasweave.json`.
/// @returns An owned configuration; the caller frees it.
/// @raises EProjectConfigError for unreadable files, invalid JSON, unknown
///   keys, wrong types, unsupported versions, or unsafe paths.
function LoadProjectConfig(const AFilename: string): TProjectConfig;

/// Stable lowercase name of a visibility policy.
function VisibilityPolicyName(APolicy: TRenderVisibilityPolicy): string;

implementation

uses
  FPJSON, JSONParser, PasWeave.Compiler, PasWeave.FS, PasWeave.Parser;

type
  TJSONKind = (jkObject, jkString, jkBoolean, jkInteger, jkArray);

procedure Fail(const AMessage: string);
begin
  raise EProjectConfigError.Create(AMessage);
end;

function KeyPath(const AParent, AKey: string): string;
begin
  if AParent = '' then
    Result := AKey
  else
    Result := AParent + '.' + AKey;
end;

procedure EnsureKnownKeys(AObject: TJSONObject;
  const AAllowed: array of string; const APath: string);
var
  I: Integer;
  J: Integer;
  Allowed: Boolean;
begin
  for I := 0 to AObject.Count - 1 do
  begin
    Allowed := False;
    for J := Low(AAllowed) to High(AAllowed) do
      if SameText(AObject.Names[I], AAllowed[J]) then
      begin
        Allowed := True;
        Break;
      end;
    if not Allowed then
      Fail('unknown configuration key: ' + KeyPath(APath, AObject.Names[I]));
  end;
end;

procedure ExpectKind(AItem: TJSONData; AKind: TJSONKind;
  const APath: string);
var
  Matches: Boolean;
begin
  case AKind of
    jkObject: Matches := AItem.JSONType = jtObject;
    jkString: Matches := AItem.JSONType = jtString;
    jkBoolean: Matches := AItem.JSONType = jtBoolean;
    jkInteger: Matches := AItem.JSONType = jtNumber;
    jkArray: Matches := AItem.JSONType = jtArray;
  else
    Matches := False;
  end;
  if not Matches then
    Fail('configuration key has the wrong type: ' + APath);
end;

function OptionalString(AObject: TJSONObject; const AKey, APath: string;
  out AValue: string): Boolean;
var
  Item: TJSONData;
begin
  AValue := '';
  Item := AObject.Find(AKey);
  Result := Assigned(Item);
  if not Result then
    Exit;
  ExpectKind(Item, jkString, KeyPath(APath, AKey));
  AValue := Item.AsString;
end;

function OptionalBoolean(AObject: TJSONObject; const AKey, APath: string;
  out AValue: Boolean): Boolean;
var
  Item: TJSONData;
begin
  AValue := False;
  Item := AObject.Find(AKey);
  Result := Assigned(Item);
  if not Result then
    Exit;
  ExpectKind(Item, jkBoolean, KeyPath(APath, AKey));
  AValue := Item.AsBoolean;
end;

function OptionalInteger(AObject: TJSONObject; const AKey, APath: string;
  out AValue: Integer): Boolean;
var
  Item: TJSONData;
begin
  AValue := 0;
  Item := AObject.Find(AKey);
  Result := Assigned(Item);
  if not Result then
    Exit;
  ExpectKind(Item, jkInteger, KeyPath(APath, AKey));
  AValue := Item.AsInteger;
end;

procedure AddStringArray(AObject: TJSONObject; const AKey, APath: string;
  ATarget: TStrings);
var
  Item: TJSONData;
  Elements: TJSONArray;
  I: Integer;
begin
  Item := AObject.Find(AKey);
  if not Assigned(Item) then
    Exit;
  ExpectKind(Item, jkArray, KeyPath(APath, AKey));
  Elements := TJSONArray(Item);
  for I := 0 to Elements.Count - 1 do
  begin
    if Elements[I].JSONType <> jtString then
      Fail(KeyPath(APath, AKey) + ' entries must be strings');
    ATarget.Add(Elements[I].AsString);
  end;
end;

{ Validates a relative path and rejects absolute paths and traversal that
  escapes the configuration directory. Returns the normalized original so the
  effective configuration does not depend on the host. }
function CheckRelativePath(const AValue: string;
  const APath: string): string;
var
  Normalised: string;
  Start: Integer;
  Stop: Integer;
  Segment: string;
  Depth: Integer;
begin
  Normalised := StringReplace(Trim(AValue), '\', '/', [rfReplaceAll]);
  if Normalised = '' then
    Fail(APath + ' must not be empty');
  if (Normalised[1] = '/') or
    ((Length(Normalised) >= 2) and (Normalised[2] = ':')) then
    Fail(APath + ' must be relative to the configuration directory: ' +
      AValue);
  Depth := 0;
  Start := 1;
  while Start <= Length(Normalised) do
  begin
    Stop := Start;
    while (Stop <= Length(Normalised)) and (Normalised[Stop] <> '/') do
      Inc(Stop);
    Segment := Copy(Normalised, Start, Stop - Start);
    if Segment = '' then
      Fail(APath + ' contains an empty path segment: ' + AValue)
    else if Segment = '.' then
      Fail(APath + ' must not contain "." segments: ' + AValue)
    else if Segment = '..' then
    begin
      Dec(Depth);
      if Depth < 0 then
        Fail(APath + ' escapes the configuration directory: ' + AValue);
    end
    else
      Inc(Depth);
    Start := Stop + 1;
  end;
  Result := Normalised;
end;

procedure AddPathArray(AObject: TJSONObject; const AKey, APath: string;
  ATarget: TStrings);
var
  Values: TStringList;
  I: Integer;
begin
  Values := TStringList.Create;
  try
    AddStringArray(AObject, AKey, APath, Values);
    for I := 0 to Values.Count - 1 do
      ATarget.Add(CheckRelativePath(Values[I],
        KeyPath(APath, AKey) + '[' + IntToStr(I) + ']'));
  finally
    Values.Free;
  end;
end;

procedure LoadComments(const AValue, APath: string;
  AConfig: TProjectConfig);
begin
  if not TryParseDocumentationCommentStyles(AValue, AConfig.Comments) then
    Fail(APath + ' is not a supported comment style: ' + AValue);
  AConfig.HasComments := True;
end;

procedure LoadVisibility(const AValue, APath: string; AConfig: TProjectConfig);
begin
  if SameText(AValue, 'public') then
    AConfig.Visibility := rvpPublicAPI
  else if SameText(AValue, 'all') then
    AConfig.Visibility := rvpAllDeclarations
  else
    Fail(APath + ' must be "public" or "all": ' + AValue);
end;

procedure LoadProjectSection(AObject: TJSONObject; AConfig: TProjectConfig);
var
  Value: string;
  Theme: TJSONData;
  ThemeObject: TJSONObject;
begin
  EnsureKnownKeys(AObject,
    ['name', 'mark', 'repositoryUrl', 'sourceLinkTemplate', 'theme'],
    'project');
  if OptionalString(AObject, 'name', 'project', Value) then
    AConfig.ProjectName := Value;
  if OptionalString(AObject, 'mark', 'project', Value) then
  begin
    if not IsValidProjectMark(Value) then
      Fail('project.mark must be 1 to 4 alphanumeric characters');
    AConfig.ProjectMark := Value;
  end;
  if OptionalString(AObject, 'repositoryUrl', 'project', Value) then
    AConfig.RepositoryURL := Value;
  if OptionalString(AObject, 'sourceLinkTemplate', 'project', Value) then
    AConfig.SourceLinkTemplate := Value;
  Theme := AObject.Find('theme');
  if not Assigned(Theme) then
    Exit;
  ExpectKind(Theme, jkObject, 'project.theme');
  ThemeObject := TJSONObject(Theme);
  EnsureKnownKeys(ThemeObject, ['accent', 'accent2', 'font'],
    'project.theme');
  if OptionalString(ThemeObject, 'accent', 'project.theme', Value) then
  begin
    if not IsValidThemeColor(Value) then
      Fail('project.theme.accent must be a #RGB, #RRGGBB, or #RRGGBBAA color');
    AConfig.ThemeAccent := Value;
  end;
  if OptionalString(ThemeObject, 'accent2', 'project.theme', Value) then
  begin
    if not IsValidThemeColor(Value) then
      Fail('project.theme.accent2 must be a #RGB, #RRGGBB, or #RRGGBBAA color');
    AConfig.ThemeAccentAlt := Value;
  end;
  if OptionalString(ThemeObject, 'font', 'project.theme', Value) then
  begin
    if not IsValidThemeFont(Value) then
      Fail('project.theme.font must be a safe font family name');
    AConfig.ThemeFont := Value;
  end;
end;

procedure LoadDiscoverySection(AObject: TJSONObject; AConfig: TProjectConfig);
var
  Value: Boolean;
  Probe: TSourceDiscoveryOptions;
  Include: TStringList;
  Exclude: TStringList;
  I: Integer;
begin
  EnsureKnownKeys(AObject, ['recursive', 'include', 'exclude'], 'discovery');
  if OptionalBoolean(AObject, 'recursive', 'discovery', Value) then
    AConfig.Recursive := Value;
  { Reuse the discovery glob validator so config and CLI rules cannot drift. }
  Include := TStringList.Create;
  Exclude := TStringList.Create;
  Probe := TSourceDiscoveryOptions.Create;
  try
    AddStringArray(AObject, 'include', 'discovery', Include);
    AddStringArray(AObject, 'exclude', 'discovery', Exclude);
    try
      for I := 0 to Include.Count - 1 do
        Probe.AddIncludePattern(Include[I]);
      for I := 0 to Exclude.Count - 1 do
        Probe.AddExcludePattern(Exclude[I]);
    except
      on E: EPasWeaveInputError do
        Fail('discovery include/exclude ' + E.Message);
    end;
    for I := 0 to Probe.IncludePatterns.Count - 1 do
      AConfig.IncludePatterns.Add(Probe.IncludePatterns[I]);
    for I := 0 to Probe.ExcludePatterns.Count - 1 do
      AConfig.ExcludePatterns.Add(Probe.ExcludePatterns[I]);
  finally
    Probe.Free;
    Exclude.Free;
    Include.Free;
  end;
end;

procedure LoadCompilerSection(AObject: TJSONObject; AConfig: TProjectConfig);
var
  Value: string;
  Normalised: string;
  I: Integer;
begin
  EnsureKnownKeys(AObject,
    ['unitPaths', 'includePaths', 'defines', 'targetOs', 'targetCpu',
     'buildMode', 'packagePaths'], 'compiler');
  AddPathArray(AObject, 'unitPaths', 'compiler', AConfig.UnitPaths);
  AddPathArray(AObject, 'includePaths', 'compiler', AConfig.IncludePaths);
  AddPathArray(AObject, 'packagePaths', 'compiler', AConfig.PackagePaths);
  AddStringArray(AObject, 'defines', 'compiler', AConfig.Defines);
  for I := 0 to AConfig.Defines.Count - 1 do
    if not IsValidConditionalDefine(AConfig.Defines[I]) then
      Fail('compiler.defines[' + IntToStr(I) +
        '] must be a plain Pascal identifier: ' + AConfig.Defines[I]);
  if OptionalString(AObject, 'targetOs', 'compiler', Value) then
  begin
    if not TryNormaliseTargetOS(Value, Normalised) then
      Fail('compiler.targetOs is not a supported FPC target: ' + Value);
    AConfig.TargetOS := Normalised;
  end;
  if OptionalString(AObject, 'targetCpu', 'compiler', Value) then
  begin
    if not TryNormaliseTargetCPU(Value, Normalised) then
      Fail('compiler.targetCpu is not a supported FPC target: ' + Value);
    AConfig.TargetCPU := Normalised;
  end;
  if OptionalString(AObject, 'buildMode', 'compiler', Value) then
  begin
    if Trim(Value) = '' then
      Fail('compiler.buildMode must not be empty');
    AConfig.BuildMode := Value;
  end;
end;

procedure LoadCoverageSection(AObject: TJSONObject; AConfig: TProjectConfig);
var
  Minimum: Integer;
  Value: string;
  Severity: TDiagnosticSeverity;
begin
  EnsureKnownKeys(AObject, ['minimum', 'failOn'], 'coverage');
  if OptionalInteger(AObject, 'minimum', 'coverage', Minimum) then
  begin
    if (Minimum < 0) or (Minimum > 100) then
      Fail('coverage.minimum must be an integer from 0 to 100');
    AConfig.MinimumCoverage := Minimum;
    AConfig.HasMinimumCoverage := True;
  end;
  if OptionalString(AObject, 'failOn', 'coverage', Value) then
  begin
    if not TryParseDiagnosticSeverity(Value, Severity) then
      Fail('coverage.failOn must be warning or error');
    AConfig.FailOn := DiagnosticSeverityName(Severity);
  end;
end;

constructor TProjectConfig.Create;
begin
  inherited Create;
  Visibility := rvpPublicAPI;
  Comments := DefaultDocumentationCommentStyles;
  IncludePatterns := TStringList.Create;
  ExcludePatterns := TStringList.Create;
  UnitPaths := TStringList.Create;
  IncludePaths := TStringList.Create;
  Defines := TStringList.Create;
  PackagePaths := TStringList.Create;
end;

destructor TProjectConfig.Destroy;
begin
  PackagePaths.Free;
  Defines.Free;
  IncludePaths.Free;
  UnitPaths.Free;
  ExcludePatterns.Free;
  IncludePatterns.Free;
  inherited Destroy;
end;

function VisibilityPolicyName(APolicy: TRenderVisibilityPolicy): string;
begin
  case APolicy of
    rvpPublicAPI: Result := 'public';
    rvpAllDeclarations: Result := 'all';
  end;
end;

function LoadProjectConfig(const AFilename: string): TProjectConfig;
var
  Root: TJSONData;
  RootObject: TJSONObject;
  Section: TJSONData;
  Version: Integer;
  Value: string;
begin
  if not FileExists(AFilename) then
    raise EProjectConfigError.CreateFmt(
      'configuration file does not exist: %s', [AFilename]);
  try
    Root := GetJSON(ReadFileToString(AFilename));
  except
    on E: Exception do
      raise EProjectConfigError.CreateFmt(
        'configuration file is not valid JSON: %s: %s',
        [AFilename, E.Message]);
  end;
  try
    if Root.JSONType <> jtObject then
      Fail('configuration root must be a JSON object');
    RootObject := TJSONObject(Root);
    EnsureKnownKeys(RootObject,
      ['version', 'source', 'output', 'project', 'comments', 'discovery',
       'compiler', 'visibility', 'coverage'], '');
    if not OptionalInteger(RootObject, 'version', '', Version) then
      Fail('configuration is missing the required version key');
    if Version <> ProjectConfigVersion then
      Fail(Format('unsupported configuration version: %d (expected %d)',
        [Version, ProjectConfigVersion]));

    Result := TProjectConfig.Create;
    try
      Result.Filename := ExpandFileName(AFilename);
      Result.Directory := ExtractFileDir(Result.Filename);
      if OptionalString(RootObject, 'source', '', Value) then
        Result.SourcePath := CheckRelativePath(Value, 'source');
      if OptionalString(RootObject, 'output', '', Value) then
        Result.OutputPath := CheckRelativePath(Value, 'output');
      if OptionalString(RootObject, 'comments', '', Value) then
        LoadComments(Value, 'comments', Result);
      if OptionalString(RootObject, 'visibility', '', Value) then
        LoadVisibility(Value, 'visibility', Result);

      Section := RootObject.Find('project');
      if Assigned(Section) then
      begin
        ExpectKind(Section, jkObject, 'project');
        LoadProjectSection(TJSONObject(Section), Result);
      end;
      Section := RootObject.Find('discovery');
      if Assigned(Section) then
      begin
        ExpectKind(Section, jkObject, 'discovery');
        LoadDiscoverySection(TJSONObject(Section), Result);
      end;
      Section := RootObject.Find('compiler');
      if Assigned(Section) then
      begin
        ExpectKind(Section, jkObject, 'compiler');
        LoadCompilerSection(TJSONObject(Section), Result);
      end;
      Section := RootObject.Find('coverage');
      if Assigned(Section) then
      begin
        ExpectKind(Section, jkObject, 'coverage');
        LoadCoverageSection(TJSONObject(Section), Result);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Root.Free;
  end;
end;

end.
