/// Owns the generated output tree: atomic file writes, the per-build
/// ledger, and the deterministic manifest.
///
/// This is a leaf unit so renderers and the model never link the parser.
unit PasWeave.Output;

{$mode objfpc}{$H+}

interface

uses
  Classes;



const
  /// Expected `schemaVersion` inside `manifest.json`.
  ManifestSchemaVersion = 1;
  /// Manifest filename written at the output root.
  ManifestFilename = 'manifest.json';

type
  /// One generated file recorded in the manifest.
  TManifestEntry = record
    /// Output-relative path using `/` separators (for example `html/index.html`).
    Path: string;
    /// Lowercase hex SHA-256 of the file content.
    SHA256: string;
    /// File size in bytes.
    Size: Int64;
  end;

  /// Deterministic record of one completed build.
  TManifest = class
  public
    /// Manifest schema version.
    SchemaVersion: Integer;
    /// PasWeave version that produced this manifest.
    PasWeaveVersion: string;
    /// Fingerprint of every build-affecting input.
    InputFingerprint: string;
    /// Number of parsed units.
    UnitCount: Integer;
    /// Number of documented symbols.
    SymbolCount: Integer;
    /// Number of attempted units including failures.
    AttemptedCount: Integer;
    /// Number of warnings in the completed build.
    WarningCount: Integer;
    /// Number of errors in the completed build.
    ErrorCount: Integer;
    /// Generated files owned by PasWeave.
    Entries: array of TManifestEntry;
  end;

/// Returns the full path to `manifest.json` inside an output directory.
///
/// @param AOutputDirectory Output root.
/// @returns The manifest file path.
function ManifestFilePath(const AOutputDirectory: string): string;

/// Starts a fresh per-build ledger of generated files.
procedure BeginOutputLedger;
/// Writes `AData` atomically and records it in the ledger.
///
/// @param AFilename Destination file.
/// @param AData UTF-8 content to write.
/// @returns Hex SHA-256 of the written content.
function WriteOutputFile(const AFilename: string;
  const AData: UTF8String): string;
/// Copies `ASource` to `ADestination` atomically and records it.
///
/// @param ASource Existing file to copy.
/// @param ADestination Destination file.
/// @returns Hex SHA-256 of the copied content.
function WriteOutputCopy(const ASource, ADestination: string): string;
/// Returns ledger entries as output-relative `path + #1 + sha + #1 + size` rows.
///
/// @param AOutputDirectory Output root used to relativize paths.
/// @returns Owned sorted list; caller frees it.
function LedgerEntries(const AOutputDirectory: string): TStringList;
/// Returns only the output-relative paths from the current ledger.
///
/// @param AOutputDirectory Output root used to relativize paths.
/// @returns Owned sorted list; caller frees it.
function LedgerPaths(const AOutputDirectory: string): TStringList;

/// Writes `AData` through a temp file plus rename so readers never see half-written output.
///
/// @param AFilename Destination file.
/// @param AData UTF-8 content to write.
procedure WriteFileAtomic(const AFilename: string; const AData: UTF8String);
/// Copies a file through a temp file plus rename.
///
/// @param ASource Existing file to copy.
/// @param ADestination Destination file.
procedure WriteFileAtomicCopy(const ASource, ADestination: string);

/// Reads and validates a prior manifest, or returns `nil` when missing or invalid.
///
/// Corrupt manifests are recoverable: the caller rebuilds from scratch.
///
/// @param AOutputDirectory Output root.
/// @returns Owned manifest, or `nil`.
function ReadManifest(const AOutputDirectory: string): TManifest;
/// Returns True when every manifest-listed output exists with matching size.
///
/// @param AManifest Prior manifest to check.
/// @param AOutputDirectory Output root.
/// @returns True when an incremental skip is safe.
function ManifestOutputsPresent(AManifest: TManifest;
  const AOutputDirectory: string): Boolean;
/// Writes `AManifest` as deterministic JSON.
///
/// @param AOutputDirectory Output root.
/// @param AManifest Manifest to persist.
procedure WriteManifest(const AOutputDirectory: string; AManifest: TManifest);

/// Deletes superseded outputs owned by the prior manifest, never user files.
///
/// Paths are validated to stay inside the output root before deletion.
///
/// @param AOutputDirectory Output root.
/// @param AOldManifest Prior manifest proving ownership.
/// @param ANewPaths Output-relative paths in the current build.
procedure RemoveStaleOutputs(const AOutputDirectory: string;
  AOldManifest: TManifest; const ANewPaths: TStrings);

implementation

