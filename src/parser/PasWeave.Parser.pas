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
      ResolveTypeRelationships(Result);
    except
      Result.Free;
      raise;
    end;
  finally
    Files.Free;
  end;
end;

end.
