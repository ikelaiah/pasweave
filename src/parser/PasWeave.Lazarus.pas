unit PasWeave.Lazarus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, PasWeave.Compiler, PasWeave.FS,
  PasWeave.Lazarus.Support;

type

  TLazarusConfiguration = class
  private
    FCompilerOptions: TCompilerOptions;
    FMainUnits: TStringList;
    FPackageFiles: TStringList;
    FProjectName: string;
    FSourceFiles: TStringList;
    FSourceRoot: string;
  public
    constructor Create;
    destructor Destroy; override;
    property CompilerOptions: TCompilerOptions read FCompilerOptions;
    property MainUnits: TStringList read FMainUnits;
    property PackageFiles: TStringList read FPackageFiles;
    property ProjectName: string read FProjectName write FProjectName;
    property SourceFiles: TStringList read FSourceFiles;
    property SourceRoot: string read FSourceRoot write FSourceRoot;
  end;

function LoadLazarusConfiguration(const AInputPath, ABuildMode: string;
  APackagePaths: TStrings): TLazarusConfiguration;

implementation

uses
  Contnrs, DOM, XMLRead;

type
  TRequiredPackage = class
  public
    Filename: string;
    Name: string;
  end;

  TPackageInfo = class
  public
    CompilerOptions: TCompilerOptions;
    Filename: string;
    Name: string;
    RequiredPackages: TObjectList;
    SourceFiles: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

procedure AddUnique(AList: TStringList; const AValue: string);
begin
  if (AValue <> '') and (AList.IndexOf(AValue) < 0) then
    AList.Add(AValue);
end;

procedure AddSourceFile(AList: TStringList; const ABaseDirectory,
  AValue, ADescription: string);
var
  Filename: string;
begin
  if not IsPascalSourceFile(AValue) then
    Exit;
  Filename := ResolvePath(ABaseDirectory, AValue);
  if not FileExists(Filename) then
    raise ELazarusConfigurationError.CreateFmt(
      'Lazarus %s source file does not exist: %s',
      [ADescription, NormalisePath(AValue)]);
  AddUnique(AList, Filename);
end;

procedure CollectProjectUnits(ANode: TDOMNode; const ABaseDirectory: string;
  AConfiguration: TLazarusConfiguration);
var
  UnitNode: TDOMNode;
  Filename: string;
begin
  if not Assigned(ANode) then
    Exit;
  UnitNode := ANode.FirstChild;
  while Assigned(UnitNode) do
  begin
    if SameText(UnitNode.NodeName, 'Unit') then
    begin
      Filename := NodeValue(UnitNode, 'Filename');
      if IsPascalSourceFile(Filename) and
        ((AttributeValue(UnitNode, 'IsPartOfProject') = '') or
        IsTrueValue(AttributeValue(UnitNode, 'IsPartOfProject'))) then
      begin
        AddSourceFile(AConfiguration.SourceFiles, ABaseDirectory, Filename,
          'project');
        AddUnique(AConfiguration.MainUnits,
          ResolvePath(ABaseDirectory, Filename));
      end;
    end;
    UnitNode := UnitNode.NextSibling;
  end;
end;

procedure CollectRequiredPackages(ANode: TDOMNode; APackages: TObjectList);
var
  Item: TDOMNode;
  Required: TRequiredPackage;
begin
  if not Assigned(ANode) then
    Exit;
  Item := ANode.FirstChild;
  while Assigned(Item) do
  begin
    if SameText(Item.NodeName, 'Item') then
    begin
      Required := TRequiredPackage.Create;
      Required.Name := Trim(NodeValue(Item, 'PackageName'));
      Required.Filename := Trim(NodeValue(Item, 'Filename'));
      if Required.Filename = '' then
        Required.Filename := Trim(NodeValue(Item, 'DefaultFilename'));
      if Required.Name = '' then
      begin
        Required.Free;
        raise ELazarusConfigurationError.Create(
          'Lazarus package reference is missing PackageName');
      end;
      APackages.Add(Required);
    end;
    Item := Item.NextSibling;
  end;
end;

