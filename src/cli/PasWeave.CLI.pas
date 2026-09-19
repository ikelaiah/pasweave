/// Implements the `pasweave build` command-line pipeline.
///
/// Usage starts at @see RunPasWeave, which parses options, builds the
/// documentation model, renders HTML/Markdown/JSON, and writes `manifest.json`
/// for safe incremental rebuilds.
unit PasWeave.CLI;

{$mode objfpc}{$H+}{$J+}

interface

/// Runs PasWeave with the process command line.
///
/// @returns Process exit code: `0` success, `1` build diagnostics at or above
///   the `--fail-on` severity, `2` invalid command line or configuration,
///   `3` an unexpected internal error.
function RunPasWeave: Integer;

implementation

uses
  Classes, SysUtils, PasWeave.Comments, PasWeave.Compiler,
  PasWeave.Diagnostics, PasWeave.Incremental, PasWeave.Lazarus,
  PasWeave.Lazarus.Support, PasWeave.Model,
  PasWeave.Model.JSON, PasWeave.Output, PasWeave.Parser, PasWeave.SourceLinks,
  PasWeave.Render.Markdown, PasWeave.Render.HTML,
  PasWeave.Render.HTML.Assets, PasWeave.Validation, PasWeave.Version;

procedure PrintUsage;
begin
  WriteLn('PasWeave - Free Pascal-first documentation model generator');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  pasweave --version');
  WriteLn('  pasweave build <unit-or-directory> [--output <directory>]');
  WriteLn('                 [--project-name <name>] [--doc-comments=<styles>]');
  WriteLn('                 [--recursive] [--include=<glob>] [--exclude=<glob>]');
  WriteLn('                 [--unit-path=<directory>] [--include-path=<directory>]');
  WriteLn('                 [--define=<name>] [--target-os=<os>] [--target-cpu=<cpu>]');
  WriteLn('                 [--build-mode=<name>] [--package-path=<directory>]');
  WriteLn('                 [--repository-url=<url>]');
  WriteLn('                 [--source-link-template=<relative-template>]');
  WriteLn('                 [--min-documentation-coverage=<0-100>]');
  WriteLn('                 [--fail-on=<error|warning>]');
  WriteLn('                 [--clean]');
  WriteLn('                 [--verbose]');
  WriteLn;
  WriteLn('Source discovery:');
  WriteLn('  Directories are non-recursive unless --recursive is supplied');
  WriteLn('  --include and --exclude are repeatable, source-root-relative globs');
  WriteLn('  * and ? stay within one path segment; ** spans directories');
  WriteLn('  Exclusions win when both an include and exclude match');
  WriteLn;
  WriteLn('Compiler-aware parsing:');
  WriteLn('  --unit-path, --include-path, and --define are repeatable');
  WriteLn('  Unit and include paths are searched in command-line order');
  WriteLn('  Explicit target OS/CPU values override the documentation host defaults');
  WriteLn;
  WriteLn('Lazarus project and package inputs:');
  WriteLn('  .lpi projects and .lpk packages import their source and compiler settings');
  WriteLn('  --build-mode selects a named Lazarus project build mode');
  WriteLn('  --package-path is repeatable and opts into additional package roots');
  WriteLn('  automatic package search prunes build, vendor, example, and test trees');
  WriteLn;
  WriteLn('Authoring feedback and CI:');
  WriteLn('  --min-documentation-coverage fails the build below the percentage');
  WriteLn('  --fail-on=error is the default; warning also fails on authoring feedback');
  WriteLn('  diagnostics.json is written beside api-model.json');
  WriteLn;
  WriteLn('Incremental builds:');
  WriteLn('  repeated builds skip unchanged parse and render work by default');
  WriteLn('  --clean forces a full rebuild from scratch');
  WriteLn('  manifest.json records every generated page and asset');
  WriteLn;
  WriteLn('Source links:');
  WriteLn('  --repository-url and --source-link-template must be supplied together');
  WriteLn('  the template is repository-relative and requires {path} and {line}');
  WriteLn('  example: blob/main/{path}#L{line}');
  WriteLn;
  WriteLn('Project branding:');
  WriteLn('  --project-mark=<1-4 alphanumeric characters> replaces the brand mark');
  WriteLn('  --theme-accent=<#RGB|#RRGGBB|#RRGGBBAA> and');
  WriteLn('  --theme-accent-2=<color> set the two project accent colors');
  WriteLn('  --theme-font=<family name> sets the primary body font family');
  WriteLn('  defaults reproduce the built-in light and dark reader schemes');
  WriteLn;
  WriteLn('Documentation comment styles:');
  WriteLn('  slash = /// lines (PasWeave convention; plain // is ignored)');
  WriteLn('  brace = { ... }; paren = (* ... *)');
  WriteLn('  Styles may be comma-separated; all enables all three styles');
  WriteLn('  Default: slash (/// only)');
