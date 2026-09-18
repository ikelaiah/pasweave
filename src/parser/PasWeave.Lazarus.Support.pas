/// Shared Lazarus configuration helpers: XML access, path and macro
/// expansion, and Free Pascal custom-option parsing.
unit PasWeave.Lazarus.Support;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, PasWeave.Compiler;

type
  ELazarusConfigurationError = class(Exception);

function NormalisePath(const APath: string): string;
function ChildNode(AParent: TDOMNode; const AName: string): TDOMNode;
function AttributeValue(ANode: TDOMNode; const AName: string): string;
function NodeValue(ANode: TDOMNode; const AName: string): string;
function IsPascalSourceFile(const AFilename: string): Boolean;
function IsTrueValue(const AValue: string): Boolean;
function DefaultName(const AFilename: string): string;
function ResolvePath(const ABaseDirectory, AValue: string): string;
function ExpandConfiguredValue(const AValue, ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions; out AGenerated: Boolean): string;
function ResolvePackageReference(const ABaseDirectory, AValue: string;
  ACompilerOptions: TCompilerOptions): string;
function DirectoryIsReadable(const APath: string): Boolean;
function NormalisePackagePath(const AValue: string): string;
procedure AddConfiguredPath(const AValue, ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions; AIncludePath: Boolean);
procedure SplitCommandLine(const AValue: string; AValues: TStrings);
procedure ParseCustomOptions(const AValue, ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions);
procedure ParseTarget(ANode: TDOMNode; ACompilerOptions: TCompilerOptions);
procedure ParseCompilerOptions(ANode: TDOMNode; const ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions);

implementation

uses
  Contnrs, XMLRead;

function NormalisePath(const APath: string): string;
begin
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

function ChildNode(AParent: TDOMNode; const AName: string): TDOMNode;
var
  Node: TDOMNode;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;
  Node := AParent.FirstChild;
  while Assigned(Node) do
  begin
    if SameText(Node.NodeName, AName) then
      Exit(Node);
    Node := Node.NextSibling;
  end;
end;

function AttributeValue(ANode: TDOMNode; const AName: string): string;
var
  Attribute: TDOMNode;
begin
  Result := '';
  if not Assigned(ANode) or not Assigned(ANode.Attributes) then
    Exit;
  Attribute := ANode.Attributes.GetNamedItem(AName);
  if Assigned(Attribute) then
    Result := Attribute.NodeValue;
end;

function NodeValue(ANode: TDOMNode; const AName: string): string;
begin
  Result := AttributeValue(ChildNode(ANode, AName), 'Value');
end;

function IsPascalSourceFile(const AFilename: string): Boolean;
begin
  Result := SameText(ExtractFileExt(AFilename), '.pas') or
    SameText(ExtractFileExt(AFilename), '.pp');
end;

function IsTrueValue(const AValue: string): Boolean;
begin
  Result := SameText(Trim(AValue), 'true') or (Trim(AValue) = '1');
end;

function DefaultName(const AFilename: string): string;
begin
  Result := ChangeFileExt(ExtractFileName(AFilename), '');
end;

function ResolvePath(const ABaseDirectory, AValue: string): string;
var
  Value: string;
