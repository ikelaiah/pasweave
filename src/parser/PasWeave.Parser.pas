unit PasWeave.Parser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PasWeave.Model, PasWeave.Comments, PasWeave.Compiler;

type
  EPasWeaveInputError = class(Exception);

  TSourceDiscoveryOptions = class
  private
    FExcludePatterns: TStringList;
    FIncludePatterns: TStringList;
    FRecursive: Boolean;
    function GetHasExplicitSettings: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddExcludePattern(const APattern: string);
    procedure AddIncludePattern(const APattern: string);
    property HasExplicitSettings: Boolean read GetHasExplicitSettings;
    property Recursive: Boolean read FRecursive write FRecursive;
  end;

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer): TDocProject; overload;
function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles): TDocProject; overload;
function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ADiscoveryOptions: TSourceDiscoveryOptions): TDocProject; overload;
function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ADiscoveryOptions: TSourceDiscoveryOptions;
  ACompilerOptions: TCompilerOptions): TDocProject; overload;
function BuildProjectFromFiles(const ASourceRoot, AProjectName: string;
  AFiles: TStrings; out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ACompilerOptions: TCompilerOptions): TDocProject;

implementation

uses
  PasWeave.Diagnostics, PasWeave.FPCAdapter, PasWeave.Validation;

function NormalisePath(const APath: string): string;
begin
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

procedure SplitPath(const APath: string; AParts: TStrings);
var
  StartPosition: Integer;
  Position: Integer;
begin
  AParts.Clear;
  StartPosition := 1;
  for Position := 1 to Length(APath) + 1 do
    if (Position > Length(APath)) or (APath[Position] = '/') then
    begin
      if Position > StartPosition then
        AParts.Add(Copy(APath, StartPosition, Position - StartPosition));
      StartPosition := Position + 1;
    end;
end;

function NormaliseDiscoveryPattern(const APattern, AOptionName: string): string;
var
  Parts: TStringList;
  I: Integer;
begin
  Result := Trim(NormalisePath(APattern));
  while Copy(Result, 1, 2) = './' do
    Delete(Result, 1, 2);
  while Pos('//', Result) > 0 do
    Result := StringReplace(Result, '//', '/', [rfReplaceAll]);
  while (Length(Result) > 0) and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);

  if Result = '' then
    raise EPasWeaveInputError.CreateFmt('%s pattern must not be empty',
      [AOptionName]);
  if (Result[1] = '/') or
    ((Length(Result) >= 2) and (Result[2] = ':')) then
    raise EPasWeaveInputError.CreateFmt(
      '%s pattern must be relative to the source directory: %s',
      [AOptionName, APattern]);

  Parts := TStringList.Create;
  try
    SplitPath(Result, Parts);
    for I := 0 to Parts.Count - 1 do
      if Parts[I] = '..' then
        raise EPasWeaveInputError.CreateFmt(
          '%s pattern must not leave the source directory: %s',
          [AOptionName, APattern]);
  finally
    Parts.Free;
  end;
end;

procedure ConfigurePatternList(AList: TStringList);
begin
  AList.Sorted := True;
  AList.CaseSensitive := False;
  AList.Duplicates := dupIgnore;
end;

constructor TSourceDiscoveryOptions.Create;
begin
  inherited Create;
  FIncludePatterns := TStringList.Create;
  FExcludePatterns := TStringList.Create;
  ConfigurePatternList(FIncludePatterns);
  ConfigurePatternList(FExcludePatterns);
end;

destructor TSourceDiscoveryOptions.Destroy;
begin
  FExcludePatterns.Free;
  FIncludePatterns.Free;
  inherited Destroy;
end;

function TSourceDiscoveryOptions.GetHasExplicitSettings: Boolean;
begin
  Result := FRecursive or (FIncludePatterns.Count > 0) or
    (FExcludePatterns.Count > 0);
end;

procedure TSourceDiscoveryOptions.AddExcludePattern(const APattern: string);
begin
  FExcludePatterns.Add(NormaliseDiscoveryPattern(APattern, '--exclude'));
end;

procedure TSourceDiscoveryOptions.AddIncludePattern(const APattern: string);
begin
  FIncludePatterns.Add(NormaliseDiscoveryPattern(APattern, '--include'));
end;

function MatchPathSegment(const APattern, AValue: string): Boolean;
var
  PatternText: string;
  ValueText: string;
  PatternPosition: Integer;
  ValuePosition: Integer;
  StarPosition: Integer;
  StarValuePosition: Integer;
