unit PasWeave.Parser;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, PasWeave.Model, PasWeave.Comments;

type
  EPasWeaveInputError = class(Exception);

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer): TDocProject; overload;
function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles): TDocProject; overload;

implementation

uses
  Classes, PasWeave.Diagnostics, PasWeave.FPCAdapter;

procedure AddMatchingFiles(const ADirectory, AMask: string; AFiles: TStrings);
var
  Search: TSearchRec;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + AMask,
    faAnyFile, Search) = 0 then
  try
    repeat
      if (Search.Attr and faDirectory) = 0 then
        AFiles.Add(IncludeTrailingPathDelimiter(ADirectory) + Search.Name);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function NormalisePath(const APath: string): string;
begin
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
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

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer): TDocProject;
begin
  Result := BuildProject(ASourcePath, AProjectName, AAttemptedFileCount,
    DefaultDocumentationCommentStyles);
end;

function BuildProject(const ASourcePath, AProjectName: string;
  out AAttemptedFileCount: Integer;
  ACommentStyles: TDocumentationCommentStyles): TDocProject;
var
  Files: TStringList;
  SourceRoot: string;
  DisplayRoot: string;
  UnitModel: TDocUnit;
  Diagnostic: TDiagnostic;
  I: Integer;
begin
  AAttemptedFileCount := 0;
  if not FileExists(ASourcePath) and not DirectoryExists(ASourcePath) then
    raise EPasWeaveInputError.CreateFmt('source path does not exist: %s',
      [ASourcePath]);

  Files := TStringList.Create;
  try
    Files.Sorted := True;
    Files.CaseSensitive := False;
    Files.Duplicates := dupIgnore;
    if DirectoryExists(ASourcePath) then
    begin
      SourceRoot := ExpandFileName(ASourcePath);
      DisplayRoot := ExcludeTrailingPathDelimiter(ASourcePath);
      AddMatchingFiles(SourceRoot, '*.pas', Files);
      AddMatchingFiles(SourceRoot, '*.pp', Files);
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
        'no Pascal unit files (*.pas or *.pp) found in: %s', [ASourcePath]);

    Result := TDocProject.Create;
    try
      if AProjectName <> '' then
        Result.Name := AProjectName
      else
        Result.Name := DefaultProjectName(ASourcePath);
      Result.SourceRoot := NormalisePath(DisplayRoot);

      AAttemptedFileCount := Files.Count;
      for I := 0 to Files.Count - 1 do
      begin
        UnitModel := nil;
        Diagnostic := nil;
        if ParseUnitFile(Files[I], SourceRoot, ACommentStyles, UnitModel,
          Diagnostic) then
          Result.Units.Add(UnitModel)
        else if Assigned(Diagnostic) then
          Result.Errors.Add(Diagnostic);
      end;
    except
      Result.Free;
      raise;
    end;
  finally
    Files.Free;
  end;
end;

end.
