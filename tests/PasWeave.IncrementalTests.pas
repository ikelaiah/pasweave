unit PasWeave.IncrementalTests;

{$mode objfpc}{$H+}

interface

procedure RunIncrementalTests;

implementation

uses
  Classes, SysUtils, PasWeave.Hashing, PasWeave.Incremental,
  PasWeave.Compiler, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.Markdown, PasWeave.Render.HTML;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('incremental test failed: ' + AMessage);
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

function AssembleManifest(AProject: TDocProject; const AOutputDirectory,
  AInputFingerprint: string): TManifest;
var
  Entries: TStringList;
  I: Integer;
  FirstSeparator: Integer;
  SecondSeparator: Integer;
begin
  Result := TManifest.Create;
  Result.SchemaVersion := ManifestSchemaVersion;
  Result.PasWeaveVersion := 'test';
  Result.InputFingerprint := AInputFingerprint;
  Result.UnitCount := AProject.Units.Count;
  Result.SymbolCount := AProject.SymbolCount;
  Result.AttemptedCount := 1;
  Result.WarningCount := AProject.Warnings.Count;
  Result.ErrorCount := AProject.Errors.Count;
  Entries := LedgerEntries(AOutputDirectory);
  try
    SetLength(Result.Entries, Entries.Count);
    for I := 0 to Entries.Count - 1 do
    begin
      FirstSeparator := Pos(#1, Entries[I]);
      SecondSeparator := Pos(#1, Copy(Entries[I], FirstSeparator + 1,
        MaxInt)) + FirstSeparator;
      Result.Entries[I].Path := Copy(Entries[I], 1, FirstSeparator - 1);
      Result.Entries[I].SHA256 := Copy(Entries[I], FirstSeparator + 1,
        SecondSeparator - FirstSeparator - 1);
      Result.Entries[I].Size := StrToInt64(Copy(Entries[I],
        SecondSeparator + 1, MaxInt));
    end;
  finally
    Entries.Free;
  end;
end;

procedure RunIncrementalTests;
var
  Project: TDocProject;
  AttemptedCount: Integer;
  OutputDirectory: string;
  SecondOutputDirectory: string;
  Manifest: TManifest;
  ReadBack: TManifest;
  FirstManifestBytes: UTF8String;
  SecondManifestBytes: UTF8String;
  InputFiles: TStringList;
  Fingerprint: string;
  SecondFingerprint: string;
  ConfigA: string;
  ConfigB: string;
  Compiler: TCompilerOptions;
  OldManifest: TManifest;
  NewPaths: TStringList;
  StaleDirectory: string;
