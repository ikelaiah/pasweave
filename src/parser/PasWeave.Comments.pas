unit PasWeave.Comments;

{$mode objfpc}{$H+}

interface

uses
  Contnrs;

type
  TDocumentationCommentStyle = (dcsSlash, dcsBrace, dcsParen);
  TDocumentationCommentStyles = set of TDocumentationCommentStyle;

const
  DefaultDocumentationCommentStyles: TDocumentationCommentStyles =
    [dcsSlash];
  AllDocumentationCommentStyles: TDocumentationCommentStyles =
    [dcsSlash, dcsBrace, dcsParen];

function TryParseDocumentationCommentStyles(const AValue: string;
  out AStyles: TDocumentationCommentStyles): Boolean;
function DocumentationCommentStylesText(
  AStyles: TDocumentationCommentStyles): string;
procedure ParseDocumentationComment(const ASourceText: string;
  ADeclarationLine: Integer; AStyles: TDocumentationCommentStyles;
  out ARawDocumentation, AMarkdownDocumentation: string;
  ADirectives: TObjectList);

implementation

uses
  Classes, SysUtils, PasWeave.Model;

type
  TCommentFragment = class
  public
    RawText: string;
    Style: TDocumentationCommentStyle;
    constructor Create(const ARawText: string;
      AStyle: TDocumentationCommentStyle);
  end;

constructor TCommentFragment.Create(const ARawText: string;
  AStyle: TDocumentationCommentStyle);
begin
  inherited Create;
  RawText := ARawText;
  Style := AStyle;
end;

function TryParseDocumentationCommentStyles(const AValue: string;
  out AStyles: TDocumentationCommentStyles): Boolean;
var
  Parts: TStringList;
  I: Integer;
  Part: string;
  ParsedStyles: TDocumentationCommentStyles;
begin
  AStyles := [];
  ParsedStyles := [];
  Result := False;
  if Trim(AValue) = '' then
    Exit;

  Parts := TStringList.Create;
  try
    Parts.Delimiter := ',';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := AValue;
    for I := 0 to Parts.Count - 1 do
    begin
      Part := LowerCase(Trim(Parts[I]));
      if Part = 'all' then
        ParsedStyles := ParsedStyles + AllDocumentationCommentStyles
      else if Part = 'slash' then
        Include(ParsedStyles, dcsSlash)
      else if Part = 'brace' then
        Include(ParsedStyles, dcsBrace)
      else if Part = 'paren' then
        Include(ParsedStyles, dcsParen)
      else
        Exit;
    end;
    Result := ParsedStyles <> [];
    if Result then
      AStyles := ParsedStyles;
  finally
    Parts.Free;
  end;
end;

function DocumentationCommentStylesText(
  AStyles: TDocumentationCommentStyles): string;

  procedure AddStyle(const AName: string);
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + AName;
  end;

begin
  Result := '';
  if dcsSlash in AStyles then
    AddStyle('slash');
  if dcsBrace in AStyles then
    AddStyle('brace');
  if dcsParen in AStyles then
    AddStyle('paren');
end;

function IsRecognisedDirective(const AName: string): Boolean;
begin
  Result :=
    (AName = 'param') or
    (AName = 'returns') or
    (AName = 'raises') or
    (AName = 'deprecated') or
    (AName = 'see') or
    (AName = 'since');
end;

procedure AppendLine(var AText: string; const ALine: string);
begin
  if AText <> '' then
    AText := AText + #10;
  AText := AText + ALine;
end;

function SplitFirstWord(const AText: string;
  out AWord, ARemainder: string): Boolean;
var
  P: Integer;
