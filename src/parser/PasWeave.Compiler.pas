unit PasWeave.Compiler;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  ECompilerConfigurationError = class(Exception);

  TCompilerOptions = class
  private
    FDefines: TStringList;
    FDefinesExplicit: Boolean;
    FIncludePaths: TStringList;
    FIncludePathsExplicit: Boolean;
    FTargetCPU: string;
    FTargetCPUExplicit: Boolean;
    FTargetOS: string;
    FTargetOSExplicit: Boolean;
    FUnitPaths: TStringList;
    FUnitPathsExplicit: Boolean;
    procedure AddPath(APaths: TStringList; const AValue,
      AOptionName: string);
    function GetHasExplicitSettings: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddDefine(const AValue: string);
    procedure AddIncludePath(const AValue: string);
    procedure AddUnitPath(const AValue: string);
    procedure AppendParserArguments(AArguments: TStrings);
    procedure AppendImported(const AOptions: TCompilerOptions);
    procedure ApplyDefaultsFrom(const AOptions: TCompilerOptions);
    procedure SetTargetCPU(const AValue: string);
    procedure SetTargetOS(const AValue: string);
    property Defines: TStringList read FDefines;
    property HasExplicitSettings: Boolean read GetHasExplicitSettings;
    property IncludePaths: TStringList read FIncludePaths;
    property TargetCPU: string read FTargetCPU;
    property TargetCPUExplicit: Boolean read FTargetCPUExplicit;
    property TargetOS: string read FTargetOS;
    property TargetOSExplicit: Boolean read FTargetOSExplicit;
    property UnitPaths: TStringList read FUnitPaths;
  end;

function IsValidConditionalDefine(const AValue: string): Boolean;
function TryNormaliseTargetCPU(const AValue: string;
  out ANormalised: string): Boolean;
function TryNormaliseTargetOS(const AValue: string;
  out ANormalised: string): Boolean;

implementation

procedure ConfigureOrderedList(AList: TStringList);
begin
  AList.CaseSensitive := False;
  AList.Duplicates := dupIgnore;
end;

function IsValidConditionalDefine(const AValue: string): Boolean;
var
  I: Integer;
