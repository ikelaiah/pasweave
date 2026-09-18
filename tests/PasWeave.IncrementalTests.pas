unit PasWeave.IncrementalTests;

{$mode objfpc}{$H+}

interface

procedure RunIncrementalTests;

implementation

uses
  Classes, SysUtils, PasWeave.Hashing, PasWeave.Incremental,
  PasWeave.Compiler, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.Markdown, PasWeave.Render.HTML, PasWeave.TestSupport;

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

procedure CheckRejectedManifest(const AName, AManifestJSON: string);
const
  ManifestCheckDirectory = 'build/incremental-manifest-checks';
begin
  WriteTextFile(ManifestCheckDirectory + '/manifest.json', AManifestJSON);
  Check(not Assigned(ReadManifest(ManifestCheckDirectory)),
    AName + ' should be rejected as a manifest');
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
  AtomicDirectory: string;
  ValidSHA: string;
begin
  BeginTest('incremental builds');
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

  ValidSHA := StringOfChar('a', 64);
  CheckRejectedManifest('a root that is not an object', '[1, 2, 3]');
  CheckRejectedManifest('a future schema version',
    '{"schemaVersion": 2, "outputs": []}');
  CheckRejectedManifest('a parent-traversal output path',
    '{"schemaVersion": 1, "outputs": [{"path": "../escape.md", "sha256": "' +
    ValidSHA + '", "size": 1}]}');
  CheckRejectedManifest('an absolute output path',
    '{"schemaVersion": 1, "outputs": [{"path": "C:/abs.md", "sha256": "' +
    ValidSHA + '", "size": 1}]}');
  CheckRejectedManifest('a backslash output path',
    '{"schemaVersion": 1, "outputs": [{"path": "a\\b.md", "sha256": "' +
    ValidSHA + '", "size": 1}]}');
  CheckRejectedManifest('a truncated digest',
    '{"schemaVersion": 1, "outputs": [{"path": "ok.md", "sha256": "abc", ' +
    '"size": 1}]}');
  CheckRejectedManifest('a negative size',
    '{"schemaVersion": 1, "outputs": [{"path": "ok.md", "sha256": "' +
    ValidSHA + '", "size": -1}]}');
  CheckRejectedManifest('a non-object output entry',
    '{"schemaVersion": 1, "outputs": [42]}');
  CheckRejectedManifest('an empty output path',
    '{"schemaVersion": 1, "outputs": [{"path": "", "sha256": "' +
    ValidSHA + '", "size": 1}]}');
  WriteTextFile('build/incremental-manifest-checks/manifest.json',
    '{"schemaVersion": 1, "outputs": [{"path": "ok.md", "sha256": "' +
    ValidSHA + '", "size": 1}]}');
  ReadBack := ReadManifest('build/incremental-manifest-checks');
  try
    Check(Assigned(ReadBack) and (Length(ReadBack.Entries) = 1),
      'a well-formed manifest should still be accepted');
  finally
    ReadBack.Free;
  end;

  AtomicDirectory := 'build/incremental-atomic-docs';
  DeleteTree(AtomicDirectory);
  WriteTextFile(AtomicDirectory + '/source.txt', 'copied content');
  BeginOutputLedger;
  WriteOutputFile(AtomicDirectory + '/page.html', 'first version');
  WriteOutputFile(AtomicDirectory + '/page.html', 'second version');
  Check(ReadUTF8File(AtomicDirectory + '/page.html') = 'second version',
    'atomic writes should replace existing output content');
  WriteOutputCopy(AtomicDirectory + '/source.txt', AtomicDirectory +
    '/asset.css');
  WriteOutputCopy(AtomicDirectory + '/source.txt', AtomicDirectory +
    '/asset.css');
  Check(ReadUTF8File(AtomicDirectory + '/asset.css') = 'copied content',
    'atomic copies should replace existing output content');
  Check(not FileExists(AtomicDirectory + '/page.html.pasweave-tmp') and
    not FileExists(AtomicDirectory + '/asset.css.pasweave-tmp'),
    'atomic writes should not leave temporary files behind');

  DeleteTree('build/incremental-test-input');
  DeleteTree(OutputDirectory);
  DeleteTree(SecondOutputDirectory);
  DeleteTree(StaleDirectory);
  DeleteTree(AtomicDirectory);
  DeleteTree('build/incremental-manifest-checks');
end;

end.