end;

function RequireOptionValue(var AIndex: Integer; const AOption: string): string;
begin
  Inc(AIndex);
  if AIndex > ParamCount then
    raise EPasWeaveInputError.CreateFmt('missing value for %s', [AOption]);
  Result := ParamStr(AIndex);
end;

/// Matches `--name value` or `--name=value`, advancing AIndex for the
/// separated form. Returns False when the parameter is a different option.
function MatchValueOption(const AParam, AName: string; var AIndex: Integer;
  out AValue: string): Boolean;
var
  Prefix: string;
begin
  AValue := '';
  if AParam = AName then
  begin
    AValue := RequireOptionValue(AIndex, AName);
    Exit(True);
  end;
  Prefix := AName + '=';
  Result := Pos(Prefix, AParam) = 1;
  if Result then
    AValue := Copy(AParam, Length(Prefix) + 1, MaxInt);
end;

procedure PrintDiagnostic(ADiagnostic: TDiagnostic; AVerbose: Boolean);
var
  Location: string;
begin
  Location := ADiagnostic.SourceFilename;
  if ADiagnostic.SourceLine > 0 then
  begin
    Location := Location + ':' + IntToStr(ADiagnostic.SourceLine);
    if ADiagnostic.SourceColumn > 0 then
      Location := Location + ':' + IntToStr(ADiagnostic.SourceColumn);
  end;
  WriteLn('[', DiagnosticSeverityName(ADiagnostic.Severity), ' ',
    ADiagnostic.Code, '] ', Location, '  ', ADiagnostic.MessageText);
  if AVerbose then
  begin
    WriteLn('        severity=', DiagnosticSeverityName(ADiagnostic.Severity));
    if ADiagnostic.Details <> '' then
      WriteLn('        ', ADiagnostic.Details);
  end;
end;