begin
  PatternText := LowerCase(APattern);
  ValueText := LowerCase(AValue);
  PatternPosition := 1;
  ValuePosition := 1;
  StarPosition := 0;
  StarValuePosition := 0;

  while ValuePosition <= Length(ValueText) do
  begin
    if (PatternPosition <= Length(PatternText)) and
      ((PatternText[PatternPosition] = '?') or
      (PatternText[PatternPosition] = ValueText[ValuePosition])) then
    begin
      Inc(PatternPosition);
      Inc(ValuePosition);
    end
    else if (PatternPosition <= Length(PatternText)) and
      (PatternText[PatternPosition] = '*') then
    begin
      StarPosition := PatternPosition;
      StarValuePosition := ValuePosition;
      Inc(PatternPosition);
    end
    else if StarPosition > 0 then
    begin
      PatternPosition := StarPosition + 1;
      Inc(StarValuePosition);
      ValuePosition := StarValuePosition;
    end
    else
      Exit(False);
  end;

  while (PatternPosition <= Length(PatternText)) and
    (PatternText[PatternPosition] = '*') do
    Inc(PatternPosition);
  Result := PatternPosition > Length(PatternText);
end;

function MatchPathParts(APatternParts, AValueParts: TStrings;
  APatternIndex, AValueIndex: Integer): Boolean;
begin
  if APatternIndex >= APatternParts.Count then
    Exit(AValueIndex >= AValueParts.Count);

  if APatternParts[APatternIndex] = '**' then
  begin
    if MatchPathParts(APatternParts, AValueParts, APatternIndex + 1,
      AValueIndex) then
      Exit(True);
    if AValueIndex < AValueParts.Count then
      Exit(MatchPathParts(APatternParts, AValueParts, APatternIndex,
        AValueIndex + 1));
    Exit(False);
  end;

  Result := (AValueIndex < AValueParts.Count) and
    MatchPathSegment(APatternParts[APatternIndex],
      AValueParts[AValueIndex]) and
    MatchPathParts(APatternParts, AValueParts, APatternIndex + 1,
      AValueIndex + 1);
end;

function DiscoveryPatternMatches(const APattern, ARelativePath: string): Boolean;
var
  PatternParts: TStringList;
  ValueParts: TStringList;
begin
  if Pos('/', APattern) = 0 then
    Exit(MatchPathSegment(APattern, ExtractFileName(ARelativePath)));

  PatternParts := TStringList.Create;
  ValueParts := TStringList.Create;
  try
    SplitPath(APattern, PatternParts);
    SplitPath(ARelativePath, ValueParts);
    Result := MatchPathParts(PatternParts, ValueParts, 0, 0);
  finally
    ValueParts.Free;
    PatternParts.Free;
  end;
end;

