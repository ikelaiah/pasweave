unit PasWeave.CLI;

{$mode objfpc}{$H+}

interface

function RunPasWeave: Integer;

implementation

uses
  Classes, SysUtils, PasWeave.Comments, PasWeave.Compiler,
  PasWeave.Diagnostics, PasWeave.Lazarus, PasWeave.Model,
  PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.Markdown,
  PasWeave.Render.HTML, PasWeave.Validation, PasWeave.Version;

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
  WriteLn('                 [--min-documentation-coverage=<0-100>]');
  WriteLn('                 [--fail-on=<error|warning>]');
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
  CommentStyleValue: string;
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
  ThresholdValue: string;
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
  CommentStyles := DefaultDocumentationCommentStyles;
  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  CompilerOptions := TCompilerOptions.Create;
  PackagePaths := TStringList.Create;
  LazarusConfiguration := nil;
  try
    I := 2;
    while I <= ParamCount do
    begin
      if ParamStr(I) = '--output' then
        OutputPath := RequireOptionValue(I, '--output')
      else if ParamStr(I) = '--project-name' then
      begin
        ProjectName := RequireOptionValue(I, '--project-name');
        ProjectNameExplicit := True;
      end
      else if Pos('--project-name=', ParamStr(I)) = 1 then
      begin
        ProjectName := Copy(ParamStr(I), Length('--project-name=') + 1,
          MaxInt);
        ProjectNameExplicit := True;
      end
      else if ParamStr(I) = '--doc-comments' then
      begin
        CommentStyleValue := RequireOptionValue(I, '--doc-comments');
        if not TryParseDocumentationCommentStyles(CommentStyleValue,
          CommentStyles) then
          raise EPasWeaveInputError.CreateFmt(
            'invalid documentation comment styles: %s ' +
            '(expected slash (///), brace ({ ... }), paren ((* ... *)), ' +
            'a comma-separated combination, or all)',
            [CommentStyleValue]);
      end
      else if Pos('--doc-comments=', ParamStr(I)) = 1 then
      begin
        CommentStyleValue := Copy(ParamStr(I), Length('--doc-comments=') + 1,
          MaxInt);
        if not TryParseDocumentationCommentStyles(CommentStyleValue,
          CommentStyles) then
          raise EPasWeaveInputError.CreateFmt(
            'invalid documentation comment styles: %s ' +
            '(expected slash (///), brace ({ ... }), paren ((* ... *)), ' +
            'a comma-separated combination, or all)',
            [CommentStyleValue]);
      end
      else if ParamStr(I) = '--recursive' then
        DiscoveryOptions.Recursive := True
      else if ParamStr(I) = '--include' then
        DiscoveryOptions.AddIncludePattern(
          RequireOptionValue(I, '--include'))
      else if Pos('--include=', ParamStr(I)) = 1 then
        DiscoveryOptions.AddIncludePattern(Copy(ParamStr(I),
          Length('--include=') + 1, MaxInt))
      else if ParamStr(I) = '--exclude' then
        DiscoveryOptions.AddExcludePattern(
          RequireOptionValue(I, '--exclude'))
      else if Pos('--exclude=', ParamStr(I)) = 1 then
        DiscoveryOptions.AddExcludePattern(Copy(ParamStr(I),
          Length('--exclude=') + 1, MaxInt))
      else if ParamStr(I) = '--unit-path' then
        CompilerOptions.AddUnitPath(
          RequireOptionValue(I, '--unit-path'))
      else if Pos('--unit-path=', ParamStr(I)) = 1 then
        CompilerOptions.AddUnitPath(Copy(ParamStr(I),
          Length('--unit-path=') + 1, MaxInt))
      else if ParamStr(I) = '--include-path' then
        CompilerOptions.AddIncludePath(
          RequireOptionValue(I, '--include-path'))
      else if Pos('--include-path=', ParamStr(I)) = 1 then
        CompilerOptions.AddIncludePath(Copy(ParamStr(I),
          Length('--include-path=') + 1, MaxInt))
      else if ParamStr(I) = '--define' then
        CompilerOptions.AddDefine(RequireOptionValue(I, '--define'))
      else if Pos('--define=', ParamStr(I)) = 1 then
        CompilerOptions.AddDefine(Copy(ParamStr(I),
          Length('--define=') + 1, MaxInt))
      else if ParamStr(I) = '--target-os' then
        CompilerOptions.SetTargetOS(
          RequireOptionValue(I, '--target-os'))
      else if Pos('--target-os=', ParamStr(I)) = 1 then
        CompilerOptions.SetTargetOS(Copy(ParamStr(I),
          Length('--target-os=') + 1, MaxInt))
      else if ParamStr(I) = '--target-cpu' then
        CompilerOptions.SetTargetCPU(
          RequireOptionValue(I, '--target-cpu'))
      else if Pos('--target-cpu=', ParamStr(I)) = 1 then
        CompilerOptions.SetTargetCPU(Copy(ParamStr(I),
          Length('--target-cpu=') + 1, MaxInt))
      else if ParamStr(I) = '--build-mode' then
        BuildMode := RequireOptionValue(I, '--build-mode')
      else if Pos('--build-mode=', ParamStr(I)) = 1 then
        BuildMode := Copy(ParamStr(I), Length('--build-mode=') + 1, MaxInt)
      else if ParamStr(I) = '--package-path' then
        PackagePaths.Add(RequireOptionValue(I, '--package-path'))
      else if Pos('--package-path=', ParamStr(I)) = 1 then
        PackagePaths.Add(Copy(ParamStr(I), Length('--package-path=') + 1,
          MaxInt))
      else if ParamStr(I) = '--min-documentation-coverage' then
      begin
        ThresholdValue := RequireOptionValue(I, '--min-documentation-coverage');
        if not TryStrToInt(ThresholdValue, MinimumCoverage) or
          (MinimumCoverage < 0) or (MinimumCoverage > 100) then
          raise EPasWeaveInputError.Create(
            '--min-documentation-coverage must be an integer from 0 to 100');
        HasMinimumCoverage := True;
      end
      else if Pos('--min-documentation-coverage=', ParamStr(I)) = 1 then
      begin
        ThresholdValue := Copy(ParamStr(I),
          Length('--min-documentation-coverage=') + 1, MaxInt);
        if not TryStrToInt(ThresholdValue, MinimumCoverage) or
          (MinimumCoverage < 0) or (MinimumCoverage > 100) then
          raise EPasWeaveInputError.Create(
            '--min-documentation-coverage must be an integer from 0 to 100');
        HasMinimumCoverage := True;
      end
      else if ParamStr(I) = '--fail-on' then
      begin
        ThresholdValue := RequireOptionValue(I, '--fail-on');
        if not TryParseDiagnosticSeverity(ThresholdValue, FailureSeverity) then
          raise EPasWeaveInputError.Create(
            '--fail-on must be warning or error');
      end
      else if Pos('--fail-on=', ParamStr(I)) = 1 then
      begin
        ThresholdValue := Copy(ParamStr(I), Length('--fail-on=') + 1, MaxInt);
        if not TryParseDiagnosticSeverity(ThresholdValue, FailureSeverity) then
          raise EPasWeaveInputError.Create(
            '--fail-on must be warning or error');
      end
      else if ParamStr(I) = '--verbose' then
        Verbose := True
      else if (ParamStr(I) = '--help') or (ParamStr(I) = '-h') then
      begin
        PrintUsage;
        Exit(0);
      end
      else if (Length(ParamStr(I)) > 0) and (ParamStr(I)[1] = '-') then
        raise EPasWeaveInputError.CreateFmt('unknown option: %s', [ParamStr(I)])
      else if SourcePath = '' then
        SourcePath := ParamStr(I)
      else
        raise EPasWeaveInputError.Create('only one source path may be supplied');
      Inc(I);
    end;

    if SourcePath = '' then
      raise EPasWeaveInputError.Create('missing unit or source directory');

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
      Project := BuildProjectFromFiles(LazarusConfiguration.SourceRoot,
        ProjectName, LazarusConfiguration.SourceFiles, AttemptedCount,
        CommentStyles, CompilerOptions);
    end
    else
    begin
      if BuildMode <> '' then
        raise EPasWeaveInputError.Create(
          '--build-mode requires a Lazarus .lpi or .lpk input');
      if PackagePaths.Count > 0 then
        raise EPasWeaveInputError.Create(
          '--package-path requires a Lazarus .lpi or .lpk input');
      Project := BuildProject(SourcePath, ProjectName, AttemptedCount,
        CommentStyles, DiscoveryOptions, CompilerOptions);
    end;
  finally
    LazarusConfiguration.Free;
    PackagePaths.Free;
    CompilerOptions.Free;
    DiscoveryOptions.Free;
  end;
  try
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

    if HasDiagnosticsAtOrAbove(Project, FailureSeverity) then
      Result := 1
    else
      Result := 0;
  finally
    Project.Free;
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