constructor TLazarusConfiguration.Create;
begin
  inherited Create;
  FCompilerOptions := TCompilerOptions.Create;
  FMainUnits := TStringList.Create;
  FPackageFiles := TStringList.Create;
  FSourceFiles := TStringList.Create;
  FMainUnits.CaseSensitive := False;
  FMainUnits.Duplicates := dupIgnore;
  FMainUnits.Sorted := True;
  FPackageFiles.CaseSensitive := False;
  FPackageFiles.Duplicates := dupIgnore;
  FPackageFiles.Sorted := True;
  FSourceFiles.CaseSensitive := False;
  FSourceFiles.Duplicates := dupIgnore;
  FSourceFiles.Sorted := True;
end;

destructor TLazarusConfiguration.Destroy;
begin
  FSourceFiles.Free;
  FPackageFiles.Free;
  FMainUnits.Free;
  FCompilerOptions.Free;
  inherited Destroy;
end;

constructor TPackageInfo.Create;
begin
  inherited Create;
  CompilerOptions := TCompilerOptions.Create;
  RequiredPackages := TObjectList.Create(True);
  SourceFiles := TStringList.Create;
  SourceFiles.CaseSensitive := False;
  SourceFiles.Duplicates := dupIgnore;
end;

destructor TPackageInfo.Destroy;
begin
  SourceFiles.Free;
  RequiredPackages.Free;
  CompilerOptions.Free;
  inherited Destroy;
end;

function ReadXMLDocument(const AFilename: string): TXMLDocument;
begin
  Result := nil;
  try
    ReadXMLFile(Result, AFilename);
  except
    on E: Exception do
      raise ELazarusConfigurationError.CreateFmt(
        'cannot read Lazarus configuration %s: %s', [AFilename, E.Message]);
  end;
end;

function SelectBuildMode(ABuildModes: TDOMNode; const ABuildMode: string): TDOMNode;
var
  Item: TDOMNode;
  Candidate: TDOMNode;
  DefaultCount: Integer;
  ModeCount: Integer;
  FirstMode: TDOMNode;
  MatchingCount: Integer;
begin
  Result := nil;
  if not Assigned(ABuildModes) then
  begin
    if ABuildMode <> '' then
      raise ELazarusConfigurationError.CreateFmt(
        'Lazarus build mode is not available: %s', [ABuildMode]);
    Exit;
  end;
  Candidate := nil;
  DefaultCount := 0;
  ModeCount := 0;
  FirstMode := nil;
  MatchingCount := 0;
  Item := ABuildModes.FirstChild;
  while Assigned(Item) do
  begin
    if SameText(Item.NodeName, 'Item') then
    begin
      Inc(ModeCount);
      if not Assigned(FirstMode) then
        FirstMode := Item;
      if (ABuildMode <> '') and SameText(AttributeValue(Item, 'Name'),
        ABuildMode) then
      begin
        Candidate := Item;
        Inc(MatchingCount);
      end;
      if IsTrueValue(AttributeValue(Item, 'Default')) then
      begin
        Inc(DefaultCount);
        if ABuildMode = '' then
          Candidate := Item;
      end;
    end;
    Item := Item.NextSibling;
  end;
  if ABuildMode <> '' then
  begin
    if MatchingCount > 1 then
      raise ELazarusConfigurationError.CreateFmt(
        'ambiguous Lazarus build mode: %s is declared more than once',
        [ABuildMode]);
    if not Assigned(Candidate) then
      raise ELazarusConfigurationError.CreateFmt(
        'unknown Lazarus build mode: %s', [ABuildMode]);
    Exit(Candidate);
  end;
  if DefaultCount > 1 then
    raise ELazarusConfigurationError.Create(
      'ambiguous Lazarus build mode: more than one default is declared');
  if Assigned(Candidate) then
    Exit(Candidate);
  if ModeCount = 1 then
    Exit(FirstMode);
  if ModeCount > 1 then
    raise ELazarusConfigurationError.Create(
      'ambiguous Lazarus build mode: specify --build-mode');
end;

procedure ParsePackageDocument(const AFilename: string; ADocument: TXMLDocument;
  AInfo: TPackageInfo);
var
  Root: TDOMNode;
  PackageNode: TDOMNode;
  FilesNode: TDOMNode;
  UsageOptions: TDOMNode;
  Item: TDOMNode;
  Filename: string;
  Generated: Boolean;
