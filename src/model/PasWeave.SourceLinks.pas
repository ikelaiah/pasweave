unit PasWeave.SourceLinks;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Model;

function TryConfigureSourceLinks(AProject: TDocProject;
  const ARepositoryURL, ASourceLinkTemplate: string;
  out AErrorMessage: string): Boolean;
function SourceLinkURL(AProject: TDocProject; const ASourceFilename: string;
  ASourceLine: Integer): string;

implementation

uses
  Classes, SysUtils;

function CountValue(const AText, AValue: string): Integer;
var
  Offset: Integer;
  MatchPosition: Integer;
begin
  Result := 0;
  Offset := 1;
  repeat
    MatchPosition := Pos(AValue, Copy(AText, Offset, MaxInt));
    if MatchPosition > 0 then
    begin
      Inc(Result);
      Inc(Offset, MatchPosition + Length(AValue) - 1);
    end;
  until MatchPosition = 0;
end;

function HasUnsafeCharacters(const AValue: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(AValue) do
    if (Ord(AValue[I]) <= 32) or (AValue[I] = '\') then
      Exit(True);
  Result := False;
end;

function HasControlCharacters(const AValue: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(AValue) do
    if Ord(AValue[I]) < 32 then
      Exit(True);
  Result := False;
end;

function HasUnsafePathSegments(const APath: string): Boolean;
var
  I: Integer;
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    ExtractStrings(['/'], [], PChar(APath), Parts);
    Result := Parts.Count = 0;
    for I := 0 to Parts.Count - 1 do
      if (Parts[I] = '.') or (Parts[I] = '..') then
        Exit(True);
  finally
    Parts.Free;
  end;
end;

function HexDigitValue(ACharacter: Char): Integer;
begin
  if ACharacter in ['0'..'9'] then
    Result := Ord(ACharacter) - Ord('0')
  else if ACharacter in ['A'..'F'] then
    Result := Ord(ACharacter) - Ord('A') + 10
  else if ACharacter in ['a'..'f'] then
    Result := Ord(ACharacter) - Ord('a') + 10
  else
    Result := -1;
end;

function HasUnsafePercentEncoding(const APath: string): Boolean;
var
  Decoded: Integer;
  HighDigit: Integer;
  I: Integer;
  LowDigit: Integer;
begin
  I := 1;
  while I <= Length(APath) do
  begin
    if APath[I] <> '%' then
    begin
      Inc(I);
      Continue;
    end;
    if I + 2 > Length(APath) then
      Exit(True);
    HighDigit := HexDigitValue(APath[I + 1]);
    LowDigit := HexDigitValue(APath[I + 2]);
    if (HighDigit < 0) or (LowDigit < 0) then
      Exit(True);
    Decoded := HighDigit * 16 + LowDigit;
    if (Decoded <= 32) or (Decoded = Ord('.')) or
      (Decoded = Ord('/')) or (Decoded = Ord('\')) or
      (Decoded = Ord('%')) then
      Exit(True);
    Inc(I, 3);
  end;
  Result := False;
end;

function ValidateRepositoryURL(const AValue: string;
  out ANormalized, AErrorMessage: string): Boolean;
var
  HostPart: string;
  PathPart: string;
  PathPosition: Integer;
  SchemeLength: Integer;
  Remainder: string;
begin
  Result := False;
  ANormalized := AValue;
  if HasUnsafeCharacters(ANormalized) then
  begin
    AErrorMessage := 'repository URL must not contain whitespace or backslashes';
    Exit;
  end;
  if (Pos('?', ANormalized) > 0) or (Pos('#', ANormalized) > 0) then
  begin
    AErrorMessage := 'repository URL must not contain a query or fragment';
    Exit;
  end;
  if Pos('https://', LowerCase(ANormalized)) = 1 then
    SchemeLength := Length('https://')
  else if Pos('http://', LowerCase(ANormalized)) = 1 then
    SchemeLength := Length('http://')
  else
  begin
    AErrorMessage := 'repository URL must use http or https';
    Exit;
  end;
  Remainder := Copy(ANormalized, SchemeLength + 1, MaxInt);
  if (Remainder = '') or (Remainder[1] = '/') then
  begin
    AErrorMessage := 'repository URL must include a host';
    Exit;
  end;
  PathPosition := Pos('/', Remainder);
  if PathPosition > 0 then
  begin
    HostPart := Copy(Remainder, 1, PathPosition - 1);
    PathPart := Copy(Remainder, PathPosition + 1, MaxInt);
  end
  else
  begin
    HostPart := Remainder;
    PathPart := '';
  end;
  if (HostPart = '') or (Pos('@', HostPart) > 0) or
    (Pos('%', HostPart) > 0) then
  begin
    AErrorMessage := 'repository URL must include a plain host without credentials';
    Exit;
  end;
  if (PathPart <> '') and (HasUnsafePathSegments(PathPart) or
    HasUnsafePercentEncoding(PathPart)) then
  begin
    AErrorMessage := 'repository URL must not contain encoded or literal path traversal';
    Exit;
  end;
  if (Pos('{', ANormalized) > 0) or (Pos('}', ANormalized) > 0) then
  begin
    AErrorMessage := 'repository URL must not contain placeholders';
    Exit;
  end;
  while (Length(ANormalized) > SchemeLength) and
    (ANormalized[Length(ANormalized)] = '/') do
    Delete(ANormalized, Length(ANormalized), 1);
  Result := True;
end;

function ValidateTemplate(const AValue: string;
  out AErrorMessage: string): Boolean;
var
  PlaceholderFree: string;
  FragmentPosition: Integer;
  PathPart: string;
begin
  Result := False;
  if (AValue = '') or (Trim(AValue) <> AValue) or
    HasUnsafeCharacters(AValue) then
  begin
    AErrorMessage := 'source-link template must be a non-empty relative URL';
    Exit;
  end;
  if (AValue[1] = '/') or (Pos('://', AValue) > 0) then
  begin
    AErrorMessage := 'source-link template must be relative to the repository URL';
    Exit;
  end;
  if Pos('?', AValue) > 0 then
  begin
    AErrorMessage := 'source-link template must not contain a query';
    Exit;
  end;
  if (CountValue(AValue, '{path}') <> 1) or
    (CountValue(AValue, '{line}') <> 1) then
  begin
    AErrorMessage := 'source-link template must contain one {path} and one {line} placeholder';
    Exit;
  end;
  PlaceholderFree := StringReplace(AValue, '{path}', '', []);
  PlaceholderFree := StringReplace(PlaceholderFree, '{line}', '', []);
  if (Pos('{', PlaceholderFree) > 0) or (Pos('}', PlaceholderFree) > 0) then
  begin
    AErrorMessage := 'source-link template contains an unknown placeholder';
    Exit;
  end;
  FragmentPosition := Pos('#', AValue);
  if (FragmentPosition = 0) or
    (FragmentPosition > Pos('{line}', AValue)) or
    (CountValue(AValue, '#') <> 1) then
  begin
    AErrorMessage := 'source-link template must place {line} in one URL fragment';
    Exit;
  end;
  if Pos('{path}', AValue) > FragmentPosition then
  begin
    AErrorMessage := 'source-link template must place {path} before its fragment';
    Exit;
  end;
  PathPart := Copy(AValue, 1, FragmentPosition - 1);
  if HasUnsafePathSegments(PathPart) or HasUnsafePercentEncoding(PathPart) then
  begin
    AErrorMessage := 'source-link template must not contain encoded or literal path traversal';
    Exit;
  end;
  Result := True;
end;

function TryConfigureSourceLinks(AProject: TDocProject;
  const ARepositoryURL, ASourceLinkTemplate: string;
  out AErrorMessage: string): Boolean;
var
  NormalizedRepositoryURL: string;
begin
  AErrorMessage := '';
  if (ARepositoryURL = '') and (ASourceLinkTemplate = '') then
  begin
    AProject.RepositoryURL := '';
    AProject.SourceLinkTemplate := '';
    Exit(True);
  end;
  if ARepositoryURL = '' then
  begin
    AErrorMessage := 'source-link template requires --repository-url';
    Exit(False);
  end;
  if ASourceLinkTemplate = '' then
  begin
    AErrorMessage := 'repository URL requires --source-link-template';
    Exit(False);
  end;
  if not ValidateRepositoryURL(ARepositoryURL, NormalizedRepositoryURL,
    AErrorMessage) then
    Exit(False);
  if not ValidateTemplate(ASourceLinkTemplate, AErrorMessage) then
    Exit(False);
  AProject.RepositoryURL := NormalizedRepositoryURL;
  AProject.SourceLinkTemplate := ASourceLinkTemplate;
  Result := True;
end;

function IsUnreserved(ACharacter: Char): Boolean;
begin
  Result := (ACharacter in ['A'..'Z', 'a'..'z', '0'..'9', '-', '.', '_', '~']);
end;

function EncodeSourcePath(const ASourceFilename: string): string;
var
  EncodedInput: UTF8String;
  I: Integer;
  Normalized: string;
begin
  Result := '';
  Normalized := StringReplace(ASourceFilename, '\', '/', [rfReplaceAll]);
  if (Normalized = '') or (Normalized[1] = '/') or
    (Pos(':', Normalized) > 0) or (Pos('?', Normalized) > 0) or
    (Pos('#', Normalized) > 0) or HasControlCharacters(Normalized) or
    HasUnsafePathSegments(Normalized) then
    Exit;
  EncodedInput := UTF8Encode(UnicodeString(Normalized));
  for I := 1 to Length(EncodedInput) do
    if IsUnreserved(EncodedInput[I]) or (EncodedInput[I] = '/') then
      Result := Result + EncodedInput[I]
    else
      Result := Result + '%' + IntToHex(Ord(EncodedInput[I]), 2);
end;

function SourceLinkURL(AProject: TDocProject; const ASourceFilename: string;
  ASourceLine: Integer): string;
var
  EncodedPath: string;
  ExpandedTemplate: string;
begin
  Result := '';
  if not Assigned(AProject) or (AProject.RepositoryURL = '') or
    (AProject.SourceLinkTemplate = '') or (ASourceLine < 1) then
    Exit;
  EncodedPath := EncodeSourcePath(ASourceFilename);
  if EncodedPath = '' then
    Exit;
  ExpandedTemplate := StringReplace(AProject.SourceLinkTemplate, '{path}',
    EncodedPath, []);
  ExpandedTemplate := StringReplace(ExpandedTemplate, '{line}',
    IntToStr(ASourceLine), []);
  Result := AProject.RepositoryURL + '/' + ExpandedTemplate;
  if Pos(AProject.RepositoryURL + '/', Result) <> 1 then
    Result := '';
end;

end.
