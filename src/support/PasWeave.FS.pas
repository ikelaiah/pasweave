/// Shared filesystem helpers for source discovery and incremental builds.
///
/// This is a leaf unit: it depends only on the RTL so parsers, discovery, and
/// output code can share one definition of path and file handling.
unit PasWeave.FS;

{$mode objfpc}{$H+}{$J+}

interface

uses
  Classes;

/// Converts Windows separators to `/` for stable comparisons.
function NormalisePath(const APath: string): string;
/// Reads a whole file as a byte string, preserving its encoding.
function ReadFileToString(const AFilename: string): string;
/// True for `.pas` and `.pp` source files.
function IsPascalSourceFile(const AFilename: string): Boolean;
/// True for every extension that can contribute to a build fingerprint
/// (`.pas`, `.pp`, `.inc`, `.lpi`, `.lpk`).
function HasBuildInputExtension(const AFilename: string): Boolean;
/// True when the directory can be opened for listing.
function DirectoryIsReadable(const APath: string): Boolean;
/// True when search attributes mark a symbolic link.
function IsSymbolicLink(AAttributes: LongInt): Boolean;

implementation

uses
  SysUtils;

function NormalisePath(const APath: string): string;
begin
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

function ReadFileToString(const AFilename: string): string;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, Stream.Size);
    if Stream.Size > 0 then
      Stream.ReadBuffer(Result[1], Stream.Size);
  finally
    Stream.Free;
  end;
end;

function IsPascalSourceFile(const AFilename: string): Boolean;
begin
  Result := SameText(ExtractFileExt(AFilename), '.pas') or
    SameText(ExtractFileExt(AFilename), '.pp');
end;

function HasBuildInputExtension(const AFilename: string): Boolean;
var
  Extension: string;
begin
  Extension := LowerCase(ExtractFileExt(AFilename));
  Result := (Extension = '.pas') or (Extension = '.pp') or
    (Extension = '.inc') or (Extension = '.lpi') or (Extension = '.lpk');
end;

function DirectoryIsReadable(const APath: string): Boolean;
var
  Search: TSearchRec;
begin
  Result := FindFirst(IncludeTrailingPathDelimiter(APath) + '*',
    faAnyFile, Search) = 0;
  if Result then
    FindClose(Search);
end;

function IsSymbolicLink(AAttributes: LongInt): Boolean;
begin
  {$IFDEF UNIX}
  Result := (AAttributes and faSymLink) <> 0;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

end.