begin
  Check(SHA256HexString('') =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'SHA-256 of the empty string should match the NIST vector');
  Check(SHA256HexString('abc') =
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    'SHA-256 of "abc" should match the NIST vector');
  Check(SHA256HexString('The quick brown fox jumps over the lazy dog') =
    'd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592',
    'SHA-256 of the pangram should match the NIST vector');

  ConfigA := 'config' + #10 + 'project-name=Demo' + #10;
  ConfigB := 'config' + #10 + 'project-name=Changed' + #10;
  WriteTextFile('build/incremental-test-input/a.txt', 'alpha');
  WriteTextFile('build/incremental-test-input/b.txt', 'bravo');
  InputFiles := TStringList.Create;
  try
    InputFiles.Sorted := True;
    InputFiles.Add(ExpandFileName('build/incremental-test-input/a.txt'));
    InputFiles.Add(ExpandFileName('build/incremental-test-input/b.txt'));
    Fingerprint := ComputeBuildFingerprint(ConfigA, InputFiles, 'assets');
    SecondFingerprint := ComputeBuildFingerprint(ConfigA, InputFiles, 'assets');
    Check(Fingerprint = SecondFingerprint,
      'the input fingerprint should be deterministic');
    SecondFingerprint := ComputeBuildFingerprint(ConfigB, InputFiles, 'assets');
    Check(Fingerprint <> SecondFingerprint,
      'a changed configuration should change the fingerprint');
    WriteTextFile('build/incremental-test-input/b.txt', 'bravo-changed');
    SecondFingerprint := ComputeBuildFingerprint(ConfigA, InputFiles, 'assets');
    Check(Fingerprint <> SecondFingerprint,
      'a changed input file should change the fingerprint');
    WriteTextFile('build/incremental-test-input/b.txt', 'bravo');
  finally
    InputFiles.Free;
  end;

  OutputDirectory := 'build/incremental-test-docs';
  SecondOutputDirectory := 'build/incremental-second-docs';
  DeleteTree(OutputDirectory);
  DeleteTree(SecondOutputDirectory);

  Project := BuildProject('tests/fixtures/SimpleUnit.pas',
    'IncrementalFixture', AttemptedCount);
  try
    Compiler := TCompilerOptions.Create;
    try
      InputFiles := EnumerateInputFiles('tests/fixtures/SimpleUnit.pas', False,
        nil, Compiler, nil, nil);
      try
        Fingerprint := ComputeBuildFingerprint('config' + #10, InputFiles,
          'assets');
      finally
        InputFiles.Free;
      end;
    finally
      Compiler.Free;
    end;

    BeginOutputLedger;
    WriteProjectJSON(Project, IncludeTrailingPathDelimiter(OutputDirectory) +
      'api-model.json');
    WriteMarkdownDocumentation(Project,
      IncludeTrailingPathDelimiter(OutputDirectory) + 'markdown');
    WriteHTMLDocumentation(Project,
      IncludeTrailingPathDelimiter(OutputDirectory) + 'html');

    Manifest := AssembleManifest(Project, OutputDirectory, Fingerprint);
    try
      Check(Length(Manifest.Entries) > 0,
        'the output ledger should record generated pages and assets');
      WriteManifest(OutputDirectory, Manifest);
    finally
      Manifest.Free;
    end;

    FirstManifestBytes := ReadUTF8File(ManifestFilePath(OutputDirectory));
    Manifest := AssembleManifest(Project, OutputDirectory, Fingerprint);
    try
      WriteManifest(OutputDirectory, Manifest);
    finally
      Manifest.Free;
    end;
    SecondManifestBytes := ReadUTF8File(ManifestFilePath(OutputDirectory));
    Check(FirstManifestBytes = SecondManifestBytes,
      'the manifest should be deterministic across identical builds');

    ReadBack := ReadManifest(OutputDirectory);
    try
      Check(Assigned(ReadBack), 'a written manifest should be readable');
      Check(ReadBack.InputFingerprint = Fingerprint,
        'the manifest should retain its input fingerprint');
      Check(ReadBack.UnitCount = 1, 'the manifest should record the unit count');
      Check(ReadBack.SymbolCount = Project.SymbolCount,
        'the manifest should record the symbol count');
      Check(ManifestOutputsPresent(ReadBack, OutputDirectory),
        'an intact manifest should report all outputs present');
    finally
      ReadBack.Free;
    end;

    DeleteFile(IncludeTrailingPathDelimiter(OutputDirectory) +
      'html' + PathDelim + 'index.html');
    ReadBack := ReadManifest(OutputDirectory);
    try
      Check(Assigned(ReadBack) and
        not ManifestOutputsPresent(ReadBack, OutputDirectory),
        'a missing output should be detected as an interrupted build');
    finally
      ReadBack.Free;
    end;

    BeginOutputLedger;
    WriteProjectJSON(Project, IncludeTrailingPathDelimiter(OutputDirectory) +
      'api-model.json');
    WriteMarkdownDocumentation(Project,
      IncludeTrailingPathDelimiter(OutputDirectory) + 'markdown');
    WriteHTMLDocumentation(Project,
      IncludeTrailingPathDelimiter(OutputDirectory) + 'html');
    Manifest := AssembleManifest(Project, OutputDirectory, Fingerprint);
    try
      WriteManifest(OutputDirectory, Manifest);
    finally
      Manifest.Free;
    end;

    BeginOutputLedger;
    WriteProjectJSON(Project, IncludeTrailingPathDelimiter(SecondOutputDirectory) +
      'api-model.json');
    WriteMarkdownDocumentation(Project,
      IncludeTrailingPathDelimiter(SecondOutputDirectory) + 'markdown');
    WriteHTMLDocumentation(Project,
      IncludeTrailingPathDelimiter(SecondOutputDirectory) + 'html');
    Manifest := AssembleManifest(Project, SecondOutputDirectory, Fingerprint);
    try
      WriteManifest(SecondOutputDirectory, Manifest);
    finally
      Manifest.Free;
    end;

    Check(DirectoryTreesMatch(OutputDirectory, SecondOutputDirectory),
      'a clean build and an independent rebuild should match byte-for-byte');
  finally
    Project.Free;
  end;

  StaleDirectory := 'build/incremental-stale-docs';
  DeleteTree(StaleDirectory);
  WriteTextFile(StaleDirectory + '/markdown/units/Keep.md', 'keep');
  WriteTextFile(StaleDirectory + '/markdown/units/Remove.md', 'remove');
  WriteTextFile(StaleDirectory + '/markdown/units/UserFile.txt', 'unowned');
  OldManifest := TManifest.Create;
  try
    OldManifest.SchemaVersion := ManifestSchemaVersion;
    OldManifest.PasWeaveVersion := 'test';
    OldManifest.InputFingerprint := 'old';
    SetLength(OldManifest.Entries, 2);
    OldManifest.Entries[0].Path := 'markdown/units/Keep.md';
    OldManifest.Entries[0].SHA256 := StringOfChar('0', 64);
    OldManifest.Entries[0].Size := 4;
    OldManifest.Entries[1].Path := 'markdown/units/Remove.md';
    OldManifest.Entries[1].SHA256 := StringOfChar('0', 64);
    OldManifest.Entries[1].Size := 6;
    NewPaths := TStringList.Create;
    try
      NewPaths.Sorted := True;
      NewPaths.Add('markdown/units/Keep.md');
      RemoveStaleOutputs(StaleDirectory, OldManifest, NewPaths);
    finally
      NewPaths.Free;
    end;
    Check(FileExists(StaleDirectory + '/markdown/units/Keep.md'),
      'stale cleanup should preserve outputs still in the manifest');
    Check(not FileExists(StaleDirectory + '/markdown/units/Remove.md'),
      'stale cleanup should delete only previously manifest-owned files');
    Check(FileExists(StaleDirectory + '/markdown/units/UserFile.txt'),
      'stale cleanup should never delete unowned files');
  finally
    OldManifest.Free;
  end;

  WriteTextFile(StaleDirectory + '/manifest.json', 'not valid json {');
  Check(not Assigned(ReadManifest(StaleDirectory)),
    'a corrupted manifest should be recoverable rather than fatal');

  DeleteTree('build/incremental-test-input');
  DeleteTree(OutputDirectory);
  DeleteTree(SecondOutputDirectory);
  DeleteTree(StaleDirectory);
end;

end.