begin
  Result := AValue <> '';
  if not Result then
    Exit;
  if not (AValue[1] in ['A'..'Z', 'a'..'z', '_']) then
    Exit(False);
  for I := 2 to Length(AValue) do
    if not (AValue[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      Exit(False);
end;

function TryNormaliseTargetOS(const AValue: string;
  out ANormalised: string): Boolean;
var
  Value: string;
begin
  Value := LowerCase(Trim(AValue));
  if (Value = 'windows32') or (Value = 'windows-32') then
    Value := 'win32'
  else if (Value = 'windows64') or (Value = 'windows-64') then
    Value := 'win64'
  else if (Value = 'macos') or (Value = 'macosx') then
    Value := 'darwin'
  else if Value = 'sunos' then
    Value := 'solaris';

  Result := (Value = 'aix') or (Value = 'amiga') or
    (Value = 'aros') or (Value = 'beos') or (Value = 'darwin') or
    (Value = 'dragonfly') or (Value = 'freebsd') or
    (Value = 'haiku') or (Value = 'linux') or (Value = 'morphos') or
    (Value = 'netbsd') or (Value = 'openbsd') or (Value = 'qnx') or
    (Value = 'solaris') or (Value = 'win32') or (Value = 'win64') or
    (Value = 'wince');
  if Result then
    ANormalised := Value
  else
    ANormalised := '';
end;

function TryNormaliseTargetCPU(const AValue: string;
  out ANormalised: string): Boolean;
var
  Value: string;
begin
  Value := LowerCase(Trim(AValue));
  if (Value = 'amd64') or (Value = 'x64') or (Value = 'x86-64') then
    Value := 'x86_64'
  else if (Value = 'x86') or (Value = 'x86-32') then
    Value := 'i386'
  else if Value = 'arm64' then
    Value := 'aarch64';

  Result := (Value = 'aarch64') or (Value = 'arm') or
    (Value = 'i386') or (Value = 'mips') or (Value = 'mipsel') or
    (Value = 'mips64') or (Value = 'mips64el') or
    (Value = 'powerpc') or (Value = 'powerpc64') or
    (Value = 'riscv32') or (Value = 'riscv64') or
    (Value = 'sparc') or (Value = 'sparc64') or
    (Value = 'wasm32') or (Value = 'x86_64');
  if Result then
    ANormalised := Value
  else
    ANormalised := '';
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

function NormaliseDirectoryPath(const AValue, AOptionName: string): string;
begin
  Result := Trim(AValue);
  if Result = '' then
    raise ECompilerConfigurationError.CreateFmt(
      '%s path must not be empty', [AOptionName]);
  Result := ExpandFileName(Result);
  if FileExists(Result) then
    raise ECompilerConfigurationError.CreateFmt(
      '%s path is not a directory: %s', [AOptionName, AValue]);
  if not DirectoryExists(Result) then
    raise ECompilerConfigurationError.CreateFmt(
      '%s path does not exist: %s', [AOptionName, AValue]);
  if not DirectoryIsReadable(Result) then
    raise ECompilerConfigurationError.CreateFmt(
      '%s path is not readable: %s', [AOptionName, AValue]);
  Result := ExcludeTrailingPathDelimiter(Result);
end;

function IsUnixTarget(const ATargetOS: string): Boolean;
begin
  Result := (ATargetOS = 'aix') or (ATargetOS = 'beos') or
    (ATargetOS = 'darwin') or (ATargetOS = 'dragonfly') or
    (ATargetOS = 'freebsd') or (ATargetOS = 'haiku') or
    (ATargetOS = 'linux') or (ATargetOS = 'netbsd') or
    (ATargetOS = 'openbsd') or (ATargetOS = 'qnx') or
    (ATargetOS = 'solaris');
end;

function IsBSDTarget(const ATargetOS: string): Boolean;
begin
  Result := (ATargetOS = 'dragonfly') or (ATargetOS = 'freebsd') or
    (ATargetOS = 'netbsd') or (ATargetOS = 'openbsd');
end;

function IsWindowsTarget(const ATargetOS: string): Boolean;
begin
  Result := (ATargetOS = 'win32') or (ATargetOS = 'win64') or
    (ATargetOS = 'wince');
end;

function Is64BitTarget(const ATargetCPU: string): Boolean;
begin
  Result := (ATargetCPU = 'aarch64') or (ATargetCPU = 'mips64') or
    (ATargetCPU = 'mips64el') or (ATargetCPU = 'powerpc64') or
    (ATargetCPU = 'riscv64') or (ATargetCPU = 'sparc64') or
    (ATargetCPU = 'x86_64');
end;

constructor TCompilerOptions.Create;
begin
  inherited Create;
  FDefines := TStringList.Create;
  FIncludePaths := TStringList.Create;
  FUnitPaths := TStringList.Create;
  ConfigureOrderedList(FDefines);
  ConfigureOrderedList(FIncludePaths);
  ConfigureOrderedList(FUnitPaths);
  if not TryNormaliseTargetOS({$I %FPCTARGETOS%}, FTargetOS) then
    FTargetOS := LowerCase({$I %FPCTARGETOS%});
  if not TryNormaliseTargetCPU({$I %FPCTARGETCPU%}, FTargetCPU) then
    FTargetCPU := LowerCase({$I %FPCTARGETCPU%});
end;

destructor TCompilerOptions.Destroy;
begin
  FUnitPaths.Free;
  FIncludePaths.Free;
  FDefines.Free;
  inherited Destroy;
end;

procedure TCompilerOptions.AddPath(APaths: TStringList; const AValue,
  AOptionName: string);
var
  Path: string;
begin
  Path := NormaliseDirectoryPath(AValue, AOptionName);
  if APaths.IndexOf(Path) < 0 then
    APaths.Add(Path);
end;

function TCompilerOptions.GetHasExplicitSettings: Boolean;
begin
  Result := FTargetCPUExplicit or FTargetOSExplicit or
    (FDefines.Count > 0) or (FIncludePaths.Count > 0) or
    (FUnitPaths.Count > 0);
end;

procedure TCompilerOptions.AddDefine(const AValue: string);
var
  Define: string;
begin
  Define := Trim(AValue);
  if not IsValidConditionalDefine(Define) then
    raise ECompilerConfigurationError.CreateFmt(
      'invalid conditional define: %s', [AValue]);
  Define := UpperCase(Define);
  FDefinesExplicit := True;
  if FDefines.IndexOf(Define) < 0 then
    FDefines.Add(Define);
end;

procedure TCompilerOptions.AddIncludePath(const AValue: string);
begin
  FIncludePathsExplicit := True;
  AddPath(FIncludePaths, AValue, 'include');
end;

procedure TCompilerOptions.AddUnitPath(const AValue: string);
begin
  FUnitPathsExplicit := True;
  AddPath(FUnitPaths, AValue, 'unit');
end;

procedure TCompilerOptions.AppendImported(const AOptions: TCompilerOptions);
var
  I: Integer;
begin
  if not Assigned(AOptions) then
    Exit;
  for I := 0 to AOptions.Defines.Count - 1 do
    if FDefines.IndexOf(AOptions.Defines[I]) < 0 then
      FDefines.Add(AOptions.Defines[I]);
  for I := 0 to AOptions.IncludePaths.Count - 1 do
    if FIncludePaths.IndexOf(AOptions.IncludePaths[I]) < 0 then
      FIncludePaths.Add(AOptions.IncludePaths[I]);
  for I := 0 to AOptions.UnitPaths.Count - 1 do
    if FUnitPaths.IndexOf(AOptions.UnitPaths[I]) < 0 then
      FUnitPaths.Add(AOptions.UnitPaths[I]);

  if not FTargetOSExplicit and AOptions.TargetOSExplicit then
    FTargetOS := AOptions.TargetOS;
  if not FTargetCPUExplicit and AOptions.TargetCPUExplicit then
    FTargetCPU := AOptions.TargetCPU;
end;

procedure TCompilerOptions.ApplyDefaultsFrom(const AOptions: TCompilerOptions);
begin
  if not Assigned(AOptions) then
    Exit;
  if not FDefinesExplicit then
    FDefines.Assign(AOptions.Defines);
  if not FIncludePathsExplicit then
    FIncludePaths.Assign(AOptions.IncludePaths);
  if not FUnitPathsExplicit then
    FUnitPaths.Assign(AOptions.UnitPaths);
  if not FTargetOSExplicit and AOptions.TargetOSExplicit then
    FTargetOS := AOptions.TargetOS;
  if not FTargetCPUExplicit and AOptions.TargetCPUExplicit then
    FTargetCPU := AOptions.TargetCPU;
end;

procedure TCompilerOptions.SetTargetCPU(const AValue: string);
begin
  if not TryNormaliseTargetCPU(AValue, FTargetCPU) then
    raise ECompilerConfigurationError.CreateFmt(
      'unsupported target CPU: %s', [AValue]);
  FTargetCPUExplicit := True;
end;

procedure TCompilerOptions.SetTargetOS(const AValue: string);
begin
  if not TryNormaliseTargetOS(AValue, FTargetOS) then
    raise ECompilerConfigurationError.CreateFmt(
      'unsupported target OS: %s', [AValue]);
  FTargetOSExplicit := True;
end;

procedure TCompilerOptions.AppendParserArguments(AArguments: TStrings);
var
  I: Integer;
begin
  for I := 0 to FIncludePaths.Count - 1 do
    AArguments.Add('-Fi' + FIncludePaths[I]);
  for I := 0 to FDefines.Count - 1 do
    AArguments.Add('-d' + FDefines[I]);

  if IsWindowsTarget(FTargetOS) then
  begin
    AArguments.Add('-dWINDOWS');
    AArguments.Add('-dMSWINDOWS');
  end;
  if IsUnixTarget(FTargetOS) then
    AArguments.Add('-dUNIX');
  if IsBSDTarget(FTargetOS) then
    AArguments.Add('-dBSD');
  if FTargetOS = 'solaris' then
    AArguments.Add('-dSOLARIS');

  if Is64BitTarget(FTargetCPU) then
  begin
    AArguments.Add('-uCPU32');
    AArguments.Add('-dCPU64');
  end
  else
  begin
    AArguments.Add('-uCPU64');
    AArguments.Add('-dCPU32');
  end;
end;

end.
