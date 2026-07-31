unit PasWeave.CLI;

{$mode objfpc}{$H+}

interface

function RunPasWeave: Integer;

implementation

uses
  Classes, SysUtils, PasWeave.Diagnostics, PasWeave.Model,
  PasWeave.Model.JSON, PasWeave.Parser, PasWeave.Render.Markdown,
  PasWeave.Render.HTML;

procedure PrintUsage;
begin
  WriteLn('PasWeave - Free Pascal-first documentation model generator');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  pasweave build <unit-or-directory> [--output <directory>]');
  WriteLn('                 [--project-name <name>] [--verbose]');
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
  WriteLn('[error] ', Location, '  ', ADiagnostic.MessageText);
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
  MarkdownOutputPath: string;
  HTMLOutputPath: string;
begin
  SourcePath := '';
  OutputPath := 'build/docs';
  ProjectName := '';
  Verbose := False;
  I := 2;
  while I <= ParamCount do
  begin
    if ParamStr(I) = '--output' then
      OutputPath := RequireOptionValue(I, '--output')
    else if ParamStr(I) = '--project-name' then
      ProjectName := RequireOptionValue(I, '--project-name')
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

  Project := BuildProject(SourcePath, ProjectName, AttemptedCount);
  try
    OutputFile := IncludeTrailingPathDelimiter(OutputPath) + 'api-model.json';
    WriteProjectJSON(Project, OutputFile);
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

    ParsedCount := Project.Units.Count;
    WriteLn;
    WriteLn('Generated ', Project.SymbolCount, ' symbols from ', ParsedCount,
      ' of ', AttemptedCount, ' units, with ', Project.Warnings.Count,
      ' warnings and ', Project.Errors.Count, ' errors.');
    WriteLn('Wrote ', OutputFile);
    WriteLn('Wrote ', IncludeTrailingPathDelimiter(MarkdownOutputPath),
      'index.md and ', Project.Units.Count, ' unit pages');
    WriteLn('Wrote ', IncludeTrailingPathDelimiter(HTMLOutputPath),
      'index.html, search assets, and ', Project.Units.Count, ' unit pages');

    if Project.Errors.Count > 0 then
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
    on E: Exception do
    begin
      WriteLn(StdErr, 'pasweave: internal error: ', E.Message);
      Result := 3;
    end;
  end;
end;

end.