function RunBuild: Integer;
var
  SourcePath: string;
  OutputPath: string;
  ProjectName: string;
  Verbose: Boolean;
  I: Integer;
  AttemptedCount: Integer;
  Project: TDocProject;
  UnitModel: TDocUnit;
  ParsedCount: Integer;
  Diagnostic: TDiagnostic;
  OutputFile: string;
  DiagnosticOutputFile: string;
  MarkdownOutputPath: string;
  HTMLOutputPath: string;
  BuildMode: string;
  CommentStyles: TDocumentationCommentStyles;
  DiscoveryOptions: TSourceDiscoveryOptions;
  CompilerOptions: TCompilerOptions;
  PackagePaths: TStringList;
  LazarusConfiguration: TLazarusConfiguration;
  ProjectNameExplicit: Boolean;
  IsLazarusInput: Boolean;
  FailureSeverity: TDiagnosticSeverity;
  MinimumCoverage: Integer;
  HasMinimumCoverage: Boolean;
  RepositoryURL: string;
  SourceLinkTemplate: string;
  SourceLinkError: string;
  ProjectMark: string;
  ThemeAccent: string;
  ThemeAccentAlt: string;
  ThemeFont: string;
  HasProjectMark: Boolean;
  HasThemeAccent: Boolean;
  HasThemeAccentAlt: Boolean;
  HasThemeFont: Boolean;
  CleanBuild: Boolean;
  SkipBuild: Boolean;
  ManifestExisted: Boolean;
  StartTick: QWord;
  Fingerprint: string;
  ConfigText: string;
  InputFiles: TStringList;
  OldManifest: TManifest;
  NewManifest: TManifest;
  NewPaths: TStringList;
  ParseHandled: Boolean;

  procedure AppendConfigLine(const ALine: string);
  begin
    ConfigText := ConfigText + ALine + #10;
  end;

  procedure AppendConfigValue(const AKey, AValue: string);
  begin
    AppendConfigLine(AKey + '=' + AValue);
  end;

  procedure AppendConfigFlag(const AKey: string; AValue: Boolean);
  begin
    if AValue then
      AppendConfigLine(AKey + '=true')
    else
      AppendConfigLine(AKey + '=false');
  end;

  function TryParseLedgerEntry(const AEntry: string; out APath, ASHA: string;
    out ASize: Int64): Boolean;
  var
    FirstSeparator: Integer;
    SecondSeparator: Integer;
    SizeText: string;
  begin
    Result := False;
    APath := '';
    ASHA := '';
    ASize := 0;
    FirstSeparator := Pos(#1, AEntry);
    if FirstSeparator <= 1 then
      Exit;
    SecondSeparator := Pos(#1, Copy(AEntry, FirstSeparator + 1,
      MaxInt)) + FirstSeparator;
    if SecondSeparator <= FirstSeparator + 1 then
      Exit;
    APath := Copy(AEntry, 1, FirstSeparator - 1);
    ASHA := Copy(AEntry, FirstSeparator + 1,
      SecondSeparator - FirstSeparator - 1);
    SizeText := Copy(AEntry, SecondSeparator + 1, MaxInt);
    if not TryStrToInt64(SizeText, ASize) then
      Exit;
    if ASize < 0 then
      Exit;
    Result := True;
  end;

  function BuildManifestFromLedger: TManifest;
  var
    Entries: TStringList;
    I: Integer;
  begin
    Result := TManifest.Create;
    Result.SchemaVersion := ManifestSchemaVersion;
    Result.PasWeaveVersion := PasWeaveVersion;
    Result.InputFingerprint := Fingerprint;
    Result.UnitCount := Project.Units.Count;
    Result.SymbolCount := Project.SymbolCount;
    Result.AttemptedCount := AttemptedCount;
    Result.WarningCount := Project.Warnings.Count;
    Result.ErrorCount := Project.Errors.Count;
    Entries := LedgerEntries(OutputPath);
    try
      SetLength(Result.Entries, Entries.Count);
      for I := 0 to Entries.Count - 1 do
      begin
        if not TryParseLedgerEntry(Entries[I], Result.Entries[I].Path,
          Result.Entries[I].SHA256, Result.Entries[I].Size) then
        begin
          Result.Entries[I].Path := '';
          Result.Entries[I].SHA256 := '';
          Result.Entries[I].Size := 0;
        end;
      end;
    finally
      Entries.Free;
    end;
  end;

  procedure ParseCommandLine;
  var
    OptionValue: string;
  begin
    I := 2;
    while I <= ParamCount do
    begin
      if MatchValueOption(ParamStr(I), '--output', I, OptionValue) then
        OutputPath := OptionValue
      else if MatchValueOption(ParamStr(I), '--project-name', I, OptionValue) then
      begin
        ProjectName := OptionValue;
        ProjectNameExplicit := True;
      end
      else if MatchValueOption(ParamStr(I), '--doc-comments', I, OptionValue) then
      begin
        if not TryParseDocumentationCommentStyles(OptionValue, CommentStyles) then
          raise EPasWeaveInputError.CreateFmt(
            'invalid documentation comment styles: %s ' +
            '(expected slash (///), brace ({ ... }), paren ((* ... *)), ' +
            'a comma-separated combination, or all)',
            [OptionValue]);
      end
      else if ParamStr(I) = '--recursive' then
        DiscoveryOptions.Recursive := True
      else if MatchValueOption(ParamStr(I), '--include', I, OptionValue) then
        DiscoveryOptions.AddIncludePattern(OptionValue)
      else if MatchValueOption(ParamStr(I), '--exclude', I, OptionValue) then
        DiscoveryOptions.AddExcludePattern(OptionValue)
      else if MatchValueOption(ParamStr(I), '--unit-path', I, OptionValue) then
        CompilerOptions.AddUnitPath(OptionValue)
      else if MatchValueOption(ParamStr(I), '--include-path', I, OptionValue) then
        CompilerOptions.AddIncludePath(OptionValue)
      else if MatchValueOption(ParamStr(I), '--define', I, OptionValue) then
        CompilerOptions.AddDefine(OptionValue)
      else if MatchValueOption(ParamStr(I), '--target-os', I, OptionValue) then
        CompilerOptions.SetTargetOS(OptionValue)
      else if MatchValueOption(ParamStr(I), '--target-cpu', I, OptionValue) then
        CompilerOptions.SetTargetCPU(OptionValue)
      else if MatchValueOption(ParamStr(I), '--build-mode', I, OptionValue) then
        BuildMode := OptionValue
      else if MatchValueOption(ParamStr(I), '--package-path', I, OptionValue) then
        PackagePaths.Add(OptionValue)
      else if MatchValueOption(ParamStr(I), '--repository-url', I, OptionValue) then
        RepositoryURL := OptionValue
      else if MatchValueOption(ParamStr(I), '--source-link-template', I, OptionValue) then
        SourceLinkTemplate := OptionValue
      else if MatchValueOption(ParamStr(I), '--project-mark', I, OptionValue) then
      begin
        if not IsValidProjectMark(OptionValue) then
          raise EPasWeaveInputError.Create(
            '--project-mark must be 1 to 4 alphanumeric characters');
        ProjectMark := OptionValue;
        HasProjectMark := True;
      end
      else if MatchValueOption(ParamStr(I), '--theme-accent', I, OptionValue) then
      begin
        if not IsValidThemeColor(OptionValue) then
          raise EPasWeaveInputError.Create(
            '--theme-accent must be a #RGB, #RRGGBB, or #RRGGBBAA color');
        ThemeAccent := OptionValue;
        HasThemeAccent := True;
      end
      else if MatchValueOption(ParamStr(I), '--theme-accent-2', I, OptionValue) then
      begin
        if not IsValidThemeColor(OptionValue) then
          raise EPasWeaveInputError.Create(
            '--theme-accent-2 must be a #RGB, #RRGGBB, or #RRGGBBAA color');
        ThemeAccentAlt := OptionValue;
        HasThemeAccentAlt := True;
      end
      else if MatchValueOption(ParamStr(I), '--theme-font', I, OptionValue) then
      begin
        if not IsValidThemeFont(OptionValue) then
          raise EPasWeaveInputError.Create(
            '--theme-font must be a safe font family name');
        ThemeFont := OptionValue;
        HasThemeFont := True;
      end
      else if MatchValueOption(ParamStr(I), '--min-documentation-coverage', I, OptionValue) then
      begin
        if not TryStrToInt(OptionValue, MinimumCoverage) or
          (MinimumCoverage < 0) or (MinimumCoverage > 100) then
          raise EPasWeaveInputError.Create(
            '--min-documentation-coverage must be an integer from 0 to 100');
        HasMinimumCoverage := True;
      end
      else if MatchValueOption(ParamStr(I), '--fail-on', I, OptionValue) then
      begin
        if not TryParseDiagnosticSeverity(OptionValue, FailureSeverity) then
          raise EPasWeaveInputError.Create(
            '--fail-on must be warning or error');
      end
      else if ParamStr(I) = '--clean' then
        CleanBuild := True
      else if ParamStr(I) = '--verbose' then
        Verbose := True
      else if (ParamStr(I) = '--help') or (ParamStr(I) = '-h') then
      begin
        PrintUsage;
        ParseHandled := True;
        Exit;
      end
      else if (Length(ParamStr(I)) > 0) and (ParamStr(I)[1] = '-') then
        raise EPasWeaveInputError.CreateFmt('unknown option: %s', [ParamStr(I)])
      else if SourcePath = '' then
        SourcePath := ParamStr(I)
      else
        raise EPasWeaveInputError.Create('only one source path may be supplied');
      Inc(I);
    end;
  end;

  procedure ExecuteBuild;
  var
    I: Integer;
  begin
    if SourcePath = '' then
      raise EPasWeaveInputError.Create('missing unit or source directory');
    { Validate before fingerprinting so a typo reports a clean input error
      instead of an unhandled file-open failure. }
    if not FileExists(SourcePath) and not DirectoryExists(SourcePath) then
      raise EPasWeaveInputError.CreateFmt('source path does not exist: %s',
        [SourcePath]);
    IsLazarusInput := SameText(ExtractFileExt(SourcePath), '.lpi') or
      SameText(ExtractFileExt(SourcePath), '.lpk');
    if IsLazarusInput then
    begin
      if DiscoveryOptions.HasExplicitSettings then
        raise EPasWeaveInputError.Create(
          '--recursive, --include, and --exclude require a direct source '
          + 'file or directory input');
      LazarusConfiguration := LoadLazarusConfiguration(SourcePath, BuildMode,
        PackagePaths);
      if not ProjectNameExplicit then
        ProjectName := LazarusConfiguration.ProjectName;
      CompilerOptions.ApplyDefaultsFrom(
        LazarusConfiguration.CompilerOptions);
    end
    else
    begin
      if BuildMode <> '' then
        raise EPasWeaveInputError.Create(
          '--build-mode requires a Lazarus .lpi or .lpk input');
      if PackagePaths.Count > 0 then
        raise EPasWeaveInputError.Create(
          '--package-path requires a Lazarus .lpi or .lpk input');
    end;

    AppendConfigValue('source-path',
      StringReplace(SourcePath, '\', '/', [rfReplaceAll]));
    AppendConfigValue('project-name', ProjectName);
    AppendConfigValue('doc-comments',
      DocumentationCommentStylesText(CommentStyles));
    AppendConfigFlag('recursive', DiscoveryOptions.Recursive);
    for I := 0 to DiscoveryOptions.IncludePatterns.Count - 1 do
      AppendConfigValue('include', DiscoveryOptions.IncludePatterns[I]);
    for I := 0 to DiscoveryOptions.ExcludePatterns.Count - 1 do
      AppendConfigValue('exclude', DiscoveryOptions.ExcludePatterns[I]);
    for I := 0 to CompilerOptions.UnitPaths.Count - 1 do
      AppendConfigValue('unit-path', CompilerOptions.UnitPaths[I]);
    for I := 0 to CompilerOptions.IncludePaths.Count - 1 do
      AppendConfigValue('include-path', CompilerOptions.IncludePaths[I]);
    for I := 0 to CompilerOptions.Defines.Count - 1 do
      AppendConfigValue('define', CompilerOptions.Defines[I]);
    AppendConfigValue('target-os', CompilerOptions.TargetOS);
    AppendConfigFlag('target-os-explicit', CompilerOptions.TargetOSExplicit);
    AppendConfigValue('target-cpu', CompilerOptions.TargetCPU);
    AppendConfigFlag('target-cpu-explicit', CompilerOptions.TargetCPUExplicit);
    AppendConfigValue('build-mode', BuildMode);
    for I := 0 to PackagePaths.Count - 1 do
      AppendConfigValue('package-path', PackagePaths[I]);
    AppendConfigValue('repository-url', RepositoryURL);
    AppendConfigValue('source-link-template', SourceLinkTemplate);
    AppendConfigValue('project-mark', ProjectMark);
    AppendConfigFlag('project-mark-explicit', HasProjectMark);
    AppendConfigValue('theme-accent', ThemeAccent);
    AppendConfigFlag('theme-accent-explicit', HasThemeAccent);
    AppendConfigValue('theme-accent-2', ThemeAccentAlt);
    AppendConfigFlag('theme-accent-2-explicit', HasThemeAccentAlt);
    AppendConfigValue('theme-font', ThemeFont);
    AppendConfigFlag('theme-font-explicit', HasThemeFont);
    if HasMinimumCoverage then
      AppendConfigValue('min-documentation-coverage',
        IntToStr(MinimumCoverage))
    else
      AppendConfigValue('min-documentation-coverage', '');
    AppendConfigValue('fail-on', DiagnosticSeverityName(FailureSeverity));
    AppendConfigValue('output',
      StringReplace(OutputPath, '\', '/', [rfReplaceAll]));

    if IsLazarusInput then
      InputFiles := EnumerateInputFiles(SourcePath, True, nil, CompilerOptions,
        LazarusConfiguration.SourceFiles, LazarusConfiguration.PackageFiles)
    else
      InputFiles := EnumerateInputFiles(SourcePath, False, DiscoveryOptions,
        CompilerOptions, nil, nil);
    try
      Fingerprint := ComputeBuildFingerprint(ConfigText, InputFiles,
        ThirdPartyAssetFingerprint);
    finally
      InputFiles.Free;
    end;

    ManifestExisted := FileExists(ManifestFilePath(OutputPath));
    OldManifest := ReadManifest(OutputPath);
    if ManifestExisted and not Assigned(OldManifest) then
      WriteLn(StdErr, 'pasweave: warning: manifest.json is unreadable or ' +
        'invalid; rebuilding from scratch');
    if (not CleanBuild) and Assigned(OldManifest) and
      (OldManifest.InputFingerprint = Fingerprint) and
      ManifestOutputsPresent(OldManifest, OutputPath) then
    begin
      WriteLn('[up-to-date] output already matches current inputs');
      WriteLn('Generated ', OldManifest.SymbolCount, ' symbols from ',
        OldManifest.UnitCount, ' of ', OldManifest.AttemptedCount,
        ' units, with ', OldManifest.WarningCount, ' warnings and ',
        OldManifest.ErrorCount, ' errors.');
      WriteLn('Wrote ', ManifestFilePath(OutputPath), ' (unchanged)');
      if Verbose then
        WriteLn('elapsed=', MonotonicMilliseconds - StartTick, ' ms; ' +
          'peak-heap=', PeakHeapBytes, ' bytes');
      Result := 0;
      if (OldManifest.ErrorCount > 0) or
        ((FailureSeverity = dsWarning) and (OldManifest.WarningCount > 0)) then
        Result := 1;
      SkipBuild := True;
    end
    else
    begin
      ResetPeakHeap;
      BeginOutputLedger;
      if IsLazarusInput then
        Project := BuildProjectFromFiles(LazarusConfiguration.SourceRoot,
          ProjectName, LazarusConfiguration.SourceFiles, AttemptedCount,
          CommentStyles, CompilerOptions)
      else
        Project := BuildProject(SourcePath, ProjectName, AttemptedCount,
          CommentStyles, DiscoveryOptions, CompilerOptions);
      SamplePeakHeap;
    end;
  end;

  function RenderAndReport: Integer;
  var
    I: Integer;
  begin
    if not TryConfigureSourceLinks(Project, RepositoryURL, SourceLinkTemplate,
      SourceLinkError) then
      raise EPasWeaveInputError.Create(SourceLinkError);
    if HasProjectMark then
      Project.ProjectMark := ProjectMark;
    if HasThemeAccent then
      Project.ThemeAccent := ThemeAccent;
    if HasThemeAccentAlt then
      Project.ThemeAccentAlt := ThemeAccentAlt;
    if HasThemeFont then
      Project.ThemeFont := ThemeFont;
    if HasMinimumCoverage then
      AddDocumentationCoverageDiagnostic(Project, MinimumCoverage);
    OutputFile := IncludeTrailingPathDelimiter(OutputPath) + 'api-model.json';
    WriteProjectJSON(Project, OutputFile);
    DiagnosticOutputFile := IncludeTrailingPathDelimiter(OutputPath) +
      'diagnostics.json';
    WriteDiagnosticsJSON(Project, DiagnosticOutputFile);
    MarkdownOutputPath := IncludeTrailingPathDelimiter(OutputPath) +
      'markdown';
    WriteMarkdownDocumentation(Project, MarkdownOutputPath);
    HTMLOutputPath := IncludeTrailingPathDelimiter(OutputPath) + 'html';
    WriteHTMLDocumentation(Project, HTMLOutputPath);

    for I := 0 to Project.Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Project.Units[I]);
      WriteLn('[ok]    ', UnitModel.SourceFilename, '  ',
        UnitModel.Symbols.Count, ' symbols');
    end;
    for I := 0 to Project.Errors.Count - 1 do
    begin
      Diagnostic := TDiagnostic(Project.Errors[I]);
      PrintDiagnostic(Diagnostic, Verbose);
    end;
    for I := 0 to Project.Warnings.Count - 1 do
    begin
      Diagnostic := TDiagnostic(Project.Warnings[I]);
      PrintDiagnostic(Diagnostic, Verbose);
    end;

    ParsedCount := Project.Units.Count;
    WriteLn;
    WriteLn('Generated ', Project.SymbolCount, ' symbols from ', ParsedCount,
      ' of ', AttemptedCount, ' units, with ', Project.Warnings.Count,
      ' warnings and ', Project.Errors.Count, ' errors.');
    WriteLn('Wrote ', OutputFile);
    WriteLn('Wrote ', DiagnosticOutputFile);
    WriteLn('Wrote ', IncludeTrailingPathDelimiter(MarkdownOutputPath),
      'index.md and ', Project.Units.Count, ' unit pages');
    WriteLn('Wrote ', IncludeTrailingPathDelimiter(HTMLOutputPath),
      'index.html, search assets, and ', Project.Units.Count, ' unit pages');

    NewManifest := BuildManifestFromLedger;
    try
      NewPaths := LedgerPaths(OutputPath);
      try
        RemoveStaleOutputs(OutputPath, OldManifest, NewPaths);
      finally
        NewPaths.Free;
      end;
      WriteManifest(OutputPath, NewManifest);
    finally
      NewManifest.Free;
    end;
    WriteLn('Wrote ', ManifestFilePath(OutputPath));

    SamplePeakHeap;
    if Verbose then
      WriteLn('elapsed=', MonotonicMilliseconds - StartTick, ' ms; ' +
        'peak-heap=', PeakHeapBytes, ' bytes');

    if HasDiagnosticsAtOrAbove(Project, FailureSeverity) then
      Result := 1
    else
      Result := 0;
  end;

begin
  SourcePath := '';
  OutputPath := 'build/docs';
  ProjectName := '';
  ProjectNameExplicit := False;
  BuildMode := '';
  Verbose := False;
  FailureSeverity := dsError;
  HasMinimumCoverage := False;
  MinimumCoverage := 0;
  RepositoryURL := '';
  SourceLinkTemplate := '';
  ProjectMark := '';
  ThemeAccent := '';
  ThemeAccentAlt := '';
  ThemeFont := '';
  HasProjectMark := False;
  HasThemeAccent := False;
  HasThemeAccentAlt := False;
  HasThemeFont := False;
  CleanBuild := False;
  SkipBuild := False;
  Project := nil;
  OldManifest := nil;
  StartTick := MonotonicMilliseconds;
  CommentStyles := DefaultDocumentationCommentStyles;
  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  CompilerOptions := TCompilerOptions.Create;
  PackagePaths := TStringList.Create;
  LazarusConfiguration := nil;
  ParseHandled := False;
  try
    ParseCommandLine;
    if ParseHandled then
      Exit(0);
    ExecuteBuild;
    if SkipBuild then
      Exit;
    Result := RenderAndReport;
  finally
    Project.Free;
    OldManifest.Free;
    LazarusConfiguration.Free;
    PackagePaths.Free;
    CompilerOptions.Free;
    DiscoveryOptions.Free;
  end;
end;

function RunPasWeave: Integer;
begin
  try
    if (ParamCount = 0) or (ParamStr(1) = '--help') or
       (ParamStr(1) = '-h') then
      begin
        PrintUsage;
        Exit(0);
      end;
    if ParamStr(1) = '--version' then
    begin
      WriteLn('PasWeave ', PasWeaveVersion);
      Exit(0);
    end;
    if ParamStr(1) <> 'build' then
      raise EPasWeaveInputError.CreateFmt('unknown command: %s', [ParamStr(1)]);
    Result := RunBuild;
  except
    on E: EPasWeaveInputError do
    begin
      WriteLn(StdErr, 'pasweave: ', E.Message);
      WriteLn(StdErr, 'Run "pasweave --help" for usage.');
      Result := 2;
    end;
    on E: ECompilerConfigurationError do
    begin
      WriteLn(StdErr, 'pasweave: ', E.Message);
      WriteLn(StdErr, 'Run "pasweave --help" for usage.');
      Result := 2;
    end;
    on E: ELazarusConfigurationError do
    begin
      WriteLn(StdErr, 'pasweave: ', E.Message);
      WriteLn(StdErr, 'Run "pasweave --help" for usage.');
      Result := 2;
    end;
    on E: Exception do
    begin
      WriteLn(StdErr, 'pasweave: internal error: ', E.Message);
      Result := 3;
    end;
  end;
end;

end.
