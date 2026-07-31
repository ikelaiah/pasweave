unit PasWeave.Comments;

{$mode objfpc}{$H+}

interface

uses
  Contnrs;

procedure ParseDocumentationComment(const AParserComment: string;
  out ARawDocumentation, AMarkdownDocumentation: string;
  ADirectives: TObjectList);

implementation

uses
  Classes, SysUtils, PasWeave.Model;

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

function SplitFirstWord(const AText: string; out AWord, ARemainder: string): Boolean;
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

function TryParseDirective(const ALine: string; out ADirective: TDocDirective): Boolean;
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

procedure ParseDocumentationComment(const AParserComment: string;
  out ARawDocumentation, AMarkdownDocumentation: string;
  ADirectives: TObjectList);
var
  Lines: TStringList;
  FirstDocLine: Integer;
  LastLine: Integer;
  I: Integer;
  Content: string;
  Directive: TDocDirective;
begin
  ARawDocumentation := '';
  AMarkdownDocumentation := '';
  ADirectives.Clear;
  if AParserComment = '' then
    Exit;

  Lines := TStringList.Create;
  try
    Lines.Text := AParserComment;
    LastLine := Lines.Count - 1;
    while (LastLine >= 0) and (Lines[LastLine] = '') do
      Dec(LastLine);

    FirstDocLine := LastLine;
    while (FirstDocLine >= 0) and (Lines[FirstDocLine] <> '') and
      (Lines[FirstDocLine][1] = '/') do
      Dec(FirstDocLine);
    Inc(FirstDocLine);

    if FirstDocLine > LastLine then
      Exit;

    for I := FirstDocLine to LastLine do
    begin
      AppendLine(ARawDocumentation, '//' + Lines[I]);
      Content := Copy(Lines[I], 2, MaxInt);
      if (Content <> '') and (Content[1] = ' ') then
        Delete(Content, 1, 1);
      if TryParseDirective(Content, Directive) then
        ADirectives.Add(Directive)
      else
        AppendLine(AMarkdownDocumentation, Content);
    end;
  finally
    Lines.Free;
  end;
end;

end.