begin
  Value := StringReplace(Trim(AValue), '\', PathDelim, [rfReplaceAll]);
  if Value = '' then
    Exit('');
  if (Value[1] = PathDelim) or (Value[1] = '/') or
    ((Length(Value) >= 2) and (Value[2] = ':')) then
    Result := ExpandFileName(Value)
  else
    Result := ExpandFileName(IncludeTrailingPathDelimiter(ABaseDirectory) +
      Value);
end;

function ResolvePackageReference(const ABaseDirectory, AValue: string;
  ACompilerOptions: TCompilerOptions): string;
var
  Expanded: string;
  Generated: Boolean;
begin
  Expanded := AValue;
  if Pos('$(', Expanded) > 0 then
  begin
    Expanded := ExpandConfiguredValue(Expanded, ABaseDirectory,
      ACompilerOptions, Generated);
    if Generated then
      raise ELazarusConfigurationError.CreateFmt(
        'unsupported Lazarus macro in package reference: %s', [AValue]);
  end;
  Result := ResolvePath(ABaseDirectory, Expanded);
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

function NormalisePackagePath(const AValue: string): string;
begin
  Result := Trim(AValue);
  if Result = '' then
    raise ELazarusConfigurationError.Create(
      'Lazarus package path must not be empty');
  Result := ExpandFileName(Result);
  if not DirectoryExists(Result) then
    raise ELazarusConfigurationError.CreateFmt(
      'Lazarus package path does not exist: %s', [AValue]);
  if not DirectoryIsReadable(Result) then
    raise ELazarusConfigurationError.CreateFmt(
      'Lazarus package path is not readable: %s', [AValue]);
  Result := ExcludeTrailingPathDelimiter(Result);
end;

function MacroToken(const AValue: string; AStart: Integer;
  out AEnd: Integer): string;
var
  Closing: Integer;
begin
  Result := '';
  AEnd := 0;
  Closing := Pos(')', Copy(AValue, AStart + 2, MaxInt));
  if Closing = 0 then
    raise ELazarusConfigurationError.CreateFmt(
      'unsupported Lazarus macro in value: %s', [AValue]);
  AEnd := AStart + Closing + 1;
  Result := Copy(AValue, AStart, AEnd - AStart + 1);
end;

function ExpandConfiguredValue(const AValue, ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions; out AGenerated: Boolean): string;
var
  Position: Integer;
  EndPosition: Integer;
  Token: string;
  Name: string;
  Replacement: string;
begin
  Result := AValue;
  AGenerated := False;
  Position := Pos('$(', Result);
  while Position > 0 do
  begin
    Token := MacroToken(Result, Position, EndPosition);
    Name := LowerCase(Copy(Token, 3, Length(Token) - 3));
    if (Name = 'projdir') or (Name = 'pkgdir') then
      Replacement := ABaseDirectory
    else if (Name = 'projoutdir') or (Name = 'pkgoutdir') then
    begin
      AGenerated := True;
      Replacement := '';
    end
    else if Name = 'targetcpu' then
      Replacement := ACompilerOptions.TargetCPU
    else if Name = 'targetos' then
      Replacement := ACompilerOptions.TargetOS
    else if Name = 'lclwidgettype' then
    begin
      if (ACompilerOptions.TargetOS = 'win32') or
        (ACompilerOptions.TargetOS = 'win64') then
        Replacement := 'win32'
      else
        Replacement := 'gtk2';
    end
    else if Name = 'idebuildoptions' then
      Replacement := ''
    else
      raise ELazarusConfigurationError.CreateFmt(
        'unsupported Lazarus macro: %s', [Token]);
    Delete(Result, Position, Length(Token));
    Insert(Replacement, Result, Position);
    if AGenerated then
      Exit;
    Position := Pos('$(', Result);
  end;
end;

procedure SplitValues(const AValue: string; AValues: TStrings);
var
  Parts: TStringList;
  I: Integer;
begin
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True;
    Parts.Delimiter := ';';
    Parts.DelimitedText := AValue;
    for I := 0 to Parts.Count - 1 do
      if Trim(Parts[I]) <> '' then
        AValues.Add(Trim(Parts[I]));
  finally
    Parts.Free;
  end;
end;

procedure AddConfiguredPath(const AValue, ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions; AIncludePath: Boolean);
var
  Values: TStringList;
  I: Integer;
  Expanded: string;
  Generated: Boolean;
  PathKind: string;
begin
  Values := TStringList.Create;
  try
    SplitValues(AValue, Values);
    for I := 0 to Values.Count - 1 do
    begin
      Expanded := ExpandConfiguredValue(Values[I], ABaseDirectory,
        ACompilerOptions, Generated);
      if Generated then
        Continue;
      Expanded := ResolvePath(ABaseDirectory, Expanded);
      try
        if AIncludePath then
          ACompilerOptions.AddIncludePath(Expanded)
        else
          ACompilerOptions.AddUnitPath(Expanded);
      except
        on E: ECompilerConfigurationError do
        begin
          if AIncludePath then
            PathKind := 'include'
          else
            PathKind := 'unit';
          raise ELazarusConfigurationError.CreateFmt(
            'invalid Lazarus %s path: %s (%s)',
            [PathKind, Values[I], E.Message]);
        end;
      end;
    end;
  finally
    Values.Free;
  end;
end;

procedure SplitCommandLine(const AValue: string; AValues: TStrings);
var
  I: Integer;
  Current: string;
  Quoted: Boolean;
  Character: Char;
begin
  Current := '';
  Quoted := False;
  for I := 1 to Length(AValue) do
  begin
    Character := AValue[I];
    if Character = '"' then
      Quoted := not Quoted
    else if (Character in [' ', #9]) and not Quoted then
    begin
      if Current <> '' then
      begin
        AValues.Add(Current);
        Current := '';
      end;
    end
    else
      Current := Current + Character;
  end;
  if Current <> '' then
    AValues.Add(Current);
end;

procedure ParseCustomOptions(const AValue, ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions);
var
  Values: TStringList;
  I: Integer;
  Token: string;
  OptionValue: string;
  Generated: Boolean;
begin
  Values := TStringList.Create;
  try
    SplitCommandLine(AValue, Values);
    I := 0;
    while I < Values.Count do
    begin
      Token := Values[I];
      if (Length(Token) >= 2) and (LowerCase(Copy(Token, 1, 2)) = '-d') then
      begin
        OptionValue := Copy(Token, 3, MaxInt);
        if OptionValue = '' then
        begin
          Inc(I);
          if I >= Values.Count then
            raise ELazarusConfigurationError.Create(
              'Lazarus -d option is missing its define');
          OptionValue := Values[I];
        end;
        OptionValue := ExpandConfiguredValue(OptionValue, ABaseDirectory,
          ACompilerOptions, Generated);
        if not Generated then
        begin
          try
            ACompilerOptions.AddDefine(OptionValue);
          except
            on E: ECompilerConfigurationError do
              raise ELazarusConfigurationError.Create(E.Message);
          end;
        end;
      end
      else if (Length(Token) >= 3) and
        (LowerCase(Copy(Token, 1, 3)) = '-fi') then
      begin
        OptionValue := Copy(Token, 4, MaxInt);
        if OptionValue = '' then
        begin
          Inc(I);
          if I >= Values.Count then
            raise ELazarusConfigurationError.Create(
              'Lazarus -Fi option is missing its path');
          OptionValue := Values[I];
        end;
        ExpandConfiguredValue(OptionValue, ABaseDirectory,
          ACompilerOptions, Generated);
        if not Generated then
          AddConfiguredPath(OptionValue, ABaseDirectory, ACompilerOptions,
            True);
      end
      else if (Length(Token) >= 3) and
        (LowerCase(Copy(Token, 1, 3)) = '-fu') then
      begin
        OptionValue := Copy(Token, 4, MaxInt);
        if OptionValue = '' then
        begin
          Inc(I);
          if I >= Values.Count then
            raise ELazarusConfigurationError.Create(
              'Lazarus -Fu option is missing its path');
          OptionValue := Values[I];
        end;
        ExpandConfiguredValue(OptionValue, ABaseDirectory,
          ACompilerOptions, Generated);
        if not Generated then
          AddConfiguredPath(OptionValue, ABaseDirectory, ACompilerOptions,
            False);
      end
      else if (Length(Token) >= 2) and
        (LowerCase(Copy(Token, 1, 2)) = '-t') then
      begin
        OptionValue := Copy(Token, 3, MaxInt);
        if OptionValue = '' then
        begin
          Inc(I);
          if I >= Values.Count then
            raise ELazarusConfigurationError.Create(
              'Lazarus -T option is missing its target OS');
          OptionValue := Values[I];
        end;
        try
          ACompilerOptions.SetTargetOS(OptionValue);
        except
          on E: ECompilerConfigurationError do
            raise ELazarusConfigurationError.Create(E.Message);
        end;
      end
      else if (Length(Token) >= 2) and
        (LowerCase(Copy(Token, 1, 2)) = '-p') then
      begin
        OptionValue := Copy(Token, 3, MaxInt);
        if OptionValue = '' then
        begin
          Inc(I);
          if I >= Values.Count then
            raise ELazarusConfigurationError.Create(
              'Lazarus -P option is missing its target CPU');
          OptionValue := Values[I];
        end;
        try
          ACompilerOptions.SetTargetCPU(OptionValue);
        except
          on E: ECompilerConfigurationError do
            raise ELazarusConfigurationError.Create(E.Message);
        end;
      end
      else
      begin
        ExpandConfiguredValue(Token, ABaseDirectory, ACompilerOptions,
          Generated);
      end;
      Inc(I);
    end;
  finally
    Values.Free;
  end;
end;

procedure ParseTarget(ANode: TDOMNode; ACompilerOptions: TCompilerOptions);
var
  TargetOS: string;
  TargetCPU: string;
begin
  if not Assigned(ANode) then
    Exit;
  TargetOS := NodeValue(ANode, 'OS');
  if TargetOS = '' then
    TargetOS := NodeValue(ANode, 'TargetOS');
  TargetCPU := NodeValue(ANode, 'CPU');
  if TargetCPU = '' then
    TargetCPU := NodeValue(ANode, 'TargetCPU');
  try
    if TargetOS <> '' then
      ACompilerOptions.SetTargetOS(TargetOS);
    if TargetCPU <> '' then
      ACompilerOptions.SetTargetCPU(TargetCPU);
  except
    on E: ECompilerConfigurationError do
      raise ELazarusConfigurationError.Create(E.Message);
  end;
end;

procedure ParseCompilerOptions(ANode: TDOMNode; const ABaseDirectory: string;
  ACompilerOptions: TCompilerOptions);
var
  SearchPaths: TDOMNode;
  Other: TDOMNode;
  CustomOptions: string;
begin
  if not Assigned(ANode) then
    Exit;
  ParseTarget(ChildNode(ANode, 'Target'), ACompilerOptions);
  Other := ChildNode(ANode, 'Other');
  CustomOptions := NodeValue(Other, 'CustomOptions');
  if CustomOptions <> '' then
    ParseCustomOptions(CustomOptions, ABaseDirectory, ACompilerOptions);
  SearchPaths := ChildNode(ANode, 'SearchPaths');
  if Assigned(SearchPaths) then
  begin
    AddConfiguredPath(NodeValue(SearchPaths, 'OtherUnitFiles'),
      ABaseDirectory, ACompilerOptions, False);
    AddConfiguredPath(NodeValue(SearchPaths, 'IncludeFiles'),
      ABaseDirectory, ACompilerOptions, True);
  end;
end;

end.