uses
  SysUtils, FPJSON, JSONParser, PasWeave.FS, PasWeave.Hashing;

var
  GLedger: TStringList;

const
  TempFileSuffix = '.pasweave-tmp';

{$IFDEF MSWINDOWS}
const
  { Defined here instead of pulling in the Windows unit, whose FindFirst and
    friends would shadow SysUtils. }
  MoveFileReplaceExisting = $1;

function MoveFileExA(lpExistingFileName, lpNewFileName: PAnsiChar;
  dwFlags: DWORD): LongBool; stdcall; external 'kernel32' name 'MoveFileExA';
{$ENDIF}


/// Returns True when a manifest-relative path is safe to resolve inside the
/// output directory (no absolute paths, drive letters, or parent traversal).
function IsSafeManifestPath(const APath: string): Boolean;
var
  Normalised: string;
  Segment: string;
  StartPos: Integer;
  SlashPos: Integer;
begin
  Result := False;
  if APath = '' then
    Exit;
  Normalised := NormalisePath(APath);
  if (Normalised[1] = '/') or (Pos(':', Normalised) > 0) or
    (Pos('\', APath) > 0) then
    Exit;
  StartPos := 1;
  while StartPos <= Length(Normalised) do
  begin
    SlashPos := StartPos;
    while (SlashPos <= Length(Normalised)) and
      (Normalised[SlashPos] <> '/') do
      Inc(SlashPos);
    Segment := Copy(Normalised, StartPos, SlashPos - StartPos);
    if (Segment = '..') then
      Exit;
    StartPos := SlashPos + 1;
  end;
  Result := True;
end;

/// Resolves a manifest-relative path inside AOutputDirectory.
/// Returns '' when the resolved location would escape the output root.
function ResolveOutputPath(const AOutputDirectory,
  ARelativePath: string): string;
var
  Root: string;
  Candidate: string;
begin
  Result := '';
  if not IsSafeManifestPath(ARelativePath) then
    Exit;
  Root := NormalisePath(ExpandFileName(AOutputDirectory));
  if (Root <> '') and (Root[Length(Root)] <> '/') then
    Root := Root + '/';
  Candidate := NormalisePath(ExpandFileName(IncludeTrailingPathDelimiter(
    AOutputDirectory) + StringReplace(ARelativePath, '/', PathDelim,
    [rfReplaceAll])));
  if (Candidate = Copy(Root, 1, Length(Root) - 1)) then
    Exit;
  if Pos(Root, Candidate) <> 1 then
    Exit;
  Result := IncludeTrailingPathDelimiter(AOutputDirectory) +
    StringReplace(ARelativePath, '/', PathDelim, [rfReplaceAll]);
end;

function FileSizeOf(const AFilename: string): Int64;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result := Stream.Size;
  finally
    Stream.Free;
  end;
end;
function ManifestFilePath(const AOutputDirectory: string): string;
begin
  Result := IncludeTrailingPathDelimiter(AOutputDirectory) + ManifestFilename;
end;

function ManifestEntryFromJSON(AObject: TJSONObject): TManifestEntry;
begin
  Result.Path := AObject.Get('path', '');
  Result.SHA256 := AObject.Get('sha256', '');
  Result.Size := AObject.Get('size', Int64(0));
end;


function ReadManifest(const AOutputDirectory: string): TManifest;
var
  Data: TJSONData;
  Root: TJSONObject;
  Files: TJSONArray;
  I: Integer;
  Entry: TManifestEntry;
begin
  Result := nil;
  if not FileExists(ManifestFilePath(AOutputDirectory)) then
    Exit;
  try
    Data := GetJSON(ReadFileToString(ManifestFilePath(AOutputDirectory)));
  except
    Exit;
  end;
  try
    if not (Data is TJSONObject) then
      Exit;
    Root := TJSONObject(Data);
    if Root.Get('schemaVersion', 0) <> ManifestSchemaVersion then
      Exit;
    Result := TManifest.Create;
    Result.SchemaVersion := ManifestSchemaVersion;
    Result.PasWeaveVersion := Root.Get('pasweaveVersion', '');
    Result.InputFingerprint := Root.Get('inputFingerprint', '');
    Result.UnitCount := Root.Get('unitCount', 0);
    Result.SymbolCount := Root.Get('symbolCount', 0);
    Result.AttemptedCount := Root.Get('attemptedCount', 0);
    Result.WarningCount := Root.Get('warningCount', 0);
    Result.ErrorCount := Root.Get('errorCount', 0);
    I := Root.IndexOfName('outputs');
    if (I >= 0) and (Root.Items[I] is TJSONArray) then
    begin
      Files := TJSONArray(Root.Items[I]);
      SetLength(Result.Entries, Files.Count);
      for I := 0 to Files.Count - 1 do
      begin
        if not (Files[I] is TJSONObject) then
        begin
          FreeAndNil(Result);
          Exit;
        end;
        Entry := ManifestEntryFromJSON(TJSONObject(Files[I]));
        if (Entry.Path = '') or (Length(Entry.SHA256) <> 64) or
          (Entry.Size < 0) or not IsSafeManifestPath(Entry.Path) then
        begin
          FreeAndNil(Result);
          Exit;
        end;
        Result.Entries[I] := Entry;
      end;
    end;
  finally
    Data.Free;
  end;
end;

function ManifestOutputsPresent(AManifest: TManifest;
  const AOutputDirectory: string): Boolean;
var
  I: Integer;
  FullPath: string;
begin
  Result := False;
  if not Assigned(AManifest) then
    Exit;
  for I := 0 to Length(AManifest.Entries) - 1 do
  begin
    FullPath := ResolveOutputPath(AOutputDirectory,
      AManifest.Entries[I].Path);
    if FullPath = '' then
      Exit;
    if not FileExists(FullPath) then
      Exit;
    if FileSizeOf(FullPath) <> AManifest.Entries[I].Size then
      Exit;
  end;
  Result := True;
end;

function ManifestToJSON(AManifest: TManifest): UTF8String;
var
  Root: TJSONObject;
  Outputs: TJSONArray;
  Item: TJSONObject;
  I: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('schemaVersion', ManifestSchemaVersion);
    Root.Add('pasweaveVersion', AManifest.PasWeaveVersion);
    Root.Add('inputFingerprint', AManifest.InputFingerprint);
    Root.Add('unitCount', AManifest.UnitCount);
    Root.Add('symbolCount', AManifest.SymbolCount);
    Root.Add('attemptedCount', AManifest.AttemptedCount);
    Root.Add('warningCount', AManifest.WarningCount);
    Root.Add('errorCount', AManifest.ErrorCount);
    Outputs := TJSONArray.Create;
    for I := 0 to Length(AManifest.Entries) - 1 do
    begin
      Item := TJSONObject.Create;
      Item.Add('path', AManifest.Entries[I].Path);
      Item.Add('sha256', AManifest.Entries[I].SHA256);
      Item.Add('size', AManifest.Entries[I].Size);
      Outputs.Add(Item);
    end;
    Root.Add('outputs', Outputs);
    Result := Root.FormatJSON([], 2);
    Result := UTF8String(StringReplace(string(Result), #13#10, #10,
      [rfReplaceAll]));
    if (Result = '') or (Result[Length(Result)] <> #10) then
      Result := Result + #10;
  finally
    Root.Free;
  end;
end;

procedure WriteManifest(const AOutputDirectory: string; AManifest: TManifest);
begin
  WriteFileAtomic(ManifestFilePath(AOutputDirectory),
    ManifestToJSON(AManifest));
end;

{ Replaces the destination in one step. Deleting the destination before
  renaming is not atomic: if the rename fails (or the process dies) between the
  two calls, the previous output is lost. MoveFileEx replaces the existing file
  directly, so readers observe either the old or the new content. }
procedure CommitTempFile(const ATemp, ADestination: string);
begin
  {$IFDEF MSWINDOWS}
  if MoveFileExA(PAnsiChar(ATemp), PAnsiChar(ADestination),
    MoveFileReplaceExisting) then
    Exit;
  {$ELSE}
  if RenameFile(ATemp, ADestination) then
    Exit;
  {$ENDIF}
  raise EFCreateError.CreateFmt('cannot finalize output file: %s',
    [ADestination]);
end;

procedure DiscardTempFile(const ATemp: string);
begin
  if FileExists(ATemp) then
    DeleteFile(ATemp);
end;

procedure WriteFileAtomic(const AFilename: string; const AData: UTF8String);
var
  Temp: string;
  Stream: TFileStream;
  ParentDirectory: string;
begin
  ParentDirectory := ExtractFileDir(AFilename);
  if (ParentDirectory <> '') and not ForceDirectories(ParentDirectory) then
    raise EFCreateError.CreateFmt('cannot create output directory: %s',
      [ParentDirectory]);
  Temp := AFilename + TempFileSuffix;
  try
    Stream := TFileStream.Create(Temp, fmCreate);
    try
      if Length(AData) > 0 then
        Stream.WriteBuffer(AData[1], Length(AData));
    finally
      Stream.Free;
    end;
    CommitTempFile(Temp, AFilename);
  except
    DiscardTempFile(Temp);
    raise;
  end;
end;

procedure WriteFileAtomicCopy(const ASource, ADestination: string);
var
  Temp: string;
  SourceStream: TFileStream;
  DestinationStream: TFileStream;
  ParentDirectory: string;
begin
  ParentDirectory := ExtractFileDir(ADestination);
  if (ParentDirectory <> '') and not ForceDirectories(ParentDirectory) then
    raise EFCreateError.CreateFmt('cannot create output directory: %s',
      [ParentDirectory]);
  Temp := ADestination + TempFileSuffix;
  try
    SourceStream := TFileStream.Create(ASource, fmOpenRead or fmShareDenyWrite);
    try
      DestinationStream := TFileStream.Create(Temp, fmCreate);
      try
        DestinationStream.CopyFrom(SourceStream, 0);
      finally
        DestinationStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
    CommitTempFile(Temp, ADestination);
  except
    DiscardTempFile(Temp);
    raise;
  end;
end;

procedure BeginOutputLedger;
begin
  if not Assigned(GLedger) then
    GLedger := TStringList.Create
  else
    GLedger.Clear;
end;

function WriteOutputFile(const AFilename: string;
  const AData: UTF8String): string;
begin
  WriteFileAtomic(AFilename, AData);
  Result := SHA256HexString(AData);
  if Assigned(GLedger) then
    GLedger.Add(NormalisePath(ExpandFileName(AFilename)) + #1 + Result + #1 +
      IntToStr(Length(AData)));
end;

function WriteOutputCopy(const ASource, ADestination: string): string;
begin
  WriteFileAtomicCopy(ASource, ADestination);
  Result := SHA256HexFile(ASource);
  if Assigned(GLedger) then
    GLedger.Add(NormalisePath(ExpandFileName(ADestination)) + #1 + Result +
      #1 + IntToStr(FileSizeOf(ADestination)));
end;

function LedgerRelativePath(const ARoot, AItem: string): string;
var
  Separator: Integer;
  FullPath: string;
begin
  Separator := Pos(#1, AItem);
  if Separator <= 1 then
    Exit('');
  FullPath := Copy(AItem, 1, Separator - 1);
  if Pos(ARoot, FullPath) = 1 then
    Result := Copy(FullPath, Length(ARoot) + 1, MaxInt)
  else
    Result := '';
end;

function OutputRootPrefix(const AOutputDirectory: string): string;
begin
  Result := NormalisePath(ExpandFileName(AOutputDirectory));
  if (Result <> '') and (Result[Length(Result)] <> '/') then
    Result := Result + '/';
end;

function LedgerEntries(const AOutputDirectory: string): TStringList;
var
  Root: string;
  I: Integer;
  Relative: string;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupIgnore;
  if not Assigned(GLedger) then
    Exit;
  Root := OutputRootPrefix(AOutputDirectory);
  for I := 0 to GLedger.Count - 1 do
  begin
    Relative := LedgerRelativePath(Root, GLedger[I]);
    if Relative <> '' then
      Result.Add(Relative + #1 + Copy(GLedger[I],
        Pos(#1, GLedger[I]) + 1, MaxInt));
  end;
end;

function LedgerPaths(const AOutputDirectory: string): TStringList;
var
  Entries: TStringList;
  I: Integer;
  Separator: Integer;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupIgnore;
  Entries := LedgerEntries(AOutputDirectory);
  try
    for I := 0 to Entries.Count - 1 do
    begin
      Separator := Pos(#1, Entries[I]);
      if Separator <= 1 then
        Continue;
      Result.Add(Copy(Entries[I], 1, Separator - 1));
    end;
  finally
    Entries.Free;
  end;
end;

procedure RemoveStaleOutputs(const AOutputDirectory: string;
  AOldManifest: TManifest; const ANewPaths: TStrings);
var
  I: Integer;
  FullPath: string;
begin
  if not Assigned(AOldManifest) then
    Exit;
  for I := 0 to Length(AOldManifest.Entries) - 1 do
  begin
    if Assigned(ANewPaths) and
      (ANewPaths.IndexOf(AOldManifest.Entries[I].Path) >= 0) then
      Continue;
    FullPath := ResolveOutputPath(AOutputDirectory,
      AOldManifest.Entries[I].Path);
    if (FullPath = '') or not FileExists(FullPath) then
      Continue;
    DeleteFile(FullPath);
  end;
end;

initialization

finalization
  GLedger.Free;

end.