begin
  Root := ADocument.DocumentElement;
  PackageNode := ChildNode(Root, 'Package');
  if not Assigned(PackageNode) then
    raise ELazarusConfigurationError.CreateFmt(
      'Lazarus package has no Package element: %s', [AFilename]);
  AInfo.Filename := AFilename;
  AInfo.Name := Trim(NodeValue(PackageNode, 'Name'));
  if AInfo.Name = '' then
    AInfo.Name := DefaultName(AFilename);
  ParseCompilerOptions(ChildNode(PackageNode, 'CompilerOptions'),
    ExtractFileDir(AFilename), AInfo.CompilerOptions);
  UsageOptions := ChildNode(PackageNode, 'UsageOptions');
  if Assigned(UsageOptions) then
    AddConfiguredPath(NodeValue(UsageOptions, 'UnitPath'),
      ExtractFileDir(AFilename), AInfo.CompilerOptions, False);
  FilesNode := ChildNode(PackageNode, 'Files');
  if Assigned(FilesNode) then
  begin
    Item := FilesNode.FirstChild;
    while Assigned(Item) do
    begin
      if SameText(Item.NodeName, 'Item') then
      begin
        Filename := NodeValue(Item, 'Filename');
        if Pos('$(', Filename) > 0 then
        begin
          Filename := ExpandConfiguredValue(Filename,
            ExtractFileDir(AFilename), AInfo.CompilerOptions, Generated);
          if Generated then
            Filename := '';
        end;
        AddSourceFile(AInfo.SourceFiles, ExtractFileDir(AFilename), Filename,
          'package');
      end;
      Item := Item.NextSibling;
    end;
  end;
  CollectRequiredPackages(ChildNode(PackageNode, 'RequiredPkgs'),
    AInfo.RequiredPackages);
end;

function PackageDirectoryExcluded(const AName: string): Boolean;
var
  Value: string;
begin
  Value := LowerCase(AName);
  Result := (Value = 'generated') or (Value = 'vendor') or
    (Value = 'vendored') or (Value = 'example') or (Value = 'examples') or
    (Value = 'test') or (Value = 'tests') or (Value = 'build') or
    (Value = 'dist') or (Value = 'lib') or (Value = 'obj') or
    (Value = '.git');
end;

procedure ScanPackageFiles(const ARoot, ARelative: string;
  AAllowExcluded: Boolean; AFiles: TStrings);
var
  Current: string;
  Relative: string;
  Search: TSearchRec;