begin
  AWord := '';
  ARemainder := '';
  P := 1;
  while (P <= Length(AText)) and not (AText[P] in [' ', #9]) do
    Inc(P);
  AWord := Copy(AText, 1, P - 1);
  while (P <= Length(AText)) and (AText[P] in [' ', #9]) do
    Inc(P);
  ARemainder := Copy(AText, P, MaxInt);
  Result := AWord <> '';
end;

function TryParseDirective(const ALine: string;
  out ADirective: TDocDirective): Boolean;
var
  DirectiveName: string;
  FirstWord: string;
  Remainder: string;
  Rest: string;
  P: Integer;
begin
  Result := False;
  ADirective := nil;
  if (ALine = '') or (ALine[1] <> '@') then
    Exit;

  P := 2;
  while (P <= Length(ALine)) and not (ALine[P] in [' ', #9]) do
    Inc(P);
  DirectiveName := LowerCase(Copy(ALine, 2, P - 2));
  if not IsRecognisedDirective(DirectiveName) then
    Exit;

  while (P <= Length(ALine)) and (ALine[P] in [' ', #9]) do
    Inc(P);
  Rest := Copy(ALine, P, MaxInt);

  if (DirectiveName = 'param') or (DirectiveName = 'raises') or
     (DirectiveName = 'see') or (DirectiveName = 'since') then
  begin
    SplitFirstWord(Rest, FirstWord, Remainder);
    ADirective := TDocDirective.Create(DirectiveName, FirstWord, Remainder);
  end
  else
    ADirective := TDocDirective.Create(DirectiveName, '', Rest);
  Result := True;
end;

function NormaliseLineEndings(const AText: string): string;
begin
  Result := StringReplace(AText, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

function LineStartOffset(const ASource: string; ALine: Integer): Integer;
var
  I: Integer;
  CurrentLine: Integer;
begin
  if ALine <= 1 then
    Exit(1);
  CurrentLine := 1;
  for I := 1 to Length(ASource) do
    if ASource[I] = #10 then
    begin
      Inc(CurrentLine);
      if CurrentLine = ALine then
        Exit(I + 1);
    end;
  Result := Length(ASource) + 1;
end;

procedure SkipWhitespaceBackward(const ASource: string; var APosition: Integer;
  out ANewlineCount: Integer);
begin
  ANewlineCount := 0;
  while (APosition > 0) and
    (ASource[APosition] in [' ', #9, #10, #12]) do
  begin
    if ASource[APosition] = #10 then
      Inc(ANewlineCount);
    Dec(APosition);
  end;
end;

function FindBraceStart(const ASource: string; AEndPosition: Integer): Integer;
var
  Position: Integer;
  Depth: Integer;
begin
  Result := 0;
  Depth := 1;
  Position := AEndPosition - 1;
  while Position > 0 do
  begin
    if ASource[Position] = '}' then
      Inc(Depth)
    else if ASource[Position] = '{' then
    begin
      Dec(Depth);
      if Depth = 0 then
        Exit(Position);
    end;
    Dec(Position);
  end;
end;

function FindParenStart(const ASource: string; AEndPosition: Integer): Integer;
var
  Position: Integer;
  Depth: Integer;
begin
  Result := 0;
  Depth := 1;
  Position := AEndPosition - 2;
  while Position >= 2 do
  begin
    if (ASource[Position - 1] = '*') and
       (ASource[Position] = ')') then
    begin
      Inc(Depth);
      Dec(Position, 2);
    end
    else if (ASource[Position - 1] = '(') and
            (ASource[Position] = '*') then
    begin
      Dec(Depth);
      if Depth = 0 then
        Exit(Position - 1);
      Dec(Position, 2);
    end
    else
      Dec(Position);
  end;
end;

function TryCaptureSlashComment(const ASource: string; AEndPosition: Integer;
  AStyles: TDocumentationCommentStyles; out AStartPosition: Integer;
  out AFragment: TCommentFragment): Boolean;
var
  LineStart: Integer;
  ContentStart: Integer;
begin
  Result := False;
  AFragment := nil;
  AStartPosition := 0;
  if not (dcsSlash in AStyles) then
    Exit;

  LineStart := AEndPosition;
  while (LineStart > 1) and (ASource[LineStart - 1] <> #10) do
    Dec(LineStart);
  ContentStart := LineStart;
  while (ContentStart <= AEndPosition) and
    (ASource[ContentStart] in [' ', #9]) do
    Inc(ContentStart);
  if Copy(ASource, ContentStart, 3) <> '///' then
    Exit;

  AStartPosition := ContentStart;
  AFragment := TCommentFragment.Create(
    Copy(ASource, ContentStart, AEndPosition - ContentStart + 1), dcsSlash);
  Result := True;
end;

function TryCaptureBraceComment(const ASource: string; AEndPosition: Integer;
  AStyles: TDocumentationCommentStyles; out AStartPosition: Integer;
  out AFragment: TCommentFragment): Boolean;
begin
  Result := False;
  AFragment := nil;
  AStartPosition := 0;
  if (AEndPosition < 1) or (ASource[AEndPosition] <> '}') then
    Exit;
  AStartPosition := FindBraceStart(ASource, AEndPosition);
  if AStartPosition = 0 then
    Exit;
  if (AStartPosition < Length(ASource)) and
    (ASource[AStartPosition + 1] = '$') then
    Exit;
  if not (dcsBrace in AStyles) then
    Exit;

  AFragment := TCommentFragment.Create(Copy(ASource, AStartPosition,
    AEndPosition - AStartPosition + 1), dcsBrace);
  Result := True;
end;

function TryCaptureParenComment(const ASource: string; AEndPosition: Integer;
  AStyles: TDocumentationCommentStyles; out AStartPosition: Integer;
  out AFragment: TCommentFragment): Boolean;
begin
  Result := False;
  AFragment := nil;
  AStartPosition := 0;
  if (AEndPosition < 2) or (ASource[AEndPosition] <> ')') or
    (ASource[AEndPosition - 1] <> '*') then
    Exit;
  AStartPosition := FindParenStart(ASource, AEndPosition);
  if AStartPosition = 0 then
    Exit;
  if (AStartPosition + 2 <= Length(ASource)) and
    (ASource[AStartPosition + 2] = '$') then
    Exit;
  if not (dcsParen in AStyles) then
    Exit;

  AFragment := TCommentFragment.Create(Copy(ASource, AStartPosition,
    AEndPosition - AStartPosition + 1), dcsParen);
  Result := True;
end;

function TryCaptureComment(const ASource: string; AEndPosition: Integer;
  AStyles: TDocumentationCommentStyles; out AStartPosition: Integer;
  out AFragment: TCommentFragment): Boolean;
begin
  Result := TryCaptureBraceComment(ASource, AEndPosition, AStyles,
    AStartPosition, AFragment);
  if Result then
    Exit;
  Result := TryCaptureParenComment(ASource, AEndPosition, AStyles,
    AStartPosition, AFragment);
  if Result then
    Exit;
  Result := TryCaptureSlashComment(ASource, AEndPosition, AStyles,
    AStartPosition, AFragment);
end;

function LeadingWhitespaceLength(const AText: string): Integer;
begin
  Result := 0;
  while (Result < Length(AText)) and
    (AText[Result + 1] in [' ', #9]) do
    Inc(Result);
end;

function CommentStartsSourceLine(const ASource: string;
  AStartPosition: Integer): Boolean;
var
  Position: Integer;
begin
  Position := AStartPosition - 1;
  while (Position > 0) and (ASource[Position] <> #10) do
  begin
    if not (ASource[Position] in [' ', #9]) then
      Exit(False);
    Dec(Position);
  end;
  Result := True;
end;

function NormaliseBlockBody(const ABody: string): string;
var
  Lines: TStringList;
  I: Integer;
  Indent: Integer;
  CommonIndent: Integer;
  Decorated: Boolean;
  HasContent: Boolean;
  ContentStart: Integer;
  Line: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := NormaliseLineEndings(ABody);
    while (Lines.Count > 0) and (Trim(Lines[0]) = '') do
      Lines.Delete(0);
    while (Lines.Count > 0) and (Trim(Lines[Lines.Count - 1]) = '') do
      Lines.Delete(Lines.Count - 1);
    if Lines.Count = 0 then
      Exit('');
    if Lines.Count = 1 then
      Exit(Trim(Lines[0]));

    CommonIndent := MaxInt;
    for I := 0 to Lines.Count - 1 do
      if Trim(Lines[I]) <> '' then
      begin
        Indent := LeadingWhitespaceLength(Lines[I]);
        if Indent < CommonIndent then
          CommonIndent := Indent;
      end;
    if CommonIndent = MaxInt then
      CommonIndent := 0;
    if CommonIndent > 0 then
      for I := 0 to Lines.Count - 1 do
      begin
        Line := Lines[I];
        Delete(Line, 1, CommonIndent);
        Lines[I] := Line;
      end;

    Decorated := True;
    HasContent := False;
    for I := 0 to Lines.Count - 1 do
      if Trim(Lines[I]) <> '' then
      begin
        HasContent := True;
        ContentStart := LeadingWhitespaceLength(Lines[I]) + 1;
        if (ContentStart > Length(Lines[I])) or
          (Lines[I][ContentStart] <> '*') then
          Decorated := False;
      end;
    if Decorated and HasContent then
      for I := 0 to Lines.Count - 1 do
        if Trim(Lines[I]) <> '' then
        begin
          Line := Lines[I];
          ContentStart := LeadingWhitespaceLength(Line) + 1;
          Delete(Line, ContentStart, 1);
          if (ContentStart <= Length(Line)) and
            (Line[ContentStart] = ' ') then
            Delete(Line, ContentStart, 1);
          Lines[I] := Line;
        end;

    Result := '';
    for I := 0 to Lines.Count - 1 do
      AppendLine(Result, Lines[I]);
  finally
    Lines.Free;
  end;
end;

function FragmentBody(AFragment: TCommentFragment): string;
begin
  case AFragment.Style of
    dcsSlash:
      begin
        Result := Copy(AFragment.RawText, 4, MaxInt);
        if (Result <> '') and (Result[1] = ' ') then
          Delete(Result, 1, 1);
      end;
    dcsBrace:
      Result := NormaliseBlockBody(Copy(AFragment.RawText, 2,
        Length(AFragment.RawText) - 2));
    dcsParen:
      Result := NormaliseBlockBody(Copy(AFragment.RawText, 3,
        Length(AFragment.RawText) - 4));
  end;
end;

procedure AppendDocumentationBody(const ABody: string;
  var AMarkdownDocumentation: string; ADirectives: TObjectList);
var
  Lines: TStringList;
  I: Integer;
  Directive: TDocDirective;
  Content: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := NormaliseLineEndings(ABody);
    for I := 0 to Lines.Count - 1 do
    begin
      Content := Lines[I];
      if TryParseDirective(TrimLeft(Content), Directive) then
        ADirectives.Add(Directive)
      else
        AppendLine(AMarkdownDocumentation, Content);
    end;
  finally
    Lines.Free;
  end;
end;

procedure ParseDocumentationComment(const ASourceText: string;
  ADeclarationLine: Integer; AStyles: TDocumentationCommentStyles;
  out ARawDocumentation, AMarkdownDocumentation: string;
  ADirectives: TObjectList);
var
  Source: string;
  Position: Integer;
  StartPosition: Integer;
  NewlineCount: Integer;
  Fragment: TCommentFragment;
  Fragments: TObjectList;
  I: Integer;
  GroupStartPosition: Integer;
begin
  ARawDocumentation := '';
  AMarkdownDocumentation := '';
  ADirectives.Clear;
  if (ASourceText = '') or (ADeclarationLine <= 0) or (AStyles = []) then
    Exit;

  Source := NormaliseLineEndings(ASourceText);
  Position := LineStartOffset(Source, ADeclarationLine) - 1;
  SkipWhitespaceBackward(Source, Position, NewlineCount);
  if (Position <= 0) or (NewlineCount > 1) then
    Exit;

  Fragments := TObjectList.Create(True);
  try
    GroupStartPosition := 0;
    while TryCaptureComment(Source, Position, AStyles, StartPosition,
      Fragment) do
    begin
      Fragments.Add(Fragment);
      GroupStartPosition := StartPosition;
      Position := StartPosition - 1;
      SkipWhitespaceBackward(Source, Position, NewlineCount);
      if (Position <= 0) or (NewlineCount > 1) then
        Break;
    end;

    if (Fragments.Count > 0) and
      not CommentStartsSourceLine(Source, GroupStartPosition) then
      Fragments.Clear;

    for I := Fragments.Count - 1 downto 0 do
    begin
      Fragment := TCommentFragment(Fragments[I]);
      AppendLine(ARawDocumentation, Fragment.RawText);
      AppendDocumentationBody(FragmentBody(Fragment),
        AMarkdownDocumentation, ADirectives);
    end;
  finally
    Fragments.Free;
  end;
end;

end.
