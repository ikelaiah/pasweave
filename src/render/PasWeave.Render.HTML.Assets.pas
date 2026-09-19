unit PasWeave.Render.HTML.Assets;

{$mode objfpc}{$H+}{$J+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

const
  KaTeXVersion = '0.18.1';
  MermaidVersion = '11.16.0';

function HTMLStylesheet(AProject: TDocProject): UTF8String;
function HTMLThemeBootstrap: UTF8String;
function HTMLApplicationScript: UTF8String;
function HTMLMathScript: UTF8String;
function HTMLDiagramScript: UTF8String;
function FindKaTeXAssetsDirectory: string;
function FindMermaidAssetsDirectory: string;
function ThirdPartyAssetFingerprint: string;
procedure WriteThirdPartyAssets(const AAssetsDirectory: string);
procedure WriteKaTeXAssets(const AAssetsDirectory: string);
procedure WriteMermaidAssets(const AAssetsDirectory: string);

implementation

uses
  Classes, SysUtils, StrUtils, PasWeave.Render.Support,
  PasWeave.Output, PasWeave.Hashing,
  PasWeave.Render.HTML.CSS, PasWeave.Render.HTML.Scripts
  {$IFDEF PASWEAVE_PORTABLE_ASSETS}
  {$IFDEF MSWINDOWS}
  , Zipper
  {$ELSE}
  {$ERROR Portable asset embedding currently requires Windows}
  {$ENDIF}
  {$ENDIF};


{ The stylesheet and script payloads live in dedicated units. }
function HTMLStylesheet(AProject: TDocProject): UTF8String;
begin
  Result := PasWeave.Render.HTML.CSS.HTMLStylesheet(AProject);
end;

function HTMLThemeBootstrap: UTF8String;
begin
  Result := PasWeave.Render.HTML.Scripts.HTMLThemeBootstrap;
end;

function HTMLApplicationScript: UTF8String;
begin
  Result := PasWeave.Render.HTML.Scripts.HTMLApplicationScript;
end;

function HTMLMathScript: UTF8String;
begin
  Result := PasWeave.Render.HTML.Scripts.HTMLMathScript;
end;

function HTMLDiagramScript: UTF8String;
begin
  Result := PasWeave.Render.HTML.Scripts.HTMLDiagramScript;
end;

function HasAllKaTeXFontAssets(const ADirectory: string): Boolean;
var
  CSS: TStringList;
  CSSContent: string;
  CloseAt: Integer;
  FontCount: Integer;
  FontFilename: string;
  OpenAt: Integer;
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(ADirectory);
  CSS := TStringList.Create;
  try
    CSS.LoadFromFile(Root + 'katex.min.css');
    CSSContent := CSS.Text;
  finally
    CSS.Free;
  end;

  FontCount := 0;
  OpenAt := PosEx('url(fonts/', CSSContent, 1);
  while OpenAt > 0 do
  begin
    Inc(OpenAt, Length('url(fonts/'));
    CloseAt := PosEx(')', CSSContent, OpenAt);
    if CloseAt = 0 then
      Exit(False);
    FontFilename := Copy(CSSContent, OpenAt, CloseAt - OpenAt);
    if (FontFilename = '') or not FileExists(Root + 'fonts' + PathDelim +
      FontFilename) then
      Exit(False);
    Inc(FontCount);
    OpenAt := PosEx('url(fonts/', CSSContent, CloseAt + 1);
  end;
  Result := FontCount > 0;
end;

function IsKaTeXAssetsDirectory(const ADirectory: string): Boolean;
var
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(ADirectory);
  Result := FileExists(Root + 'katex.min.js') and
    FileExists(Root + 'katex.min.css') and FileExists(Root + 'LICENSE');
  if Result then
    Result := HasAllKaTeXFontAssets(ADirectory);
end;

function FindKaTeXAssetsDirectory: string;
var
  Candidates: TStringList;
  ExecutableDirectory: string;
  EnvironmentDirectory: string;
  I: Integer;
begin
  Result := '';
  Candidates := TStringList.Create;
  try
    EnvironmentDirectory := GetEnvironmentVariable('PASWEAVE_KATEX_ASSETS');
    if EnvironmentDirectory <> '' then
      Candidates.Add(ExpandFileName(EnvironmentDirectory));

    ExecutableDirectory := ExtractFileDir(ExpandFileName(ParamStr(0)));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim +
      'assets' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'assets' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'share' + PathDelim + 'pasweave' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + '..' + PathDelim + 'assets' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(GetCurrentDir + PathDelim + 'assets' +
      PathDelim + 'katex'));

    for I := 0 to Candidates.Count - 1 do
      if IsKaTeXAssetsDirectory(Candidates[I]) then
        Exit(Candidates[I]);
  finally
    Candidates.Free;
  end;
  raise Exception.Create('cannot locate KaTeX ' + KaTeXVersion +
    ' assets; set PASWEAVE_KATEX_ASSETS or install assets/katex beside PasWeave');