function MatchesAnyDiscoveryPattern(APatterns: TStrings;
  const ARelativePath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to APatterns.Count - 1 do
    if DiscoveryPatternMatches(APatterns[I], ARelativePath) then
      Exit(True);
end;

function IsPascalUnitFilename(const AFilename: string): Boolean;
var
  Extension: string;
begin
  Extension := ExtractFileExt(AFilename);
  Result := SameText(Extension, '.pas') or SameText(Extension, '.pp');
end;

function ShouldIncludeDiscoveredFile(const ARelativePath: string;
  AOptions: TSourceDiscoveryOptions): Boolean;
begin
  Result := IsPascalUnitFilename(ARelativePath);
  if not Result or not Assigned(AOptions) then
    Exit;
  if MatchesAnyDiscoveryPattern(AOptions.FExcludePatterns,
    ARelativePath) then
    Exit(False);
  Result := (AOptions.FIncludePatterns.Count = 0) or
    MatchesAnyDiscoveryPattern(AOptions.FIncludePatterns, ARelativePath);
end;

function ShouldSkipDiscoveredDirectory(const ARelativePath: string;
  AOptions: TSourceDiscoveryOptions): Boolean;
begin
  Result := Assigned(AOptions) and
    MatchesAnyDiscoveryPattern(AOptions.FExcludePatterns, ARelativePath);
end;

function IsSymbolicLink(AAttributes: LongInt): Boolean;
begin
  {$IFDEF UNIX}
  Result := (AAttributes and faSymLink) <> 0;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

procedure DiscoverDirectoryFiles(const ARootDirectory,
  ARelativeDirectory: string; AOptions: TSourceDiscoveryOptions;
  AFiles: TStrings);
var
  CurrentDirectory: string;
  FullPath: string;
  RelativePath: string;
  Search: TSearchRec;
begin
  CurrentDirectory := ARootDirectory;
  if ARelativeDirectory <> '' then
    CurrentDirectory := IncludeTrailingPathDelimiter(CurrentDirectory) +
      StringReplace(ARelativeDirectory, '/', PathDelim, [rfReplaceAll]);

  if FindFirst(IncludeTrailingPathDelimiter(CurrentDirectory) + '*',
    faAnyFile, Search) <> 0 then
    Exit;
  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then
        Continue;
      if ARelativeDirectory = '' then
        RelativePath := Search.Name
      else
        RelativePath := ARelativeDirectory + '/' + Search.Name;
      RelativePath := NormalisePath(RelativePath);
      FullPath := IncludeTrailingPathDelimiter(CurrentDirectory) + Search.Name;

      if (Search.Attr and faDirectory) <> 0 then
      begin
        if Assigned(AOptions) and AOptions.Recursive and
          not IsSymbolicLink(Search.Attr) and
          not ShouldSkipDiscoveredDirectory(RelativePath, AOptions) then
          DiscoverDirectoryFiles(ARootDirectory, RelativePath, AOptions,
            AFiles);
      end
      else if ShouldIncludeDiscoveredFile(RelativePath, AOptions) then
        AFiles.Add(FullPath);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function DefaultProjectName(const ASourcePath: string): string;
begin
  if DirectoryExists(ASourcePath) then
    Result := ExtractFileName(ExcludeTrailingPathDelimiter(ASourcePath))
  else
    Result := ChangeFileExt(ExtractFileName(ASourcePath), '');
  if Result = '' then
    Result := 'PasWeaveProject';
end;

function IsRelationshipTypeSymbol(ASymbol: TDocSymbol): Boolean;
begin
  Result := ASymbol.Kind in [skClass, skInterface];
end;

function FindUnit(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
end;

function FindQualifiedTypeSymbol(AProject: TDocProject;
  const AQualifiedName: string): TDocSymbol;
var
  Candidate: TDocSymbol;
  I: Integer;
  J: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    for J := 0 to TDocUnit(AProject.Units[I]).Symbols.Count - 1 do
    begin
      Candidate := TDocSymbol(TDocUnit(AProject.Units[I]).Symbols[J]);
      if IsRelationshipTypeSymbol(Candidate) and
        SameText(Candidate.QualifiedName, AQualifiedName) then
      begin
        if Assigned(Result) then
          Exit(nil);
        Result := Candidate;
      end;
    end;
end;

function FindNamedTypeSymbol(AUnit: TDocUnit;
  const AName: string): TDocSymbol;
var
  Candidate: TDocSymbol;
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Candidate := TDocSymbol(AUnit.Symbols[I]);
    if IsRelationshipTypeSymbol(Candidate) and
      SameText(Candidate.Name, AName) then
    begin
      if Assigned(Result) then
        Exit(nil);
      Result := Candidate;
    end;
  end;
end;

function ResolveRelationshipTarget(AProject: TDocProject;
  ASourceUnit: TDocUnit; const ATargetName: string): TDocSymbol;
var
  Candidate: TDocSymbol;
  DependencyUnit: TDocUnit;
  I: Integer;
begin
  Result := nil;
  if ATargetName = '' then
    Exit;

  if Pos('.', ATargetName) > 0 then
    Exit(FindQualifiedTypeSymbol(AProject, ATargetName));

  Candidate := FindNamedTypeSymbol(ASourceUnit, ATargetName);
  if Assigned(Candidate) then
    Exit(Candidate);

  for I := 0 to ASourceUnit.InterfaceDependencies.Count - 1 do
  begin
    DependencyUnit := FindUnit(AProject,
      ASourceUnit.InterfaceDependencies[I]);
    if not Assigned(DependencyUnit) then
      Continue;
    Candidate := FindNamedTypeSymbol(DependencyUnit, ATargetName);
    if Assigned(Candidate) then
    begin
      if Assigned(Result) and (Result <> Candidate) then
        Exit(nil);
      Result := Candidate;
    end;
  end;
end;

procedure ResolveTypeRelationships(AProject: TDocProject);
var
  Relationship: TDocTypeRelationship;
  SourceSymbol: TDocSymbol;
  SourceUnit: TDocUnit;
  TargetSymbol: TDocSymbol;
  I: Integer;
  J: Integer;
  K: Integer;
begin
  for I := 0 to AProject.Units.Count - 1 do
  begin
    SourceUnit := TDocUnit(AProject.Units[I]);
    for J := 0 to SourceUnit.Symbols.Count - 1 do
    begin
      SourceSymbol := TDocSymbol(SourceUnit.Symbols[J]);
      for K := 0 to SourceSymbol.TypeRelationships.Count - 1 do
      begin
        Relationship := TDocTypeRelationship(
          SourceSymbol.TypeRelationships[K]);
        TargetSymbol := ResolveRelationshipTarget(AProject, SourceUnit,
          Relationship.TargetName);
        if Assigned(TargetSymbol) then
        begin
          Relationship.TargetSymbolID := TargetSymbol.ID;
          SourceSymbol.RelatedSymbolIDs.Add(TargetSymbol.ID);
        end;
      end;
    end;
  end;
end;

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer): TDocProject;
begin
  Result := BuildProject(ASourcePath, AProjectName, AAttemptedFileCount,
    DefaultDocumentationCommentStyles, nil);
end;

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles): TDocProject;
begin
  Result := BuildProject(ASourcePath, AProjectName, AAttemptedFileCount,
    ACommentStyles, nil);
