unit PasWeave.FPCAdapter;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Comments, PasWeave.Compiler, PasWeave.Diagnostics, PasWeave.Model;

function ParseUnitFile(const AFileName, ASourceRoot: string;
  ACommentStyles: TDocumentationCommentStyles;
  ACompilerOptions: TCompilerOptions;
  out AUnit: TDocUnit; out ADiagnostic: TDiagnostic): Boolean;

implementation

uses
  Classes, Contnrs, SysUtils, PParser, PScanner, PasTree,
  PasWeave.FPCAdapter.Symbols, PasWeave.FS;

type

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

function StableParserMessage(const AMessage, AParserFilename,
  ADisplayFilename: string; AConfiguredBuild: Boolean): string;
var
  FirstQuote: Integer;
  SecondQuote: Integer;
  IncludeName: string;
begin
  Result := CleanParserMessage(AMessage, AParserFilename,
    ADisplayFilename);
  if not AConfiguredBuild or
    (Pos('Could not find include file', Result) = 0) then
    Exit;

  FirstQuote := Pos('''', Result);
  SecondQuote := Pos('''', Copy(Result, FirstQuote + 1, MaxInt));
  if (FirstQuote > 0) and (SecondQuote > 0) then
  begin
    Inc(SecondQuote, FirstQuote);
    IncludeName := Copy(Result, FirstQuote + 1,
      SecondQuote - FirstQuote - 1);
    Result := 'include file is missing or unreadable: ' + IncludeName;
  end
  else
    Result := 'include file is missing or unreadable';
end;


function ParseUnitFile(const AFileName, ASourceRoot: string;
  ACommentStyles: TDocumentationCommentStyles;
  ACompilerOptions: TCompilerOptions;
  out AUnit: TDocUnit; out ADiagnostic: TDiagnostic): Boolean;
var
  Engine: TPasWeaveTreeContainer;
  Module: TPasModule;
  ArgumentList: TStringList;
  Arguments: array of string;
  DisplayFilename: string;
  ModuleClassName: string;
  SourceText: string;
  ErrorFilename: string;
  DiagnosticDetails: string;
  I: Integer;
begin
  Result := False;
  AUnit := nil;
  ADiagnostic := nil;
  Engine := TPasWeaveTreeContainer.Create;
  ArgumentList := TStringList.Create;
  Module := nil;
  DisplayFilename := RelativeSourceFilename(AFileName, ASourceRoot);
  DiagnosticDetails := 'adapter=fcl-passrc; interfaceOnly=true';
  if ACompilerOptions.HasExplicitSettings then
    DiagnosticDetails := DiagnosticDetails + '; targetOS=' +
      ACompilerOptions.TargetOS + '; targetCPU=' +
      ACompilerOptions.TargetCPU;
  try
    ArgumentList.Add('-Mobjfpc');
    if Assigned(ACompilerOptions) and ACompilerOptions.HasExplicitSettings then
      ACompilerOptions.AppendParserArguments(ArgumentList);
    ArgumentList.Add(ExpandFileName(AFileName));
    SetLength(Arguments, ArgumentList.Count);
    for I := 0 to ArgumentList.Count - 1 do
      Arguments[I] := ArgumentList[I];
    try
      SourceText := ReadSourceText(AFileName);
      Module := ParseSource(Engine, Arguments,
        ACompilerOptions.TargetOS, ACompilerOptions.TargetCPU, []);
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
      AUnit := ConvertModule(Module, AFileName, ASourceRoot,
        SourceText, ACommentStyles,
        ACompilerOptions.IncludePaths.Count > 0);
      Result := True;
    except
      on E: EParserError do
      begin
        if not ACompilerOptions.HasExplicitSettings then
          ErrorFilename := DisplayFilename
        else if (E.Filename = '') or SameText(ExpandFileName(E.Filename),
          ExpandFileName(AFileName)) then
          ErrorFilename := DisplayFilename
        else if FileExists(E.Filename) then
          ErrorFilename := RelativeSourceFilename(E.Filename, ASourceRoot)
        else
          ErrorFilename := NormalisePath(E.Filename);
        ADiagnostic := TDiagnostic.Create(dsError, ErrorFilename,
          E.Row, E.Column, StableParserMessage(E.Message, E.Filename,
          ErrorFilename, ACompilerOptions.HasExplicitSettings),
          'exception=' + E.ClassName + '; ' + DiagnosticDetails);
      end;
      on E: EFileNotFoundError do
        if ACompilerOptions.HasExplicitSettings then
          ADiagnostic := TDiagnostic.Create(dsError, DisplayFilename,
            0, 0, 'cannot read source or include file: ' +
            NormalisePath(E.Message), 'exception=' + E.ClassName +
            '; ' + DiagnosticDetails)
        else
          ADiagnostic := TDiagnostic.Create(dsError, DisplayFilename,
            0, 0, E.Message, 'exception=' + E.ClassName + '; ' +
            DiagnosticDetails);
      on E: Exception do
        ADiagnostic := TDiagnostic.Create(dsError, DisplayFilename,
          0, 0, E.Message, 'exception=' + E.ClassName + '; ' +
          DiagnosticDetails);
    end;
  finally
    Module.Free;
    ArgumentList.Free;
    Engine.Free;
    if not Result then
      FreeAndNil(AUnit);
  end;
end;

end.