end;

function IsMermaidAssetsDirectory(const ADirectory: string): Boolean;
var
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(ADirectory);
  Result := FileExists(Root + 'mermaid.tiny.js') and
    FileExists(Root + 'LICENSE');
end;

function FindMermaidAssetsDirectory: string;
var
  Candidates: TStringList;
  ExecutableDirectory: string;
  EnvironmentDirectory: string;
  I: Integer;
begin
  Result := '';
  Candidates := TStringList.Create;
  try
    EnvironmentDirectory := GetEnvironmentVariable(
      'PASWEAVE_MERMAID_ASSETS');
    if EnvironmentDirectory <> '' then
      Candidates.Add(ExpandFileName(EnvironmentDirectory));

    ExecutableDirectory := ExtractFileDir(ExpandFileName(ParamStr(0)));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim +
      'assets' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'assets' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'share' + PathDelim + 'pasweave' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + '..' + PathDelim + 'assets' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(GetCurrentDir + PathDelim + 'assets' +
      PathDelim + 'mermaid'));

    for I := 0 to Candidates.Count - 1 do
      if IsMermaidAssetsDirectory(Candidates[I]) then
        Exit(Candidates[I]);
  finally
    Candidates.Free;
  end;
  raise Exception.Create('cannot locate Mermaid ' + MermaidVersion +
    ' assets; set PASWEAVE_MERMAID_ASSETS or install assets/mermaid beside ' +
    'PasWeave');
end;

procedure CollectTreeFiles(const ADirectory, ARelative: string;
  AFiles: TStringList);
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
        CollectTreeFiles(IncludeTrailingPathDelimiter(ADirectory) + Search.Name,
          Relative, AFiles)
      else
        AFiles.Add(Relative);
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function SHA256HexDirectory(const ADirectory: string): string;
var
  Files: TStringList;
  I: Integer;
  Text: string;
  Full: string;
begin
  Files := TStringList.Create;
  try
    Files.Sorted := True;
    Files.CaseSensitive := True;
    CollectTreeFiles(ADirectory, '', Files);
    Text := '';
    for I := 0 to Files.Count - 1 do
    begin
      Full := IncludeTrailingPathDelimiter(ADirectory) +
        StringReplace(Files[I], '/', PathDelim, [rfReplaceAll]);
      Text := Text + Files[I] + #9 + SHA256HexFile(Full) + #10;
    end;
    Result := SHA256HexString(Text);
  finally
    Files.Free;
  end;
end;

function ThirdPartyAssetFingerprint: string;
begin
  {$IFDEF PASWEAVE_PORTABLE_ASSETS}
  Result := SHA256HexString('katex=' + KaTeXVersion + #10 + 'mermaid=' +
    MermaidVersion);
  {$ELSE}
  Result := SHA256HexString('katex=' + KaTeXVersion + #10 +
    SHA256HexDirectory(FindKaTeXAssetsDirectory) + #10 +
    'mermaid=' + MermaidVersion + #10 +
    SHA256HexDirectory(FindMermaidAssetsDirectory));
  {$ENDIF}
end;

procedure CopyFontFiles(const ASourceDirectory, ADestinationDirectory: string);
var
  Search: TSearchRec;
  Filenames: TStringList;
  I: Integer;
begin
  if not ForceDirectories(ADestinationDirectory) then
    raise EFCreateError.CreateFmt('cannot create KaTeX font directory: %s',
      [ADestinationDirectory]);
  Filenames := TStringList.Create;
  try
    Filenames.Sorted := True;
    if FindFirst(IncludeTrailingPathDelimiter(ASourceDirectory) + '*',
      faAnyFile, Search) = 0 then
    try
      repeat
        if (Search.Attr and faDirectory) = 0 then
          Filenames.Add(Search.Name);
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
    for I := 0 to Filenames.Count - 1 do
      WriteOutputCopy(IncludeTrailingPathDelimiter(ASourceDirectory) +
        Filenames[I], IncludeTrailingPathDelimiter(ADestinationDirectory) +
        Filenames[I]);
  finally
    Filenames.Free;
  end;
end;