end;

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ADiscoveryOptions: TSourceDiscoveryOptions): TDocProject;
begin
  Result := BuildProject(ASourcePath, AProjectName, AAttemptedFileCount,
    ACommentStyles, ADiscoveryOptions, nil);
end;

function FindUnitSourceFile(AUnitPaths: TStrings;
  const AUnitName: string): string;
const
  Extensions: array[0..1] of string = ('.pas', '.pp');
var
  Candidate: string;
  ExpectedName: string;
  I: Integer;
  J: Integer;
begin
  Result := '';
  for I := 0 to AUnitPaths.Count - 1 do
    for J := Low(Extensions) to High(Extensions) do
    begin
      ExpectedName := AUnitName + Extensions[J];
      Candidate := IncludeTrailingPathDelimiter(AUnitPaths[I]) +
        ExpectedName;
      if FileExists(Candidate) then
        Exit(ExpandFileName(Candidate));
      Candidate := IncludeTrailingPathDelimiter(AUnitPaths[I]) +
        LowerCase(ExpectedName);
      if FileExists(Candidate) then
        Exit(ExpandFileName(Candidate));
      Candidate := IncludeTrailingPathDelimiter(AUnitPaths[I]) +
        UpperCase(ExpectedName);
      if FileExists(Candidate) then
        Exit(ExpandFileName(Candidate));
    end;
end;

function BuildProjectFileSet(const ASourceRoot, ADisplayRoot, AProjectName: string;
  AFiles: TStrings; out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ACompilerOptions: TCompilerOptions): TDocProject;
var
  Files: TStringList;
  AttemptedFiles: TStringList;
  SourceRoot: string;
  UnitModel: TDocUnit;
  Diagnostic: TDiagnostic;
  EffectiveCompilerOptions: TCompilerOptions;
  OwnedCompilerOptions: TCompilerOptions;
  DependencySourceUnit: TDocUnit;
  DependencyFilename: string;
  DependencyName: string;
  DependencyUnitIndex: Integer;
  I: Integer;
  J: Integer;
