unit PasWeave.FPCAdapter;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Comments, PasWeave.Diagnostics, PasWeave.Model;

function ParseUnitFile(const AFileName, ASourceRoot: string;
  ACommentStyles: TDocumentationCommentStyles;
  out AUnit: TDocUnit; out ADiagnostic: TDiagnostic): Boolean;

implementation

uses
  Classes, Contnrs, SysUtils, PParser, PScanner, PasTree;

type
  TElementSourceInfo = class
  public
    Column: Integer;
    constructor Create(AColumn: Integer);
  end;

  TPasWeaveTreeContainer = class(TPasTreeContainer)
  private
    FSourceInfos: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateElement(AClass: TPTreeElement; const AName: string;
      AParent: TPasElement; AVisibility: TPasMemberVisibility;
      const ASourceFilename: string; ASourceLinenumber: Integer): TPasElement;
      override;
    function CreateElement(AClass: TPTreeElement; const AName: string;
      AParent: TPasElement; AVisibility: TPasMemberVisibility;
      const ASrcPos: TPasSourcePos; TypeParams: TFPList = nil): TPasElement;
      override;
    function FindElement(const AName: string): TPasElement; override;
  end;

constructor TElementSourceInfo.Create(AColumn: Integer);
begin
  inherited Create;
  Column := AColumn;
end;

constructor TPasWeaveTreeContainer.Create;
begin
  inherited Create;
  FSourceInfos := TObjectList.Create(True);
  InterfaceOnly := True;
end;

destructor TPasWeaveTreeContainer.Destroy;
begin
  FSourceInfos.Free;
  inherited Destroy;
end;

function TPasWeaveTreeContainer.CreateElement(AClass: TPTreeElement;
  const AName: string; AParent: TPasElement;
  AVisibility: TPasMemberVisibility; const ASourceFilename: string;
  ASourceLinenumber: Integer): TPasElement;
var
  SourceInfo: TElementSourceInfo;
begin
  Result := AClass.Create(AName, AParent);
  Result.Visibility := AVisibility;
  Result.SourceFilename := ASourceFilename;
  Result.SourceLinenumber := ASourceLinenumber;
  SourceInfo := TElementSourceInfo.Create(0);
  FSourceInfos.Add(SourceInfo);
  Result.CustomData := SourceInfo;
end;

function TPasWeaveTreeContainer.CreateElement(AClass: TPTreeElement;
  const AName: string; AParent: TPasElement;
  AVisibility: TPasMemberVisibility; const ASrcPos: TPasSourcePos;
  TypeParams: TFPList): TPasElement;
begin
  Result := inherited CreateElement(AClass, AName, AParent, AVisibility,
    ASrcPos, TypeParams);
  if Result.CustomData is TElementSourceInfo then
    TElementSourceInfo(Result.CustomData).Column := ASrcPos.Column;
end;

function TPasWeaveTreeContainer.FindElement(const AName: string): TPasElement;
begin
  Result := nil;
  if AName = '' then
    Exit;
end;

function NormalisePath(const APath: string): string;
begin
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
end;

function RelativeSourceFilename(const AFileName, ASourceRoot: string): string;
var
  RootPath: string;
begin
  if AFileName = '' then
    Exit('');
  RootPath := IncludeTrailingPathDelimiter(ExpandFileName(ASourceRoot));
  Result := ExtractRelativePath(RootPath, ExpandFileName(AFileName));
  Result := NormalisePath(Result);
end;

function ReadSourceText(const AFileName: string): string;
var
  SourceStream: TFileStream;
begin
  SourceStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, SourceStream.Size);
    if SourceStream.Size > 0 then
      SourceStream.ReadBuffer(Result[1], SourceStream.Size);
  finally
    SourceStream.Free;
  end;
end;

function CleanParserMessage(const AMessage, AParserFilename,
  ADisplayFilename: string): string;
var
  LocationStart: Integer;
