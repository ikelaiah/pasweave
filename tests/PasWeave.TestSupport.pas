/// Shared assertions and fixture helpers for the PasWeave test suites.
///
/// Every suite announces its current case with `BeginTest` so a failed check
/// names the behavior under test instead of only printing the assertion text.
unit PasWeave.TestSupport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PasWeave.Diagnostics, PasWeave.Model;

/// Names the behavior under test for subsequent `Check` failures.
procedure BeginTest(const AName: string);

/// Raises an exception naming the current test when `ACondition` is False.
procedure Check(ACondition: Boolean; const AMessage: string);

function ReadUTF8File(const AFilename: string): UTF8String;
procedure WriteTextFile(const AFilename, AContent: string);
procedure DeleteTree(const ADirectory: string);
function DirectoryTreesMatch(const ALeft, ARight: string): Boolean;

function FindSymbol(AUnit: TDocUnit; const AName: string): TDocSymbol;
function FindUnitModel(AProject: TDocProject; const AName: string): TDocUnit;
function FindTypeRelationship(ASymbol: TDocSymbol;
  AKind: TTypeRelationshipKind): TDocTypeRelationship;
function FindDirective(ASymbol: TDocSymbol; const AName,
  ASubject: string): TDocDirective;
function HasDirective(ASymbol: TDocSymbol; const AName: string): Boolean;
function HasDiagnosticCode(ADiagnostics: TList; const ACode: string): Boolean;
function CountOccurrences(const AText, AValue: string): Integer;

function WithoutTrailingLineBreaks(const AText: UTF8String): UTF8String;
function SampleOutputMatches(const AExpected, AFilename: UTF8String): Boolean;
function RetargetSampleIndexAssets(const AHTML: UTF8String): UTF8String;
function RetargetSampleUnitAssets(const AHTML: UTF8String): UTF8String;

implementation

var
  CurrentTestName: string;

procedure BeginTest(const AName: string);
begin
  CurrentTestName := AName;
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
  begin
    if CurrentTestName <> '' then
      raise Exception.Create('test failed [' + CurrentTestName + ']: ' +
        AMessage);
    raise Exception.Create('test failed: ' + AMessage);
  end;
end;

function ReadUTF8File(const AFilename: string): UTF8String;
var
  InputStream: TFileStream;
begin
  InputStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, InputStream.Size);
    if Length(Result) > 0 then
      InputStream.ReadBuffer(Result[1], Length(Result));
  finally
    InputStream.Free;
  end;
end;

procedure WriteTextFile(const AFilename, AContent: string);
var
  OutputStream: TFileStream;
begin
  ForceDirectories(ExtractFileDir(AFilename));
  OutputStream := TFileStream.Create(AFilename, fmCreate);
  try
    if Length(AContent) > 0 then
      OutputStream.WriteBuffer(AContent[1], Length(AContent));
  finally
    OutputStream.Free;
  end;
end;

procedure CollectTree(const ADirectory, ARelative: string;
  AEntries: TStringList);
var
  Search: TSearchRec;
  Relative: string;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    Search) <> 0 then
    Exit;
  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then
        Continue;
      if ARelative = '' then
        Relative := Search.Name
      else
        Relative := ARelative + '/' + Search.Name;
      if (Search.Attr and faDirectory) <> 0 then
        CollectTree(IncludeTrailingPathDelimiter(ADirectory) + Search.Name,
          Relative, AEntries)
      else
        AEntries.Add(Relative);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

procedure DeleteTree(const ADirectory: string);
var
  Search: TSearchRec;
  FullPath: string;
begin
  if not DirectoryExists(ADirectory) then
    Exit;
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    Search) = 0 then
  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then
        Continue;
      FullPath := IncludeTrailingPathDelimiter(ADirectory) + Search.Name;
      if (Search.Attr and faDirectory) <> 0 then
        DeleteTree(FullPath)
      else
        DeleteFile(FullPath);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
  RemoveDir(ADirectory);
end;

function DirectoryTreesMatch(const ALeft, ARight: string): Boolean;
var
  LeftEntries: TStringList;
  RightEntries: TStringList;
  I: Integer;