begin
  Current := ARoot;
  if ARelative <> '' then
    Current := IncludeTrailingPathDelimiter(Current) +
      StringReplace(ARelative, '/', PathDelim, [rfReplaceAll]);
  if FindFirst(IncludeTrailingPathDelimiter(Current) + '*', faAnyFile,
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
      begin
        if AAllowExcluded or not PackageDirectoryExcluded(Search.Name) then
          ScanPackageFiles(ARoot, Relative, AAllowExcluded, AFiles);
      end
      else if SameText(ExtractFileExt(Search.Name), '.lpk') then
        AFiles.Add(ExpandFileName(IncludeTrailingPathDelimiter(Current) +
          Search.Name));
    until FindNext(Search) <> 0;
  finally
    FindClose(Search);
  end;
end;

function FindPackageFile(const AName: string; AIndexedFiles: TStrings): string;
var
  Candidates: TStringList;
  I: Integer;
  BaseName: string;
  Document: TXMLDocument;
  PackageNode: TDOMNode;
  DeclaredName: string;
begin
  Result := '';
  Candidates := TStringList.Create;
  try
    Candidates.CaseSensitive := False;
    Candidates.Duplicates := dupIgnore;
    for I := 0 to AIndexedFiles.Count - 1 do
    begin
      BaseName := ChangeFileExt(ExtractFileName(AIndexedFiles[I]), '');
      if SameText(BaseName, AName) then
        Candidates.Add(AIndexedFiles[I]);
    end;
    if Candidates.Count = 0 then
      for I := 0 to AIndexedFiles.Count - 1 do
      begin
        Document := nil;
        try
          try
            Document := ReadXMLDocument(AIndexedFiles[I]);
            PackageNode := ChildNode(Document.DocumentElement, 'Package');
            DeclaredName := NodeValue(PackageNode, 'Name');
            if SameText(DeclaredName, AName) then
              Candidates.Add(AIndexedFiles[I]);
          except
            on E: ELazarusConfigurationError do
              Continue;
          end;
        finally
          Document.Free;
        end;
      end;
    if Candidates.Count = 0 then
      raise ELazarusConfigurationError.CreateFmt(
        'referenced Lazarus package file is missing: %s', [AName]);
    if Candidates.Count > 1 then
      raise ELazarusConfigurationError.CreateFmt(
        'ambiguous Lazarus package reference %s: %s',
        [AName, StringReplace(Candidates.CommaText, ',', ', ',
        [rfReplaceAll])]);
    Result := Candidates[0];
  finally
    Candidates.Free;
  end;
end;

procedure AddPackageSources(AConfiguration: TLazarusConfiguration;
  AInfo: TPackageInfo);
var
  I: Integer;
begin
  for I := 0 to AInfo.SourceFiles.Count - 1 do
    AddUnique(AConfiguration.SourceFiles, AInfo.SourceFiles[I]);
end;

procedure VisitPackage(const APackageFilename: string;
  AConfiguration: TLazarusConfiguration; AIndexedFiles,
  AVisiting, AVisited: TStrings; const AExpectedName: string);
var
  Document: TXMLDocument;
  Info: TPackageInfo;
  Required: TRequiredPackage;
  DependencyFilename: string;
  I: Integer;
begin
  if AVisited.IndexOf(APackageFilename) >= 0 then
    Exit;
  if AVisiting.IndexOf(APackageFilename) >= 0 then
    raise ELazarusConfigurationError.CreateFmt(
      'cyclic Lazarus package reference: %s', [NormalisePath(APackageFilename)]);
  AVisiting.Add(APackageFilename);
  Info := TPackageInfo.Create;
  try
    Document := ReadXMLDocument(APackageFilename);
    try
      ParsePackageDocument(APackageFilename, Document, Info);
    finally
      Document.Free;
    end;
    if (AExpectedName <> '') and not SameText(Info.Name, AExpectedName) then
      raise ELazarusConfigurationError.CreateFmt(
        'Lazarus package name does not match reference: expected %s, found %s',
        [AExpectedName, Info.Name]);
    AddUnique(AConfiguration.PackageFiles, APackageFilename);
    AddPackageSources(AConfiguration, Info);
    AConfiguration.CompilerOptions.AppendImported(Info.CompilerOptions);
    for I := 0 to Info.RequiredPackages.Count - 1 do
    begin
      Required := TRequiredPackage(Info.RequiredPackages[I]);
      if Required.Filename <> '' then
        DependencyFilename := ResolvePackageReference(
          ExtractFileDir(APackageFilename), Required.Filename,
          AConfiguration.CompilerOptions)
      else
        DependencyFilename := FindPackageFile(Required.Name, AIndexedFiles);
      if not FileExists(DependencyFilename) then
        raise ELazarusConfigurationError.CreateFmt(
          'referenced Lazarus package file does not exist: %s',
          [NormalisePath(DependencyFilename)]);
      VisitPackage(DependencyFilename, AConfiguration, AIndexedFiles,
        AVisiting, AVisited, Required.Name);
    end;
    AVisited.Add(APackageFilename);
  finally
    AVisiting.Delete(AVisiting.IndexOf(APackageFilename));
    Info.Free;
  end;
end;

function LoadLazarusConfiguration(const AInputPath, ABuildMode: string;
  APackagePaths: TStrings): TLazarusConfiguration;
var
  InputFilename: string;
  InputDirectory: string;
  Document: TXMLDocument;
  Root: TDOMNode;
  ProjectOptions: TDOMNode;
  ModeNode: TDOMNode;
  RequiredPackages: TObjectList;
  Required: TRequiredPackage;
  IndexedFiles: TStringList;
  PackagePaths: TStringList;
  Visiting: TStringList;
  Visited: TStringList;
  ValidationInfo: TPackageInfo;
  I: Integer;
  PackageFilename: string;
  Title: string;
  AutomaticPackageRootCount: Integer;
begin
  InputFilename := ExpandFileName(AInputPath);
  if not FileExists(InputFilename) then
    raise ELazarusConfigurationError.CreateFmt(
      'Lazarus project or package file does not exist: %s', [AInputPath]);
  if not SameText(ExtractFileExt(InputFilename), '.lpi') and
    not SameText(ExtractFileExt(InputFilename), '.lpk') then
    raise ELazarusConfigurationError.CreateFmt(
      'unsupported Lazarus input file: %s', [AInputPath]);

  Result := TLazarusConfiguration.Create;
  RequiredPackages := TObjectList.Create(True);
  IndexedFiles := TStringList.Create;
  PackagePaths := TStringList.Create;
  Visiting := TStringList.Create;
  Visited := TStringList.Create;
  try
    InputDirectory := ExtractFileDir(InputFilename);
    Result.SourceRoot := InputDirectory;
    try
      Document := ReadXMLDocument(InputFilename);
      try
        Root := Document.DocumentElement;
        if SameText(ExtractFileExt(InputFilename), '.lpi') then
        begin
          ProjectOptions := ChildNode(Root, 'ProjectOptions');
          if not Assigned(ProjectOptions) then
            raise ELazarusConfigurationError.CreateFmt(
              'Lazarus project has no ProjectOptions element: %s',
              [InputFilename]);
          Title := NodeValue(ChildNode(ProjectOptions, 'General'), 'Title');
          if Title = '' then
            Title := DefaultName(InputFilename);
          Result.ProjectName := Title;
          ParseCompilerOptions(ChildNode(Root, 'CompilerOptions'),
            InputDirectory, Result.CompilerOptions);
          ModeNode := SelectBuildMode(ChildNode(ProjectOptions, 'BuildModes'),
            ABuildMode);
          if Assigned(ModeNode) then
            ParseCompilerOptions(ChildNode(ModeNode, 'CompilerOptions'),
              InputDirectory, Result.CompilerOptions);
          CollectProjectUnits(ChildNode(ProjectOptions, 'Units'),
            InputDirectory, Result);
          CollectRequiredPackages(
            ChildNode(ProjectOptions, 'RequiredPackages'),
            RequiredPackages);
        end
        else
        begin
          ValidationInfo := TPackageInfo.Create;
          try
            ParsePackageDocument(InputFilename, Document, ValidationInfo);
            Result.ProjectName := ValidationInfo.Name;
          finally
            ValidationInfo.Free;
          end;
        end;
      finally
        Document.Free;
      end;

    PackagePaths.Add(InputDirectory);
    if SameText(ExtractFileExt(InputFilename), '.lpk') then
      AddUnique(PackagePaths, ExtractFileDir(InputDirectory));
    AutomaticPackageRootCount := PackagePaths.Count;
    if Assigned(APackagePaths) then
      for I := 0 to APackagePaths.Count - 1 do
        AddUnique(PackagePaths, NormalisePackagePath(APackagePaths[I]));
    for I := 0 to PackagePaths.Count - 1 do
      ScanPackageFiles(PackagePaths[I], '', I >= AutomaticPackageRootCount,
        IndexedFiles);
    IndexedFiles.Sort;

    if SameText(ExtractFileExt(InputFilename), '.lpk') then
    begin
      { The package was read above only to validate its XML. Re-read it into
        the normal graph path so its files and dependencies are imported. }
      VisitPackage(InputFilename, Result, IndexedFiles,
        Visiting, Visited, '');
    end
    else
      for I := 0 to RequiredPackages.Count - 1 do
      begin
        Required := TRequiredPackage(RequiredPackages[I]);
        if Required.Filename <> '' then
          PackageFilename := ResolvePackageReference(InputDirectory,
            Required.Filename, Result.CompilerOptions)
        else
          PackageFilename := FindPackageFile(Required.Name, IndexedFiles);
        if not FileExists(PackageFilename) then
          raise ELazarusConfigurationError.CreateFmt(
            'referenced Lazarus package file does not exist: %s',
            [NormalisePath(PackageFilename)]);
        VisitPackage(PackageFilename, Result, IndexedFiles,
          Visiting, Visited, Required.Name);
      end;
      if Result.SourceFiles.Count = 0 then
        raise ELazarusConfigurationError.CreateFmt(
          'Lazarus input contains no Pascal source units: %s', [AInputPath]);
    except
      Result.Free;
      Result := nil;
      raise;
    end;
  finally
    Visited.Free;
    Visiting.Free;
    PackagePaths.Free;
    IndexedFiles.Free;
    RequiredPackages.Free;
  end;
end;

end.