begin
  Result := StringReplace(AMessage, AParserFilename, ADisplayFilename,
    [rfReplaceAll]);
  LocationStart := Pos(' in file ', Result);
  if LocationStart > 0 then
    Delete(Result, LocationStart, MaxInt);
end;

function ElementColumn(AElement: TPasElement): Integer;
begin
  Result := 0;
  if Assigned(AElement) and (AElement.CustomData is TElementSourceInfo) then
    Result := TElementSourceInfo(AElement.CustomData).Column;
end;

function CanonicalText(const AText: string): string;
var
  I: Integer;
  InWhitespace: Boolean;
  C: Char;
begin
  Result := '';
  InWhitespace := False;
  for I := 1 to Length(AText) do
  begin
    C := AText[I];
    if C in [' ', #9, #10, #13] then
    begin
      if (Result <> '') and not InWhitespace then
        Result := Result + ' ';
      InWhitespace := True;
    end
    else
    begin
      Result := Result + LowerCase(C);
      InWhitespace := False;
    end;
  end;
  Result := Trim(Result);
end;

function NormaliseDeclaration(const ADeclaration: string): string;
begin
  Result := StringReplace(ADeclaration, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  Result := Trim(Result);
end;

function SpecializeTypeText(ASpecialize: TPasSpecializeType;
  AIncludeAliasName: Boolean): string; forward;

function TypeReferenceText(AType: TPasType): string;
begin
  if not Assigned(AType) then
    Exit('');
  if AType is TPasSpecializeType then
    Result := SpecializeTypeText(TPasSpecializeType(AType), False)
  else if AType.Name <> '' then
    Result := AType.SafeName
  else
    Result := AType.GetDeclaration(False);
end;

function ClassDeclaration(AClass: TPasClassType): string;
var
  TypeName: string;
  Parents: TStringList;
  I: Integer;
  ReferenceText: string;
begin
  TypeName := AClass.SafeName;
  if Assigned(AClass.GenericTemplateTypes) and
    (AClass.GenericTemplateTypes.Count > 0) then
    TypeName := TypeName +
      GenericTemplateTypesAsString(AClass.GenericTemplateTypes);

  Result := TypeName + ' = ' + ObjKindNames[AClass.ObjKind];
  if AClass.ObjKind in okAllHelpers then
  begin
    ReferenceText := TypeReferenceText(AClass.HelperForType);
    if ReferenceText <> '' then
      Result := Result + ' for ' + ReferenceText;
  end
  else
  begin
    Parents := TStringList.Create;
    try
      ReferenceText := TypeReferenceText(AClass.AncestorType);
      if ReferenceText <> '' then
        Parents.Add(ReferenceText);
      for I := 0 to AClass.Interfaces.Count - 1 do
      begin
        ReferenceText := TypeReferenceText(
          TPasType(AClass.Interfaces[I]));
        if ReferenceText <> '' then
          Parents.Add(ReferenceText);
      end;
      if Parents.Count > 0 then
      begin
        Result := Result + '(';
        for I := 0 to Parents.Count - 1 do
        begin
          if I > 0 then
            Result := Result + ', ';
          Result := Result + Parents[I];
        end;
        Result := Result + ')';
      end;
    finally
      Parents.Free;
    end;
  end;
  Result := Result + #10 + 'end';
end;

function RecordDeclaration(ARecord: TPasRecordType): string;
var
  TypeName: string;
  RecordKeyword: string;
begin
  TypeName := ARecord.SafeName;
  if Assigned(ARecord.GenericTemplateTypes) and
    (ARecord.GenericTemplateTypes.Count > 0) then
    TypeName := TypeName +
      GenericTemplateTypesAsString(ARecord.GenericTemplateTypes);
  RecordKeyword := 'record';
  if ARecord.IsPacked then
    if ARecord.IsBitPacked then
      RecordKeyword := 'bitpacked record'
    else
      RecordKeyword := 'packed record';
  Result := TypeName + ' = ' + RecordKeyword + #10 + 'end';
end;

function SpecializeTypeText(ASpecialize: TPasSpecializeType;
  AIncludeAliasName: Boolean): string;
var
  I: Integer;
  Parameter: TPasElement;
  ParameterText: string;
begin
  Result := 'specialize ' + TypeReferenceText(ASpecialize.DestType) + '<';
  for I := 0 to ASpecialize.Params.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ', ';
    Parameter := TPasElement(ASpecialize.Params[I]);
    if Parameter is TPasType then
      ParameterText := TypeReferenceText(TPasType(Parameter))
    else
      ParameterText := Parameter.GetDeclaration(False);
    Result := Result + ParameterText;
  end;
  Result := Result + '>';
  if AIncludeAliasName and (ASpecialize.Name <> '') then
    Result := ASpecialize.SafeName + ' = ' + Result;
end;

function ArgumentDeclaration(AArgument: TPasArgument): string;
var
  ValueText: string;
begin
  Result := AccessNames[AArgument.Access];
  if AArgument.Name <> '' then
    Result := Result + AArgument.SafeName;
  if Assigned(AArgument.ArgType) then
    Result := Result + ': ' + TypeReferenceText(AArgument.ArgType);
  ValueText := AArgument.Value;
  if ValueText <> '' then
    Result := Result + ' = ' + ValueText;
end;

function ProcedureNameText(AProcedure: TPasProcedure): string;
var
  I: Integer;
  NamePart: TProcedureNamePart;
begin
  Result := '';
  if Assigned(AProcedure.NameParts) then
  begin
    for I := 0 to AProcedure.NameParts.Count - 1 do
    begin
      if I > 0 then
        Result := Result + '.';
      NamePart := TProcedureNamePart(AProcedure.NameParts[I]);
      Result := Result + NamePart.Name;
      if Assigned(NamePart.Templates) and (NamePart.Templates.Count > 0) then
        Result := Result + GenericTemplateTypesAsString(NamePart.Templates);
    end;
  end
  else
    Result := AProcedure.SafeName;
end;

function ProcedureDeclaration(AProcedure: TPasProcedure): string;
var
  I: Integer;
  Modifier: TProcedureModifier;
  ResultType: TPasType;
begin
  if AProcedure is TPasOperator then
    Result := TPasOperator(AProcedure).GetOperatorDeclaration(False)
  else
  begin
    Result := AProcedure.TypeName;
    if AProcedure.Name <> '' then
      Result := Result + ' ' + ProcedureNameText(AProcedure);
  end;

  if Assigned(AProcedure.ProcType) and
    (AProcedure.ProcType.Args.Count > 0) then
  begin
    Result := Result + '(';
    for I := 0 to AProcedure.ProcType.Args.Count - 1 do
    begin
      if I > 0 then
        Result := Result + '; ';
      Result := Result + ArgumentDeclaration(
        TPasArgument(AProcedure.ProcType.Args[I]));
    end;
    Result := Result + ')';
  end;

  if AProcedure is TPasFunction then
  begin
    ResultType := nil;
    if Assigned(TPasFunction(AProcedure).FuncType) and
      Assigned(TPasFunction(AProcedure).FuncType.ResultEl) then
      ResultType := TPasFunction(AProcedure).FuncType.ResultEl.ResultType;
    if Assigned(ResultType) then
      Result := Result + ': ' + TypeReferenceText(ResultType);
  end;

  if AProcedure.CallingConvention <> ccDefault then
    Result := Result + '; ' +
      cCallingConventions[AProcedure.CallingConvention];
  for Modifier := Low(TProcedureModifier) to High(TProcedureModifier) do
    if Modifier in AProcedure.Modifiers then
      Result := Result + '; ' + ModifierNames[Modifier];
end;

function PropertyDeclaration(AProperty: TPasProperty): string;
var
  I: Integer;
begin
  if AProperty.IsClass then
    Result := 'class property '
  else
    Result := 'property ';
  Result := Result + AProperty.SafeName;
  if Assigned(AProperty.Args) and (AProperty.Args.Count > 0) then
  begin
    Result := Result + '[';
    for I := 0 to AProperty.Args.Count - 1 do
    begin
      if I > 0 then
        Result := Result + '; ';
      Result := Result + ArgumentDeclaration(
        TPasArgument(AProperty.Args[I]));
    end;
    Result := Result + ']';
  end;
  if Assigned(AProperty.VarType) then
    Result := Result + ': ' + TypeReferenceText(AProperty.VarType);
  if AProperty.ReadAccessorName <> '' then
    Result := Result + ' read ' + AProperty.ReadAccessorName;
  if AProperty.WriteAccessorName <> '' then
    Result := Result + ' write ' + AProperty.WriteAccessorName;
  if AProperty.IsDefault then
    Result := Result + '; default';
end;

function AngleBracketsBalanced(const AText: string): Boolean;
var
  I: Integer;
  Balance: Integer;
begin
  Balance := 0;
  for I := 1 to Length(AText) do
    if AText[I] = '<' then
      Inc(Balance)
    else if AText[I] = '>' then
      Dec(Balance);
  Result := Balance = 0;
end;

function VisibilityOf(AElement: TPasElement): TSymbolVisibility;
var
  Ancestor: TPasElement;
begin
  case AElement.Visibility of
    visPrivate: Result := svPrivate;
    visProtected: Result := svProtected;
    visPublic: Result := svPublic;
    visPublished: Result := svPublished;
    visAutomated: Result := svAutomated;
    visStrictPrivate: Result := svStrictPrivate;
    visStrictProtected: Result := svStrictProtected;
  else
  begin
    Ancestor := AElement.Parent;
    while Assigned(Ancestor) and not (Ancestor is TInterfaceSection) and
      not (Ancestor is TPasMembersType) do
      Ancestor := Ancestor.Parent;
    if (Ancestor is TInterfaceSection) or
       ((Ancestor is TPasClassType) and
        (TPasClassType(Ancestor).ObjKind = okInterface)) then
      Result := svPublic
    else
      Result := svDefault;
  end;
end;
end;

function KindOf(AElement: TPasElement; out AKind: TSymbolKind): Boolean;
begin
  Result := True;
  if AElement is TPasModule then
    AKind := skUnit
  else if AElement is TPasConstructor then
    AKind := skConstructor
  else if AElement is TPasDestructor then
    AKind := skDestructor
  else if AElement is TPasProcedure then
  begin
    if AElement.Parent is TPasMembersType then
      AKind := skMethod
    else
      AKind := skRoutine;
  end
  else if AElement is TPasProperty then
    AKind := skProperty
  else if AElement is TPasConst then
    AKind := skConstant
  else if AElement is TPasVariable then
  begin
    if AElement.Parent is TPasMembersType then
      AKind := skField
    else
      AKind := skVariable;
  end
  else if AElement is TPasEnumType then
    AKind := skEnumeration
  else if AElement is TPasRecordType then
    AKind := skRecord
  else if AElement is TPasClassType then
  begin
    if TPasClassType(AElement).ObjKind in [okInterface, okDispInterface] then
      AKind := skInterface
    else
      AKind := skClass;
  end
  else if AElement is TPasType then
    AKind := skTypeAlias
  else
    Result := False;
end;

function StableSymbolID(AKind: TSymbolKind; const AQualifiedName,
  ADeclaration: string): string;
begin
  Result := SymbolKindName(AKind) + ':' + LowerCase(AQualifiedName);
  if AKind in [skRoutine, skMethod, skConstructor, skDestructor, skProperty] then
    Result := Result + '#' + CanonicalText(ADeclaration);
end;

function ElementDeclaration(AElement: TPasElement): string;
var
  ParserDeclaration: string;
begin
  try
    if AElement is TPasClassType then
      Result := NormaliseDeclaration(
        ClassDeclaration(TPasClassType(AElement)))
    else if AElement is TPasRecordType then
      Result := NormaliseDeclaration(
        RecordDeclaration(TPasRecordType(AElement)))
    else if AElement is TPasSpecializeType then
      Result := NormaliseDeclaration(
        SpecializeTypeText(TPasSpecializeType(AElement), True))
    else
    begin
      ParserDeclaration := NormaliseDeclaration(
        AElement.GetDeclaration(True));
      if not AngleBracketsBalanced(ParserDeclaration) and
        (AElement is TPasProcedure) then
        Result := NormaliseDeclaration(
          ProcedureDeclaration(TPasProcedure(AElement)))
      else if not AngleBracketsBalanced(ParserDeclaration) and
        (AElement is TPasProperty) then
        Result := NormaliseDeclaration(
          PropertyDeclaration(TPasProperty(AElement)))
      else
        Result := ParserDeclaration;
    end;
  except
    Result := '';
  end;
end;

procedure AddElementSymbols(AElement: TPasElement; AUnit: TDocUnit;
  AEngine: TPasWeaveTreeContainer; const ASourceRoot, ADefaultFilename,
  AParentSymbolID, AParentQualifiedName, ASourceText: string;
  ACommentStyles: TDocumentationCommentStyles);
var
  Kind: TSymbolKind;
  Symbol: TDocSymbol;
  QualifiedName: string;
  DeclarationText: string;
  I: Integer;
  Members: TFPList;
begin
  if AElement is TPasOverloadedProc then
  begin
    for I := 0 to TPasOverloadedProc(AElement).Overloads.Count - 1 do
      AddElementSymbols(TPasElement(TPasOverloadedProc(AElement).Overloads[I]),
        AUnit, AEngine, ASourceRoot, ADefaultFilename, AParentSymbolID,
        AParentQualifiedName, ASourceText, ACommentStyles);
    Exit;
  end;

  if not KindOf(AElement, Kind) then
    Exit;

  if AParentQualifiedName = '' then
    QualifiedName := AElement.Name
  else if Kind = skUnit then
    QualifiedName := AElement.Name
  else
    QualifiedName := AParentQualifiedName + '.' + AElement.Name;

  DeclarationText := ElementDeclaration(AElement);
  Symbol := TDocSymbol.Create;
  try
    Symbol.Name := AElement.Name;
    Symbol.QualifiedName := QualifiedName;
    Symbol.Kind := Kind;
    Symbol.Visibility := VisibilityOf(AElement);
    Symbol.DeclarationText := DeclarationText;
    if AElement.SourceFilename <> '' then
      Symbol.SourceFilename := RelativeSourceFilename(
        AElement.SourceFilename, ASourceRoot)
    else
      Symbol.SourceFilename := ADefaultFilename;
    Symbol.SourceLine := AElement.SourceLinenumber;
    Symbol.SourceColumn := ElementColumn(AElement);
    if SameText(Symbol.SourceFilename, ADefaultFilename) then
      ParseDocumentationComment(ASourceText, AElement.SourceLinenumber,
        ACommentStyles, Symbol.RawDocumentation,
        Symbol.MarkdownDocumentation, Symbol.Directives);
    Symbol.ParentSymbolID := AParentSymbolID;
    Symbol.ID := StableSymbolID(Kind, QualifiedName, DeclarationText);
    AUnit.Symbols.Add(Symbol);
  except
    Symbol.Free;
    raise;
  end;

  if AElement is TPasMembersType then
  begin
    Members := TPasMembersType(AElement).Members;
    for I := 0 to Members.Count - 1 do
      AddElementSymbols(TPasElement(Members[I]), AUnit, AEngine, ASourceRoot,
        ADefaultFilename, Symbol.ID, Symbol.QualifiedName, ASourceText,
        ACommentStyles);
  end;
end;

function ConvertModule(AModule: TPasModule; AEngine: TPasWeaveTreeContainer;
  const AFileName, ASourceRoot, ASourceText: string;
  ACommentStyles: TDocumentationCommentStyles): TDocUnit;
var
  I: Integer;
  UnitSymbol: TDocSymbol;
  DefaultFilename: string;
begin
  Result := TDocUnit.Create;
  try
    Result.Name := AModule.Name;
    DefaultFilename := RelativeSourceFilename(AFileName, ASourceRoot);
    Result.SourceFilename := DefaultFilename;

    if Assigned(AModule.InterfaceSection) then
    begin
      for I := 0 to Length(AModule.InterfaceSection.UsesClause) - 1 do
        if not SameText(AModule.InterfaceSection.UsesClause[I].Name,
          'System') then
          Result.InterfaceDependencies.Add(
            AModule.InterfaceSection.UsesClause[I].Name);
    end;

    AddElementSymbols(AModule, Result, AEngine, ASourceRoot,
      DefaultFilename, '', '', ASourceText, ACommentStyles);
    UnitSymbol := TDocSymbol(Result.Symbols[Result.Symbols.Count - 1]);

    if Assigned(AModule.InterfaceSection) then
      for I := 0 to AModule.InterfaceSection.Declarations.Count - 1 do
        AddElementSymbols(
          TPasElement(AModule.InterfaceSection.Declarations[I]),
          Result, AEngine, ASourceRoot, DefaultFilename,
          UnitSymbol.ID, AModule.Name, ASourceText, ACommentStyles);
  except
    Result.Free;
    raise;
  end;
end;

function ParseUnitFile(const AFileName, ASourceRoot: string;
  ACommentStyles: TDocumentationCommentStyles;
  out AUnit: TDocUnit; out ADiagnostic: TDiagnostic): Boolean;
var
  Engine: TPasWeaveTreeContainer;
  Module: TPasModule;
  Arguments: array[0..1] of string;
  DisplayFilename: string;
  ModuleClassName: string;
  SourceText: string;
begin
  Result := False;
  AUnit := nil;
  ADiagnostic := nil;
  Engine := TPasWeaveTreeContainer.Create;
  Module := nil;
  DisplayFilename := RelativeSourceFilename(AFileName, ASourceRoot);
  try
    Arguments[0] := '-Mobjfpc';
    Arguments[1] := ExpandFileName(AFileName);
    try
      SourceText := ReadSourceText(AFileName);
      Module := ParseSource(Engine, Arguments,
        {$I %FPCTARGETOS%}, {$I %FPCTARGETCPU%}, []);
      if not Assigned(Module) or not Assigned(Module.InterfaceSection) then
      begin
        if Assigned(Module) then
          ModuleClassName := Module.ClassName
        else
          ModuleClassName := '<nil>';
        ADiagnostic := TDiagnostic.Create(dsError, DisplayFilename, 1, 1,
          'source is not a Pascal unit',
          'adapter=fcl-passrc; interfaceOnly=true; moduleClass=' +
          ModuleClassName);
        Exit;
      end;
      AUnit := ConvertModule(Module, Engine, AFileName, ASourceRoot,
        SourceText, ACommentStyles);
      Result := True;
    except
      on E: EParserError do
        ADiagnostic := TDiagnostic.Create(dsError, DisplayFilename,
          E.Row, E.Column,
          CleanParserMessage(E.Message, E.Filename, DisplayFilename),
          'exception=' + E.ClassName +
          '; adapter=fcl-passrc; interfaceOnly=true');
      on E: Exception do
        ADiagnostic := TDiagnostic.Create(dsError, DisplayFilename,
          0, 0, E.Message, 'exception=' + E.ClassName +
          '; adapter=fcl-passrc; interfaceOnly=true');
    end;
  finally
    Module.Free;
    Engine.Free;
    if not Result then
      FreeAndNil(AUnit);
  end;
end;

end.