procedure WriteKaTeXAssets(const AAssetsDirectory: string);
var
  SourceDirectory: string;
  DestinationDirectory: string;
begin
  SourceDirectory := FindKaTeXAssetsDirectory;
  DestinationDirectory := IncludeTrailingPathDelimiter(AAssetsDirectory) +
    'katex';
  if not ForceDirectories(DestinationDirectory) then
    raise EFCreateError.CreateFmt('cannot create KaTeX asset directory: %s',
      [DestinationDirectory]);
  WriteOutputCopy(IncludeTrailingPathDelimiter(SourceDirectory) + 'katex.min.js',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'katex.min.js');
  WriteOutputCopy(IncludeTrailingPathDelimiter(SourceDirectory) + 'katex.min.css',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'katex.min.css');
  WriteOutputCopy(IncludeTrailingPathDelimiter(SourceDirectory) + 'LICENSE',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'LICENSE');
  CopyFontFiles(IncludeTrailingPathDelimiter(SourceDirectory) + 'fonts',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'fonts');
end;

procedure WriteMermaidAssets(const AAssetsDirectory: string);
var
  SourceDirectory: string;
  DestinationDirectory: string;
begin
  SourceDirectory := FindMermaidAssetsDirectory;
  DestinationDirectory := IncludeTrailingPathDelimiter(AAssetsDirectory) +
    'mermaid';
  if not ForceDirectories(DestinationDirectory) then
    raise EFCreateError.CreateFmt('cannot create Mermaid asset directory: %s',
      [DestinationDirectory]);
  WriteOutputCopy(IncludeTrailingPathDelimiter(SourceDirectory) +
    'mermaid.tiny.js', IncludeTrailingPathDelimiter(DestinationDirectory) +
    'mermaid.tiny.js');
  WriteOutputCopy(IncludeTrailingPathDelimiter(SourceDirectory) + 'LICENSE',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'LICENSE');
end;

{$IFDEF PASWEAVE_PORTABLE_ASSETS}
type
  TEmbeddedAssetExtractor = class
  private
    procedure CloseInputStream(Sender: TObject; var AStream: TStream);
    procedure OpenInputStream(Sender: TObject; var AStream: TStream);
  public
    procedure ExtractTo(const AAssetsDirectory: string);
  end;

const
  WindowsRCDATAResourceType = 10;

procedure TEmbeddedAssetExtractor.OpenInputStream(Sender: TObject;
  var AStream: TStream);
begin
  AStream := TResourceStream.Create(HInstance, 'PASWEAVE_ASSETS',
    PChar(PtrUInt(WindowsRCDATAResourceType)));
end;

procedure TEmbeddedAssetExtractor.CloseInputStream(Sender: TObject;
  var AStream: TStream);
begin
  FreeAndNil(AStream);
end;

procedure TEmbeddedAssetExtractor.ExtractTo(const AAssetsDirectory: string);
var
  UnZipper: TUnZipper;
begin
  if not ForceDirectories(AAssetsDirectory) then
    raise EFCreateError.CreateFmt('cannot create HTML asset directory: %s',
      [AAssetsDirectory]);
  UnZipper := TUnZipper.Create;
  try
    UnZipper.OutputPath := AAssetsDirectory;
    UnZipper.UseUTF8 := True;
    UnZipper.OnOpenInputStream := @OpenInputStream;
    UnZipper.OnCloseInputStream := @CloseInputStream;
    UnZipper.UnZipAllFiles;
  finally
    UnZipper.Free;
  end;

  if not IsKaTeXAssetsDirectory(IncludeTrailingPathDelimiter(
    AAssetsDirectory) + 'katex') then
    raise Exception.Create('embedded KaTeX assets are incomplete');
  if not IsMermaidAssetsDirectory(IncludeTrailingPathDelimiter(
    AAssetsDirectory) + 'mermaid') then
    raise Exception.Create('embedded Mermaid assets are incomplete');
end;
{$ENDIF}

procedure WriteThirdPartyAssets(const AAssetsDirectory: string);
{$IFDEF PASWEAVE_PORTABLE_ASSETS}
var
  Extractor: TEmbeddedAssetExtractor;
{$ENDIF}
begin
  {$IFDEF PASWEAVE_PORTABLE_ASSETS}
  Extractor := TEmbeddedAssetExtractor.Create;
  try
    Extractor.ExtractTo(AAssetsDirectory);
  finally
    Extractor.Free;
  end;
  {$ELSE}
  WriteKaTeXAssets(AAssetsDirectory);
  WriteMermaidAssets(AAssetsDirectory);
  {$ENDIF}
end;

end.
