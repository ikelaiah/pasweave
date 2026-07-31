unit PasWeave.Render.HTML.Markdown;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

function EscapeHTML(const AText: string): UTF8String;
function RenderInlineMarkdown(const AText: string): UTF8String;
function RenderMarkdownFragment(const AMarkdown: string): UTF8String;

implementation

uses
  Classes, SysUtils, StrUtils;

procedure AppendLine(var AOutput: UTF8String; const ALine: UTF8String = '');
begin
  AOutput := AOutput + ALine + #10;
end;

function EscapeHTML(const AText: string): UTF8String;
var
  Value: string;
begin
  Value := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Value := StringReplace(Value, '<', '&lt;', [rfReplaceAll]);
  Value := StringReplace(Value, '>', '&gt;', [rfReplaceAll]);
  Value := StringReplace(Value, '"', '&quot;', [rfReplaceAll]);
  Value := StringReplace(Value, '''', '&#39;', [rfReplaceAll]);
  Result := UTF8String(Value);
end;

function IsSafeLinkTarget(const ATarget: string): Boolean;
var
  LowerTarget: string;
begin
  LowerTarget := LowerCase(Trim(ATarget));
  Result := (Pos('javascript:', LowerTarget) <> 1) and
    (Pos('data:', LowerTarget) <> 1) and
    (Pos('vbscript:', LowerTarget) <> 1);
end;

function IsEscaped(const AText: string; APosition: Integer): Boolean;
var
  BackslashCount: Integer;
begin
  BackslashCount := 0;
  Dec(APosition);
  while (APosition > 0) and (AText[APosition] = '\') do
  begin
    Inc(BackslashCount);
    Dec(APosition);
  end;
  Result := Odd(BackslashCount);
end;

function FindInlineMathEnd(const AText: string; AStart: Integer): Integer;
begin
  { Conservative dollar boundaries keep paired currency amounts such as
    $20 and $30 from consuming the prose between them. }
  Result := AStart;
  while Result <= Length(AText) do
  begin
    if (AText[Result] = '$') and not IsEscaped(AText, Result) and
      (Result > 1) and (AText[Result - 1] > ' ') and
      (AText[Result - 1] <> '$') and
      ((Result = Length(AText)) or
        ((AText[Result + 1] <> '$') and
          not (AText[Result + 1] in ['0'..'9']))) then
      Exit;
    Inc(Result);
  end;
  Result := 0;
end;

function RenderInlineMarkdown(const AText: string): UTF8String;
var
  I: Integer;
  CloseAt: Integer;
  LabelEnd: Integer;
  TargetEnd: Integer;
  LabelText: string;
  Target: string;
begin
  Result := '';
  I := 1;
  while I <= Length(AText) do
  begin
    if (AText[I] = '\') and (I < Length(AText)) and
      (AText[I + 1] = '$') and not IsEscaped(AText, I) then
    begin
      Result := Result + '$';
      Inc(I, 2);
      Continue;
    end;

    if AText[I] = '`' then
    begin
      CloseAt := PosEx('`', AText, I + 1);
      if CloseAt > 0 then
      begin
        Result := Result + '<code>' +
          EscapeHTML(Copy(AText, I + 1, CloseAt - I - 1)) + '</code>';
        I := CloseAt + 1;
        Continue;
      end;
    end;

    if AText[I] = '[' then
    begin
      LabelEnd := PosEx('](', AText, I + 1);
      if LabelEnd > 0 then
      begin
        TargetEnd := PosEx(')', AText, LabelEnd + 2);
        if TargetEnd > 0 then
        begin
          LabelText := Copy(AText, I + 1, LabelEnd - I - 1);
          Target := Copy(AText, LabelEnd + 2,
            TargetEnd - LabelEnd - 2);
          if IsSafeLinkTarget(Target) then
            Result := Result + '<a href="' + EscapeHTML(Target) + '">' +
              EscapeHTML(LabelText) + '</a>'
          else
            Result := Result + EscapeHTML(LabelText);
          I := TargetEnd + 1;
          Continue;
        end;
      end;
    end;

    if (AText[I] = '*') and (I < Length(AText)) and
      (AText[I + 1] = '*') then
    begin
      CloseAt := PosEx('**', AText, I + 2);
      if CloseAt > 0 then
      begin
        Result := Result + '<strong>' +
          EscapeHTML(Copy(AText, I + 2, CloseAt - I - 2)) + '</strong>';
        I := CloseAt + 2;
        Continue;
      end;
    end;

    if AText[I] = '*' then
    begin
      CloseAt := PosEx('*', AText, I + 1);
      if CloseAt > 0 then
      begin
        Result := Result + '<em>' +
          EscapeHTML(Copy(AText, I + 1, CloseAt - I - 1)) + '</em>';
        I := CloseAt + 1;
        Continue;
      end;
    end;

    if (AText[I] = '$') and
      not IsEscaped(AText, I) and
      ((I = 1) or (AText[I - 1] <> '$')) and
      (I < Length(AText)) and (AText[I + 1] > ' ') and
      (AText[I + 1] <> '$') then
    begin
      CloseAt := FindInlineMathEnd(AText, I + 1);
      if CloseAt > 0 then
      begin
        Result := Result + '<span class="math-inline" data-math-inline>' +
          EscapeHTML(Copy(AText, I, CloseAt - I + 1)) + '</span>';
        I := CloseAt + 1;
        Continue;
      end;
    end;

    Result := Result + EscapeHTML(Copy(AText, I, 1));
    Inc(I);
  end;
end;

function OrderedListText(const ALine: string; out AText: string): Boolean;
var
  I: Integer;
begin
  I := 1;
  while (I <= Length(ALine)) and (ALine[I] in ['0'..'9']) do
    Inc(I);
  Result := (I > 1) and (I + 1 <= Length(ALine)) and
    (ALine[I] = '.') and (ALine[I + 1] = ' ');
  if Result then
    AText := Copy(ALine, I + 2, MaxInt)
  else
    AText := '';
end;

function RenderMarkdownFragment(const AMarkdown: string): UTF8String;
var
  Lines: TStringList;
  Normalized: string;
  Line: string;
  Trimmed: string;
  Paragraph: string;
  ListText: string;
  FenceLanguage: string;
  I: Integer;
  HeadingLevel: Integer;
  InFence: Boolean;
  InMath: Boolean;
  InBulletList: Boolean;
  InOrderedList: Boolean;

  procedure CloseParagraph;
  begin
    if Paragraph <> '' then
    begin
      AppendLine(Result, '<p>' + RenderInlineMarkdown(Paragraph) + '</p>');
      Paragraph := '';
    end;
  end;

  procedure CloseLists;
  begin
    if InBulletList then
    begin
      AppendLine(Result, '</ul>');
      InBulletList := False;
    end;
    if InOrderedList then
    begin
      AppendLine(Result, '</ol>');
      InOrderedList := False;
    end;
  end;

begin
  Result := '';
  Normalized := StringReplace(AMarkdown, #13#10, #10, [rfReplaceAll]);
  Normalized := StringReplace(Normalized, #13, #10, [rfReplaceAll]);
  Lines := TStringList.Create;
  try
    Lines.Text := Normalized;
    Paragraph := '';
    InFence := False;
    InMath := False;
    InBulletList := False;
    InOrderedList := False;
    for I := 0 to Lines.Count - 1 do
    begin
      Line := Lines[I];
      Trimmed := Trim(Line);

      if InFence then
      begin
        if Pos('```', Trimmed) = 1 then
        begin
          AppendLine(Result, '</code></pre>');
          InFence := False;
        end
        else
          AppendLine(Result, EscapeHTML(Line));
        Continue;
      end;

      if InMath then
      begin
        AppendLine(Result, EscapeHTML(Line));
        if Trimmed = '$$' then
        begin
          AppendLine(Result, '</div>');
          InMath := False;
        end;
        Continue;
      end;

      if Pos('```', Trimmed) = 1 then
      begin
        CloseParagraph;
        CloseLists;
        FenceLanguage := Trim(Copy(Trimmed, 4, MaxInt));
        if FenceLanguage <> '' then
          AppendLine(Result, '<pre><code class="language-' +
            EscapeHTML(FenceLanguage) + '">')
        else
          AppendLine(Result, '<pre><code>');
        InFence := True;
        Continue;
      end;

      if Trimmed = '$$' then
      begin
        CloseParagraph;
        CloseLists;
        AppendLine(Result, '<div class="math-display" data-math-display>');
        AppendLine(Result, '$$');
        InMath := True;
        Continue;
      end;

      if Trimmed = '' then
      begin
        CloseParagraph;
        CloseLists;
        Continue;
      end;

      HeadingLevel := 0;
      while (HeadingLevel < Length(Trimmed)) and
        (Trimmed[HeadingLevel + 1] = '#') do
        Inc(HeadingLevel);
      if (HeadingLevel > 0) and (HeadingLevel < Length(Trimmed)) and
        (Trimmed[HeadingLevel + 1] = ' ') then
      begin
        CloseParagraph;
        CloseLists;
        HeadingLevel := HeadingLevel + 3;
        if HeadingLevel > 6 then
          HeadingLevel := 6;
        AppendLine(Result, '<h' + UTF8String(IntToStr(HeadingLevel)) + '>' +
          RenderInlineMarkdown(Copy(Trimmed, Pos(' ', Trimmed) + 1,
          MaxInt)) + '</h' + UTF8String(IntToStr(HeadingLevel)) + '>');
        Continue;
      end;

      if (Pos('- ', Trimmed) = 1) or (Pos('* ', Trimmed) = 1) then
      begin
        CloseParagraph;
        if InOrderedList then
        begin
          AppendLine(Result, '</ol>');
          InOrderedList := False;
        end;
        if not InBulletList then
        begin
          AppendLine(Result, '<ul>');
          InBulletList := True;
        end;
        AppendLine(Result, '<li>' +
          RenderInlineMarkdown(Copy(Trimmed, 3, MaxInt)) + '</li>');
        Continue;
      end;

      if OrderedListText(Trimmed, ListText) then
      begin
        CloseParagraph;
        if InBulletList then
        begin
          AppendLine(Result, '</ul>');
          InBulletList := False;
        end;
        if not InOrderedList then
        begin
          AppendLine(Result, '<ol>');
          InOrderedList := True;
        end;
        AppendLine(Result, '<li>' + RenderInlineMarkdown(ListText) + '</li>');
        Continue;
      end;

      CloseLists;
      if Pos('> ', Trimmed) = 1 then
      begin
        CloseParagraph;
        AppendLine(Result, '<blockquote><p>' +
          RenderInlineMarkdown(Copy(Trimmed, 3, MaxInt)) +
          '</p></blockquote>');
        Continue;
      end;

      if Paragraph <> '' then
        Paragraph := Paragraph + ' ';
      Paragraph := Paragraph + Trimmed;
    end;

    CloseParagraph;
    CloseLists;
    if InFence then
      AppendLine(Result, '</code></pre>');
    if InMath then
      AppendLine(Result, '</div>');
  finally
    Lines.Free;
  end;
end;

end.