begin
  Result := False;
  LeftEntries := TStringList.Create;
  RightEntries := TStringList.Create;
  try
    LeftEntries.Sorted := True;
    RightEntries.Sorted := True;
    CollectTree(ALeft, '', LeftEntries);
    CollectTree(ARight, '', RightEntries);
    if LeftEntries.Count <> RightEntries.Count then
      Exit;
    for I := 0 to LeftEntries.Count - 1 do
    begin
      if LeftEntries[I] <> RightEntries[I] then
        Exit;
      if ReadUTF8File(IncludeTrailingPathDelimiter(ALeft) +
        StringReplace(LeftEntries[I], '/', PathDelim, [rfReplaceAll])) <>
        ReadUTF8File(IncludeTrailingPathDelimiter(ARight) +
        StringReplace(RightEntries[I], '/', PathDelim, [rfReplaceAll])) then
        Exit;
    end;
    Result := True;
  finally
    RightEntries.Free;
    LeftEntries.Free;
  end;
end;

function FindSymbol(AUnit: TDocUnit; const AName: string): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if SameText(TDocSymbol(AUnit.Symbols[I]).Name, AName) then
      Exit(TDocSymbol(AUnit.Symbols[I]));
end;

function FindUnitModel(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
end;

function FindTypeRelationship(ASymbol: TDocSymbol;
  AKind: TTypeRelationshipKind): TDocTypeRelationship;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to ASymbol.TypeRelationships.Count - 1 do
    if TDocTypeRelationship(ASymbol.TypeRelationships[I]).Kind = AKind then
      Exit(TDocTypeRelationship(ASymbol.TypeRelationships[I]));
end;

function FindDirective(ASymbol: TDocSymbol; const AName,
  ASubject: string): TDocDirective;
var
  I: Integer;
  Candidate: TDocDirective;
begin
  Result := nil;
  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Candidate := TDocDirective(ASymbol.Directives[I]);
    if SameText(Candidate.Name, AName) and
      SameText(Candidate.Subject, ASubject) then
      Exit(Candidate);
  end;
end;

function HasDirective(ASymbol: TDocSymbol; const AName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ASymbol.Directives.Count - 1 do
    if SameText(TDocDirective(ASymbol.Directives[I]).Name, AName) then
      Exit(True);
end;

function HasDiagnosticCode(ADiagnostics: TList; const ACode: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ADiagnostics.Count - 1 do
    if TDiagnostic(ADiagnostics[I]).Code = ACode then
      Exit(True);
end;

function CountOccurrences(const AText, AValue: string): Integer;
var
  Position: Integer;
  Offset: Integer;
begin
  Result := 0;
  Offset := 1;
  Position := Pos(AValue, Copy(AText, Offset, MaxInt));
  while Position > 0 do
  begin
    Inc(Result);
    Inc(Offset, Position + Length(AValue) - 1);
    Position := Pos(AValue, Copy(AText, Offset, MaxInt));
  end;
end;

function WithoutTrailingLineBreaks(const AText: UTF8String): UTF8String;
begin
  Result := AText;
  while (Length(Result) > 0) and
    (Result[Length(Result)] in [#10, #13]) do
    Delete(Result, Length(Result), 1);
end;

function SampleOutputMatches(const AExpected, AFilename: UTF8String): Boolean;
var
  Actual: UTF8String;
  Expected: UTF8String;
  Position: Integer;
begin
  Expected := WithoutTrailingLineBreaks(AExpected);
  Actual := WithoutTrailingLineBreaks(ReadUTF8File(string(AFilename)));
  Result := Expected = Actual;
  if not Result then
  begin
    Position := 1;
    while (Position <= Length(Expected)) and
      (Position <= Length(Actual)) and
      (Expected[Position] = Actual[Position]) do
      Inc(Position);
    WriteLn(StdErr, 'sample mismatch: ', AFilename, ' expected=',
      Length(Expected), ' actual=', Length(Actual), ' position=', Position);
  end;
end;

function RetargetSampleIndexAssets(const AHTML: UTF8String): UTF8String;
begin
  Result := UTF8String(StringReplace(string(AHTML),
    'href="assets/katex/', 'href="../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="assets/katex/', 'src="../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="assets/mermaid/', 'src="../../../../assets/mermaid/',
    [rfReplaceAll]));
end;

function RetargetSampleUnitAssets(const AHTML: UTF8String): UTF8String;
begin
  Result := UTF8String(StringReplace(string(AHTML),
    'href="../assets/katex/', 'href="../../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="../assets/katex/', 'src="../../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="../assets/mermaid/', 'src="../../../../../assets/mermaid/',
    [rfReplaceAll]));
end;

end.
