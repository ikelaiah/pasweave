/// Computes the build input fingerprint and enumerates reached inputs.
///
/// The generated output tree is owned by PasWeave.Output.
unit PasWeave.Incremental;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PasWeave.Compiler, PasWeave.Parser;

/// Hashes version, config, assets, and every input file into one fingerprint.
///
/// @param AConfigText Normalized build-affecting options.
/// @param AInputFiles Reached source, include, project, and package files.
/// @param AAssetFingerprint Fingerprint of vendored web assets.
/// @returns Hex SHA-256 fingerprint.
function ComputeBuildFingerprint(const AConfigText: string;
  const AInputFiles: TStrings; const AAssetFingerprint: string): string;
/// Lists every input file affecting the build, sorted and deduplicated.
///
/// @param ASourcePath CLI source input.
/// @param AIsLazarusInput True for `.lpi`/`.lpk` inputs.
/// @param ADiscovery Source discovery options.
/// @param ACompiler Compiler search paths and defines.
/// @param ALazarusSourceFiles Source files imported from Lazarus.
/// @param ALazarusPackageFiles Package files imported from Lazarus.
/// @returns Owned list; caller frees it.
function EnumerateInputFiles(const ASourcePath: string; AIsLazarusInput: Boolean;
  ADiscovery: TSourceDiscoveryOptions; ACompiler: TCompilerOptions;
  const ALazarusSourceFiles, ALazarusPackageFiles: TStrings): TStringList;

/// Returns monotonic milliseconds for `--verbose` timing.
///
/// @returns Milliseconds since an arbitrary origin.
function MonotonicMilliseconds: QWord;
/// Resets the peak-heap tracker.
procedure ResetPeakHeap;
/// Samples current heap usage into the peak tracker.
procedure SamplePeakHeap;
/// Returns the peak heap bytes observed since the last reset.
///
/// @returns Peak bytes.
function PeakHeapBytes: QWord;
implementation

uses
  PasWeave.FS, PasWeave.Hashing, PasWeave.Version;

var
  GPeakHeap: QWord;



procedure CollectDirectoryPascalFiles(const ARootDirectory,
  ARelativeDirectory: string; ARecursive: Boolean;
  ADiscovery: TSourceDiscoveryOptions; AFiles: TStrings);
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
        if ARecursive and not IsSymbolicLink(Search.Attr) and
          (not Assigned(ADiscovery) or
           not ADiscovery.IsExcluded(RelativePath)) then
          CollectDirectoryPascalFiles(ARootDirectory, RelativePath, ARecursive,
            ADiscovery, AFiles);
      end
      else if HasBuildInputExtension(Search.Name) then
      begin
        if Assigned(ADiscovery) and
          (ADiscovery.IsExcluded(RelativePath) or
           not ADiscovery.IsIncluded(RelativePath)) then
          Continue;
        AFiles.Add(NormalisePath(ExpandFileName(FullPath)));
      end;
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

procedure CollectDirectoryListingFiles(const ADirectory: string;
  AFiles: TStrings);
var
  Search: TSearchRec;
  FullPath: string;
begin
  if not DirectoryExists(ADirectory) then
    Exit;
  if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + '*', faAnyFile,
    Search) <> 0 then
    Exit;
  try
    repeat
      if (Search.Name = '.') or (Search.Name = '..') then
        Continue;
      FullPath := IncludeTrailingPathDelimiter(ADirectory) + Search.Name;
      if (Search.Attr and faDirectory) = 0 then
      begin
        if HasBuildInputExtension(Search.Name) then
          AFiles.Add(NormalisePath(ExpandFileName(FullPath)));
      end;
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function EnumerateInputFiles(const ASourcePath: string; AIsLazarusInput: Boolean;
  ADiscovery: TSourceDiscoveryOptions; ACompiler: TCompilerOptions;
  const ALazarusSourceFiles, ALazarusPackageFiles: TStrings): TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := False;
  Result.Duplicates := dupIgnore;

  if AIsLazarusInput then
  begin
    Result.Add(NormalisePath(ExpandFileName(ASourcePath)));
    if Assigned(ALazarusSourceFiles) then
      for I := 0 to ALazarusSourceFiles.Count - 1 do
        Result.Add(NormalisePath(ExpandFileName(ALazarusSourceFiles[I])));
    if Assigned(ALazarusPackageFiles) then
      for I := 0 to ALazarusPackageFiles.Count - 1 do
        Result.Add(NormalisePath(ExpandFileName(ALazarusPackageFiles[I])));
  end
  else if DirectoryExists(ASourcePath) then
  begin
    CollectDirectoryPascalFiles(ExpandFileName(ASourcePath), '',
      Assigned(ADiscovery) and ADiscovery.Recursive, ADiscovery, Result);
  end
  else
  begin
    Result.Add(NormalisePath(ExpandFileName(ASourcePath)));
    CollectDirectoryListingFiles(ExtractFileDir(ExpandFileName(ASourcePath)),
      Result);
  end;

  if Assigned(ACompiler) then
  begin
    for I := 0 to ACompiler.UnitPaths.Count - 1 do
      CollectDirectoryListingFiles(ACompiler.UnitPaths[I], Result);
    for I := 0 to ACompiler.IncludePaths.Count - 1 do
      CollectDirectoryListingFiles(ACompiler.IncludePaths[I], Result);
  end;
end;

function ComputeBuildFingerprint(const AConfigText: string;
  const AInputFiles: TStrings; const AAssetFingerprint: string): string;
var
  Canonical: string;
  I: Integer;
begin
  Canonical := 'pasweave-version' + #10 + PasWeaveVersion + #10 +
    'config' + #10 + AConfigText;
  if (Canonical = '') or (Canonical[Length(Canonical)] <> #10) then
    Canonical := Canonical + #10;
  Canonical := Canonical + 'assets' + #10 + AAssetFingerprint + #10 +
    'files' + #10;
  for I := 0 to AInputFiles.Count - 1 do
    Canonical := Canonical + AInputFiles[I] + #9 +
      SHA256HexFile(AInputFiles[I]) + #10;
  Result := SHA256HexString(Canonical);
end;
function MonotonicMilliseconds: QWord;
begin
  Result := GetTickCount64;
end;

procedure ResetPeakHeap;
begin
  GPeakHeap := 0;
end;

procedure SamplePeakHeap;
var
  Used: QWord;
begin
  Used := QWord(GetFPCHeapStatus.CurrHeapUsed);
  if Used > GPeakHeap then
    GPeakHeap := Used;
end;

function PeakHeapBytes: QWord;
begin
  Result := GPeakHeap;
end;

initialization
  GPeakHeap := 0;

end.