begin
  AAttemptedFileCount := 0;
  SourceRoot := ExpandFileName(ASourceRoot);
  if not DirectoryExists(SourceRoot) then
    raise EPasWeaveInputError.CreateFmt(
      'source root does not exist: %s', [ASourceRoot]);
  if not Assigned(AFiles) or (AFiles.Count = 0) then
    raise EPasWeaveInputError.Create(
      'no Pascal unit files were selected');

  Files := TStringList.Create;
  AttemptedFiles := TStringList.Create;
  OwnedCompilerOptions := nil;
  try
    Files.CaseSensitive := False;
    Files.Duplicates := dupIgnore;
    Files.Sorted := True;
    for I := 0 to AFiles.Count - 1 do
      if FileExists(ExpandFileName(AFiles[I])) then
        Files.Add(ExpandFileName(AFiles[I]))
      else
        raise EPasWeaveInputError.CreateFmt(
          'Lazarus source file does not exist: %s', [AFiles[I]]);
    AttemptedFiles.CaseSensitive := False;
    AttemptedFiles.Duplicates := dupIgnore;
    if Assigned(ACompilerOptions) then
      EffectiveCompilerOptions := ACompilerOptions
    else
    begin
      OwnedCompilerOptions := TCompilerOptions.Create;
      EffectiveCompilerOptions := OwnedCompilerOptions;
    end;

    Result := TDocProject.Create;
    try
      if AProjectName <> '' then
        Result.Name := AProjectName
      else
        Result.Name := DefaultProjectName(ASourceRoot);
      Result.SourceRoot := NormalisePath(ADisplayRoot);
      for I := 0 to Files.Count - 1 do
      begin
        AttemptedFiles.Add(Files[I]);
        Inc(AAttemptedFileCount);
        UnitModel := nil;
        Diagnostic := nil;
        if ParseUnitFile(Files[I], SourceRoot, ACommentStyles,
          EffectiveCompilerOptions, UnitModel, Diagnostic) then
          Result.Units.Add(UnitModel)
        else if Assigned(Diagnostic) then
          Result.Errors.Add(Diagnostic);
      end;

      DependencyUnitIndex := 0;
      while DependencyUnitIndex < Result.Units.Count do
      begin
        DependencySourceUnit := TDocUnit(
          Result.Units[DependencyUnitIndex]);
        for J := 0 to DependencySourceUnit.InterfaceDependencies.Count - 1 do
        begin
          DependencyName := DependencySourceUnit.InterfaceDependencies[J];
          if Assigned(FindUnit(Result, DependencyName)) then
            Continue;
          DependencyFilename := FindUnitSourceFile(
            EffectiveCompilerOptions.UnitPaths, DependencyName);
          if (DependencyFilename = '') or
            (AttemptedFiles.IndexOf(DependencyFilename) >= 0) then
            Continue;
          AttemptedFiles.Add(DependencyFilename);
          Inc(AAttemptedFileCount);
          UnitModel := nil;
          Diagnostic := nil;
          if ParseUnitFile(DependencyFilename, SourceRoot, ACommentStyles,
            EffectiveCompilerOptions, UnitModel, Diagnostic) then
          begin
            if SameText(UnitModel.Name, DependencyName) then
              Result.Units.Add(UnitModel)
            else
            begin
              Result.Errors.Add(TDiagnostic.Create(dsError,
                UnitModel.SourceFilename, 1, 1,
                'resolved unit name does not match dependency: expected ' +
                DependencyName + ', found ' + UnitModel.Name,
                'unitPath=' + NormalisePath(ExtractFileDir(
                DependencyFilename))));
              UnitModel.Free;
            end;
          end
          else if Assigned(Diagnostic) then
            Result.Errors.Add(Diagnostic);
        end;
        Inc(DependencyUnitIndex);
      end;
      ResolveTypeRelationships(Result);
      ValidateProject(Result);
    except
      Result.Free;
      raise;
    end;
  finally
    OwnedCompilerOptions.Free;
    AttemptedFiles.Free;
    Files.Free;
  end;
end;

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ADiscoveryOptions: TSourceDiscoveryOptions;
  ACompilerOptions: TCompilerOptions): TDocProject;
var
  Files: TStringList;
  SourceRoot: string;
  DisplayRoot: string;
  EffectiveProjectName: string;
begin
  AAttemptedFileCount := 0;
  if not FileExists(ASourcePath) and not DirectoryExists(ASourcePath) then
    raise EPasWeaveInputError.CreateFmt('source path does not exist: %s',
      [ASourcePath]);
  if FileExists(ASourcePath) and Assigned(ADiscoveryOptions) and
    ADiscoveryOptions.HasExplicitSettings then
    raise EPasWeaveInputError.Create(
      'recursive, include, and exclude options require a source directory');

  Files := TStringList.Create;
  try
    Files.Sorted := True;
    Files.CaseSensitive := False;
    Files.Duplicates := dupIgnore;
    if DirectoryExists(ASourcePath) then
    begin
      SourceRoot := ExpandFileName(ASourcePath);
      DisplayRoot := ExcludeTrailingPathDelimiter(ASourcePath);
      DiscoverDirectoryFiles(SourceRoot, '', ADiscoveryOptions, Files);
    end
    else
    begin
      SourceRoot := ExtractFileDir(ExpandFileName(ASourcePath));
      DisplayRoot := ExtractFileDir(ASourcePath);
      if DisplayRoot = '' then
        DisplayRoot := '.';
      Files.Add(ExpandFileName(ASourcePath));
    end;
    if Files.Count = 0 then
      raise EPasWeaveInputError.CreateFmt(
        'no Pascal unit files (*.pas or *.pp) matched source discovery in: %s',
        [ASourcePath]);
    EffectiveProjectName := AProjectName;
    if EffectiveProjectName = '' then
      EffectiveProjectName := DefaultProjectName(ASourcePath);
    Result := BuildProjectFileSet(SourceRoot, DisplayRoot,
      EffectiveProjectName,
      Files, AAttemptedFileCount, ACommentStyles, ACompilerOptions);
  finally
    Files.Free;
  end;
end;

function BuildProjectFromFiles(const ASourceRoot, AProjectName: string;
  AFiles: TStrings; out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles;
  ACompilerOptions: TCompilerOptions): TDocProject;
begin
  Result := BuildProjectFileSet(ASourceRoot, ASourceRoot, AProjectName,
    AFiles, AAttemptedFileCount, ACommentStyles, ACompilerOptions);
end;

end.
