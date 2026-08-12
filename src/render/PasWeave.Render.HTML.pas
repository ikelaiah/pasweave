unit PasWeave.Render.HTML;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

function HTMLUnitFilename(AUnit: TDocUnit): string;
function HTMLSymbolAnchor(ASymbol: TDocSymbol): string;
function RenderMermaidDependencyGraph(AProject: TDocProject): UTF8String;
function RenderMermaidTypeRelationshipGraph(
  AProject: TDocProject): UTF8String;
function RenderHTMLIndex(AProject: TDocProject): UTF8String;
function RenderHTMLUnit(AProject: TDocProject; AUnit: TDocUnit): UTF8String;
function RenderHTMLSearchIndex(AProject: TDocProject): UTF8String;
procedure WriteHTMLDocumentation(AProject: TDocProject;
  const AOutputDirectory: string);

implementation

uses
  Classes, Contnrs, SysUtils, FPJSON, PasWeave.Diagnostics,
  PasWeave.Render.Support, PasWeave.Render.HTML.Markdown,
  PasWeave.Render.HTML.Assets, PasWeave.Render.Links, PasWeave.SourceLinks;

type
  TSymbolKinds = set of TSymbolKind;

  TRelationshipDiagramEdge = class
  public
    SourceUnit: TDocUnit;
    SourceSymbol: TDocSymbol;
    Relationship: TDocTypeRelationship;
    TargetUnit: TDocUnit;
    TargetSymbol: TDocSymbol;
    UnresolvedIndex: Integer;
  end;

const
  TypeKinds: TSymbolKinds = [
    skClass, skInterface, skRecord, skEnumeration, skTypeAlias
  ];
  RoutineKinds: TSymbolKinds = [skRoutine];
  MemberKinds: TSymbolKinds = [
    skMethod, skConstructor, skDestructor, skProperty, skField
  ];
  ValueKinds: TSymbolKinds = [skConstant, skVariable];
  AllKinds: TSymbolKinds = [
    skUnit, skClass, skInterface, skRecord, skEnumeration, skTypeAlias,
    skRoutine, skMethod, skConstructor, skDestructor, skProperty, skField,
    skConstant, skVariable
  ];

procedure AppendLine(var AOutput: UTF8String; const ALine: UTF8String = '');
begin
  AOutput := AOutput + ALine + #10;
end;

function HTMLUnitFilename(AUnit: TDocUnit): string;
begin
  Result := AUnit.Name + '.html';
end;

function HTMLSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := DocumentationSymbolAnchor(ASymbol);
end;

function SortedUnits(AProject: TDocProject): TStringList;
var
  I: Integer;
  UnitModel: TDocUnit;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    Result.AddObject(UnitModel.Name + #1 + UnitModel.SourceFilename, UnitModel);
  end;
end;

function FindUnitByName(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
end;

function SortedUnitIndex(AUnits: TStringList; AUnit: TDocUnit): Integer;
begin
  for Result := 0 to AUnits.Count - 1 do
    if AUnits.Objects[Result] = AUnit then
      Exit;
  Result := -1;
end;

function MermaidNodeID(AIndex: Integer): string;
begin
  Result := Format('unit%.4d', [AIndex + 1]);
end;

function EscapeMermaidString(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function RenderMermaidDependencyGraph(AProject: TDocProject): UTF8String;
var
  Units: TStringList;
  I: Integer;
  J: Integer;
  DependencyIndex: Integer;
  DependencyUnit: TDocUnit;
  UnitModel: TDocUnit;
begin
  Result := '';
  AppendLine(Result, 'flowchart LR');
  AppendLine(Result, '  accTitle: Unit dependency graph');
  AppendLine(Result, '  accDescr: Project units point to units imported by ' +
    'their interface uses clauses.');
  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      AppendLine(Result, '  ' + MermaidNodeID(I) + '["' +
        EscapeMermaidString(UnitModel.Name) + '"]');
    end;

    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      for J := 0 to UnitModel.InterfaceDependencies.Count - 1 do
      begin
        DependencyUnit := FindUnitByName(AProject,
          UnitModel.InterfaceDependencies[J]);
        if not Assigned(DependencyUnit) then
          Continue;
        DependencyIndex := SortedUnitIndex(Units, DependencyUnit);
        if DependencyIndex >= 0 then
          AppendLine(Result, '  ' + MermaidNodeID(I) + ' --> ' +
            MermaidNodeID(DependencyIndex));
      end;
    end;

    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      AppendLine(Result, '  click ' + MermaidNodeID(I) + ' "units/' +
        EscapeMermaidString(HTMLUnitFilename(UnitModel)) + '" "Open ' +
        EscapeMermaidString(UnitModel.Name) + ' documentation" _self');
    end;
  finally
    Units.Free;
  end;
end;

function IsDirectlyRenderable(ASymbol: TDocSymbol): Boolean;
begin
  Result := not (ASymbol.Visibility in [svPrivate, svStrictPrivate]);
end;

function IsEffectivelyRenderable(AUnit: TDocUnit;
  ASymbol: TDocSymbol): Boolean;
var
  ParentSymbol: TDocSymbol;
begin
  Result := IsDirectlyRenderable(ASymbol);
  ParentSymbol := ASymbol;
  while Result and (ParentSymbol.ParentSymbolID <> '') do
  begin
    ParentSymbol := FindSymbolByID(AUnit, ParentSymbol.ParentSymbolID);
    if not Assigned(ParentSymbol) then
      Break;
    Result := IsDirectlyRenderable(ParentSymbol);
  end;
end;

function IndexOfObject(AList: TStringList; AObject: TObject): Integer;
begin
  for Result := 0 to AList.Count - 1 do
    if AList.Objects[Result] = AObject then
      Exit;
  Result := -1;
end;

procedure AddRelationshipNode(ANodes: TStringList; ASymbol: TDocSymbol);
begin
  if IndexOfObject(ANodes, ASymbol) < 0 then
    ANodes.AddObject(ASymbol.QualifiedName + #1 + ASymbol.ID, ASymbol);
end;

function RelationshipEdgeKey(AEdge: TRelationshipDiagramEdge): string;
var
  TargetKey: string;
begin
  if Assigned(AEdge.TargetSymbol) then
    TargetKey := AEdge.TargetSymbol.QualifiedName + #1 +
      AEdge.TargetSymbol.ID
  else
    TargetKey := AEdge.Relationship.TargetName + #1 +
      AEdge.Relationship.DisplayName;
  Result := AEdge.SourceSymbol.QualifiedName + #1 +
    TypeRelationshipKindName(AEdge.Relationship.Kind) + #1 + TargetKey +
    #1 + AEdge.SourceSymbol.ID;
end;

procedure CollectRelationshipDiagram(AProject: TDocProject;
  AEdges: TObjectList; ASortedEdges, ANodes: TStringList);
var
  Edge: TRelationshipDiagramEdge;
  Relationship: TDocTypeRelationship;
  SourceSymbol: TDocSymbol;
  SourceUnit: TDocUnit;
  I: Integer;
  J: Integer;
  K: Integer;
begin
  for I := 0 to AProject.Units.Count - 1 do
  begin
    SourceUnit := TDocUnit(AProject.Units[I]);
    for J := 0 to SourceUnit.Symbols.Count - 1 do
    begin
      SourceSymbol := TDocSymbol(SourceUnit.Symbols[J]);
      if not (SourceSymbol.Kind in [skClass, skInterface]) or
        not IsEffectivelyRenderable(SourceUnit, SourceSymbol) then
        Continue;
      for K := 0 to SourceSymbol.TypeRelationships.Count - 1 do
      begin
        Relationship := TDocTypeRelationship(
          SourceSymbol.TypeRelationships[K]);
        Edge := TRelationshipDiagramEdge.Create;
        Edge.SourceUnit := SourceUnit;
        Edge.SourceSymbol := SourceSymbol;
        Edge.Relationship := Relationship;
        Edge.TargetSymbol := FindProjectSymbolByID(AProject,
          Relationship.TargetSymbolID, Edge.TargetUnit);
        if Assigned(Edge.TargetSymbol) and
          not IsEffectivelyRenderable(Edge.TargetUnit, Edge.TargetSymbol) then
        begin
          Edge.TargetSymbol := nil;
          Edge.TargetUnit := nil;
        end;
        AEdges.Add(Edge);
        ASortedEdges.AddObject(RelationshipEdgeKey(Edge), Edge);
        AddRelationshipNode(ANodes, SourceSymbol);
        if Assigned(Edge.TargetSymbol) then
          AddRelationshipNode(ANodes, Edge.TargetSymbol);
      end;
    end;
  end;
end;

function MermaidTypeNodeID(AIndex: Integer): string;
begin
  Result := Format('type%.4d', [AIndex + 1]);
end;

function MermaidUnresolvedNodeID(AIndex: Integer): string;
begin
  Result := Format('unresolved%.4d', [AIndex + 1]);
end;

function RenderMermaidTypeRelationshipGraph(
  AProject: TDocProject): UTF8String;
var
  Edge: TRelationshipDiagramEdge;
  Edges: TObjectList;
  Nodes: TStringList;
  SortedEdges: TStringList;
  Symbol: TDocSymbol;
  I: Integer;
  SourceIndex: Integer;
  TargetIndex: Integer;
  SymbolUnit: TDocUnit;
  UnresolvedCount: Integer;
  TargetNodeID: string;
begin
  Result := '';
  Edges := TObjectList.Create(True);
  Nodes := TStringList.Create;
  SortedEdges := TStringList.Create;
  try
    Nodes.Sorted := True;
    Nodes.CaseSensitive := True;
    Nodes.Duplicates := dupAccept;
    SortedEdges.Sorted := True;
    SortedEdges.CaseSensitive := True;
    SortedEdges.Duplicates := dupAccept;
    CollectRelationshipDiagram(AProject, Edges, SortedEdges, Nodes);
    if SortedEdges.Count = 0 then
      Exit;

    AppendLine(Result, 'flowchart BT');
    AppendLine(Result, '  accTitle: Class and interface relationships');
    AppendLine(Result, '  accDescr: Classes and interfaces point to their ' +
      'resolved ancestors and implemented interfaces.');
    for I := 0 to Nodes.Count - 1 do
    begin
      Symbol := TDocSymbol(Nodes.Objects[I]);
      AppendLine(Result, '  ' + MermaidTypeNodeID(I) + '["[' +
        EscapeMermaidString(SymbolKindName(Symbol.Kind)) + '] ' +
        EscapeMermaidString(Symbol.QualifiedName) + '"]');
    end;

    UnresolvedCount := 0;
    for I := 0 to SortedEdges.Count - 1 do
    begin
      Edge := TRelationshipDiagramEdge(SortedEdges.Objects[I]);
      if Assigned(Edge.TargetSymbol) then
        Continue;
      Edge.UnresolvedIndex := UnresolvedCount;
      AppendLine(Result, '  ' + MermaidUnresolvedNodeID(UnresolvedCount) +
        '["[unresolved] ' +
        EscapeMermaidString(Edge.Relationship.DisplayName) + '"]');
      Inc(UnresolvedCount);
    end;

    for I := 0 to SortedEdges.Count - 1 do
    begin
      Edge := TRelationshipDiagramEdge(SortedEdges.Objects[I]);
      SourceIndex := IndexOfObject(Nodes, Edge.SourceSymbol);
      if Assigned(Edge.TargetSymbol) then
      begin
        TargetIndex := IndexOfObject(Nodes, Edge.TargetSymbol);
        TargetNodeID := MermaidTypeNodeID(TargetIndex);
      end
      else
        TargetNodeID := MermaidUnresolvedNodeID(Edge.UnresolvedIndex);
      if Edge.Relationship.Kind = trkImplementation then
        AppendLine(Result, '  ' + MermaidTypeNodeID(SourceIndex) +
          ' -. implements .-> ' + TargetNodeID)
      else
        AppendLine(Result, '  ' + MermaidTypeNodeID(SourceIndex) +
          ' -->|inherits| ' + TargetNodeID);
    end;

    for I := 0 to Nodes.Count - 1 do
    begin
      Symbol := TDocSymbol(Nodes.Objects[I]);
      FindProjectSymbolByID(AProject, Symbol.ID, SymbolUnit);
      AppendLine(Result, '  click ' + MermaidTypeNodeID(I) + ' "units/' +
        EscapeMermaidString(HTMLUnitFilename(SymbolUnit)) + '#' +
        EscapeMermaidString(HTMLSymbolAnchor(Symbol)) + '" "Open ' +
        EscapeMermaidString(Symbol.QualifiedName) + ' documentation" _self');
    end;
  finally
    SortedEdges.Free;
    Nodes.Free;
    Edges.Free;
  end;
end;

function SortedSymbols(AUnit: TDocUnit; AKinds: TSymbolKinds): TStringList;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if (Symbol.Kind in AKinds) and IsEffectivelyRenderable(AUnit, Symbol) then
      Result.AddObject(DocumentationSymbolSortKey(Symbol), Symbol);
  end;
end;

function UnitSymbol(AUnit: TDocUnit): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if TDocSymbol(AUnit.Symbols[I]).Kind = skUnit then
      Exit(TDocSymbol(AUnit.Symbols[I]));
end;

function RenderableSymbolCount(AUnit: TDocUnit): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if IsEffectivelyRenderable(AUnit, TDocSymbol(AUnit.Symbols[I])) then
      Inc(Result);
end;

function DocumentedSymbolCount(AUnit: TDocUnit): Integer;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := 0;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if IsEffectivelyRenderable(AUnit, Symbol) and
      (Trim(Symbol.MarkdownDocumentation) <> '') then
      Inc(Result);
  end;
end;

function RenderSourceLocation(AProject: TDocProject;
  const ASourceFilename: string; ASourceLine, ASourceColumn: Integer): UTF8String;
var
  Location: string;
  URL: string;
begin
  Location := ASourceFilename;
  if ASourceLine > 0 then
  begin
    Location := Location + ':' + IntToStr(ASourceLine);
    if ASourceColumn > 0 then
      Location := Location + ':' + IntToStr(ASourceColumn);
  end;
  URL := SourceLinkURL(AProject, ASourceFilename, ASourceLine);
  if URL = '' then
    Result := '<code>' + EscapeHTML(Location) + '</code>'
  else
    Result := '<a class="source-link" href="' + EscapeHTML(URL) +
      '"><code>' + EscapeHTML(Location) + '</code></a>';
end;

function RenderSourceFile(AProject: TDocProject; const ASourceFilename: string;
  ASourceLine: Integer): UTF8String;
var
  URL: string;
begin
  URL := SourceLinkURL(AProject, ASourceFilename, ASourceLine);
  if URL = '' then
    Result := '<code>' + EscapeHTML(ASourceFilename) + '</code>'
  else
    Result := '<a class="source-link" href="' + EscapeHTML(URL) +
      '"><code>' + EscapeHTML(ASourceFilename) + '</code></a>';
end;

function DiagnosticLocation(ADiagnostic: TDiagnostic): string;
begin
  Result := ADiagnostic.SourceFilename;
  if ADiagnostic.SourceLine > 0 then
  begin
    Result := Result + ':' + IntToStr(ADiagnostic.SourceLine);
    if ADiagnostic.SourceColumn > 0 then
      Result := Result + ':' + IntToStr(ADiagnostic.SourceColumn);
  end;
end;

procedure RenderDirectives(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol);
var
  I: Integer;
  Directive: TDocDirective;
  HasParameters: Boolean;
  HasRaises: Boolean;
  HasReturns: Boolean;
  HasSince: Boolean;
  HasSee: Boolean;
begin
  HasParameters := False;
  HasRaises := False;
  HasReturns := False;
  HasSince := False;
  HasSee := False;

  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Directive := TDocDirective(ASymbol.Directives[I]);
    if Directive.Name = 'deprecated' then
    begin
      if Directive.Text <> '' then
        AppendLine(AOutput, '<div class="notice deprecated"><strong>' +
          'Deprecated:</strong> ' + RenderInlineMarkdown(Directive.Text) +
          '</div>')
      else
        AppendLine(AOutput, '<div class="notice deprecated"><strong>' +
          'Deprecated.</strong></div>');
    end;
  end;

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'param' then
    begin
      if not HasParameters then
      begin
        AppendLine(AOutput, '<section class="directive-section">');
        AppendLine(AOutput, '<h4>Parameters</h4>');
        AppendLine(AOutput, '<div class="table-shell"><table>');
        AppendLine(AOutput, '<thead><tr><th>Name</th><th>Description</th>' +
          '</tr></thead><tbody>');
        HasParameters := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      AppendLine(AOutput, '<tr><td><code>' +
        EscapeHTML(Directive.Subject) + '</code></td><td>' +
        RenderInlineMarkdown(Directive.Text) + '</td></tr>');
    end;
  if HasParameters then
    AppendLine(AOutput, '</tbody></table></div></section>');

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'returns' then
    begin
      if not HasReturns then
      begin
        AppendLine(AOutput, '<section class="directive-section">');
        AppendLine(AOutput, '<h4>Returns</h4>');
        HasReturns := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      AppendLine(AOutput, '<p>' + RenderInlineMarkdown(Directive.Text) +
        '</p>');
    end;
  if HasReturns then
    AppendLine(AOutput, '</section>');

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'raises' then
    begin
      if not HasRaises then
      begin
        AppendLine(AOutput, '<section class="directive-section">');
        AppendLine(AOutput, '<h4>Raises</h4>');
        AppendLine(AOutput, '<div class="table-shell"><table>');
        AppendLine(AOutput, '<thead><tr><th>Exception</th><th>Condition' +
          '</th></tr></thead><tbody>');
        HasRaises := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      AppendLine(AOutput, '<tr><td><code>' +
        EscapeHTML(Directive.Subject) + '</code></td><td>' +
        RenderInlineMarkdown(Directive.Text) + '</td></tr>');
    end;
  if HasRaises then
    AppendLine(AOutput, '</tbody></table></div></section>');

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'since' then
    begin
      if not HasSince then
      begin
        AppendLine(AOutput, '<section class="directive-section compact">');
        HasSince := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      if Directive.Text <> '' then
        AppendLine(AOutput, '<p><strong>Since:</strong> <code>' +
          EscapeHTML(Directive.Subject) + '</code> &mdash; ' +
          RenderInlineMarkdown(Directive.Text) + '</p>')
      else
        AppendLine(AOutput, '<p><strong>Since:</strong> <code>' +
          EscapeHTML(Directive.Subject) + '</code></p>');
    end;
  if HasSince then
    AppendLine(AOutput, '</section>');

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'see' then
    begin
      if not HasSee then
      begin
        AppendLine(AOutput, '<section class="directive-section">');
        AppendLine(AOutput, '<h4>See also</h4><ul>');
        HasSee := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      if Directive.Text <> '' then
        AppendLine(AOutput, '<li>' + RenderHTMLSeeLink(AProject, AUnit,
          Directive) + ' &mdash; ' +
          RenderInlineMarkdown(Directive.Text) + '</li>')
      else
        AppendLine(AOutput, '<li>' + RenderHTMLSeeLink(AProject, AUnit,
          Directive) + '</li>');
    end;
  if HasSee then
    AppendLine(AOutput, '</ul></section>');
end;

procedure RenderDocumentation(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol; const AUndocumentedText: string);
begin
  if Trim(ASymbol.MarkdownDocumentation) = '' then
    AppendLine(AOutput, '<div class="notice warning"><strong>' +
      'Undocumented:</strong> ' + EscapeHTML(AUndocumentedText) + '</div>')
  else
  begin
    AppendLine(AOutput, '<div class="prose">');
    AOutput := AOutput + RenderMarkdownFragment(
      ASymbol.MarkdownDocumentation);
    AppendLine(AOutput, '</div>');
  end;
  RenderDirectives(AOutput, AProject, AUnit, ASymbol);
end;

procedure RenderSearchFilters(var AOutput: UTF8String; AProject: TDocProject);
var
  I: Integer;
  J: Integer;
  Kinds: TStringList;
  Symbols: TStringList;
  UnitModel: TDocUnit;
  Units: TStringList;
  Visibilities: TStringList;
begin
  Units := SortedUnits(AProject);
  Kinds := TStringList.Create;
  Visibilities := TStringList.Create;
  try
    Kinds.Sorted := True;
    Kinds.CaseSensitive := True;
    Kinds.Duplicates := dupIgnore;
    Visibilities.Sorted := True;
    Visibilities.CaseSensitive := True;
    Visibilities.Duplicates := dupIgnore;
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      Symbols := SortedSymbols(UnitModel, AllKinds);
      try
        for J := 0 to Symbols.Count - 1 do
        begin
          Kinds.Add(SymbolKindName(TDocSymbol(Symbols.Objects[J]).Kind));
          Visibilities.Add(SymbolVisibilityName(
            TDocSymbol(Symbols.Objects[J]).Visibility));
        end;
      finally
        Symbols.Free;
      end;
    end;

    AppendLine(AOutput, '<fieldset class="search-filters"><legend ' +
      'class="sr-only">Search filters</legend>');
    AppendLine(AOutput, '<label>Unit<select data-search-unit>' +
      '<option value="">All units</option>');
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      AppendLine(AOutput, '<option value="' + EscapeHTML(UnitModel.Name) +
        '">' + EscapeHTML(UnitModel.Name) + '</option>');
    end;
    AppendLine(AOutput, '</select></label>');
    AppendLine(AOutput, '<label>Kind<select data-search-kind>' +
      '<option value="">All kinds</option>');
    for I := 0 to Kinds.Count - 1 do
      AppendLine(AOutput, '<option value="' + EscapeHTML(Kinds[I]) + '">' +
        EscapeHTML(Kinds[I]) + '</option>');
    AppendLine(AOutput, '</select></label>');
    AppendLine(AOutput, '<label>Visibility<select data-search-visibility>' +
      '<option value="">All visibilities</option>');
    for I := 0 to Visibilities.Count - 1 do
      AppendLine(AOutput, '<option value="' + EscapeHTML(Visibilities[I]) +
        '">' + EscapeHTML(Visibilities[I]) + '</option>');
    AppendLine(AOutput, '</select></label>');
    AppendLine(AOutput, '<label>Documentation<select ' +
      'data-search-documentation><option value="">Any status</option>' +
      '<option value="documented">Documented</option>' +
      '<option value="undocumented">Undocumented</option></select></label>');
    AppendLine(AOutput, '</fieldset>');
  finally
    Visibilities.Free;
    Kinds.Free;
    Units.Free;
  end;
end;

function PageStart(AProject: TDocProject; const ATitle, ARoot,
  ADescription: string; AIncludeDiagram: Boolean): UTF8String;
begin
  Result := '';
  AppendLine(Result, '<!doctype html>');
  AppendLine(Result, '<html lang="en">');
  AppendLine(Result, '<head>');
  AppendLine(Result, '<meta charset="utf-8">');
  AppendLine(Result, '<meta name="viewport" content="width=device-width,' +
    ' initial-scale=1">');
  AppendLine(Result, '<meta name="description" content="' +
    EscapeHTML(ADescription) + '">');
  AppendLine(Result, '<meta name="color-scheme" content="light dark">');
  AppendLine(Result, '<title>' + EscapeHTML(ATitle) + '</title>');
  AppendLine(Result, '<link rel="stylesheet" href="' + EscapeHTML(ARoot) +
    'assets/katex/katex.min.css">');
  AppendLine(Result, '<link rel="stylesheet" href="' + EscapeHTML(ARoot) +
    'assets/site.css">');
  AppendLine(Result, '<script defer src="' + EscapeHTML(ARoot) +
    'assets/katex/katex.min.js"></script>');
  AppendLine(Result, '<script defer src="' + EscapeHTML(ARoot) +
    'assets/math.js"></script>');
  if AIncludeDiagram then
  begin
    AppendLine(Result, '<script defer src="' + EscapeHTML(ARoot) +
      'assets/mermaid/mermaid.tiny.js"></script>');
    AppendLine(Result, '<script defer src="' + EscapeHTML(ARoot) +
      'assets/diagram.js"></script>');
  end;
  AppendLine(Result, '<script defer src="' + EscapeHTML(ARoot) +
    'assets/search-index.js"></script>');
  AppendLine(Result, '<script defer src="' + EscapeHTML(ARoot) +
    'assets/app.js"></script>');
  AppendLine(Result, '</head>');
  AppendLine(Result, '<body data-site-root="' + EscapeHTML(ARoot) + '">');
  AppendLine(Result, '<a class="skip-link" href="#main-content">Skip to ' +
    'content</a>');
  AppendLine(Result, '<header class="site-header">');
  AppendLine(Result, '<div class="shell header-inner">');
  AppendLine(Result, '<a class="brand" href="' + EscapeHTML(ARoot) +
    'index.html"><span class="brand-mark" aria-hidden="true">PW</span>' +
    '<span><strong>' + EscapeHTML(AProject.Name) +
    '</strong><small>API documentation</small></span></a>');
  AppendLine(Result, '<div class="site-search" data-search-container>');
  AppendLine(Result, '<label class="sr-only" for="site-search">Search API' +
    '</label>');
  AppendLine(Result, '<input id="site-search" data-testid="site-search" ' +
    'data-search-input type="search" autocomplete="off" ' +
    'placeholder="Search symbols…" aria-controls="search-results" ' +
    'aria-expanded="false">');
  AppendLine(Result, '<div id="search-results" class="search-panel" ' +
    'data-search-panel hidden>');
  RenderSearchFilters(Result, AProject);
  AppendLine(Result, '<p class="search-status" data-search-status ' +
    'role="status" aria-live="polite"></p><ul data-search-results></ul>');
  AppendLine(Result, '</div>');
  AppendLine(Result, '</div>');
  AppendLine(Result, '</div>');
  AppendLine(Result, '</header>');
  AppendLine(Result, '<main id="main-content" class="shell main-content">');
end;

procedure RenderDependencyFallback(var AOutput: UTF8String;
  AProject: TDocProject);
var
  Units: TStringList;
  I: Integer;
  J: Integer;
  DependencyUnit: TDocUnit;
  UnitModel: TDocUnit;
  HasProjectDependency: Boolean;
begin
  AppendLine(AOutput, '<details class="diagram-fallback ' +
    'dependency-fallback" data-diagram-fallback ' +
    'data-dependency-fallback open>');
  AppendLine(AOutput, '<summary>Text dependency list</summary>');
  AppendLine(AOutput, '<ul>');
  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      HasProjectDependency := False;
      for J := 0 to UnitModel.InterfaceDependencies.Count - 1 do
      begin
        DependencyUnit := FindUnitByName(AProject,
          UnitModel.InterfaceDependencies[J]);
        if not Assigned(DependencyUnit) then
          Continue;
        HasProjectDependency := True;
        AppendLine(AOutput, '<li><a href="units/' +
          EscapeHTML(HTMLUnitFilename(UnitModel)) + '"><code>' +
          EscapeHTML(UnitModel.Name) + '</code></a> uses <a href="units/' +
          EscapeHTML(HTMLUnitFilename(DependencyUnit)) + '"><code>' +
          EscapeHTML(DependencyUnit.Name) + '</code></a>.</li>');
      end;
      if not HasProjectDependency then
        AppendLine(AOutput, '<li><a href="units/' +
          EscapeHTML(HTMLUnitFilename(UnitModel)) + '"><code>' +
          EscapeHTML(UnitModel.Name) + '</code></a> has no project-local ' +
          'interface dependencies.</li>');
    end;
  finally
    Units.Free;
  end;
  AppendLine(AOutput, '</ul>');
  AppendLine(AOutput, '</details>');
end;

procedure RenderDiagramControls(var AOutput: UTF8String;
  const ADiagramID, ALabel: string);
var
  HelpID: string;
begin
  HelpID := ADiagramID + '-help';
  AppendLine(AOutput, '<div class="diagram-toolbar" data-diagram-toolbar ' +
    'role="toolbar" aria-label="' + EscapeHTML(ALabel) +
    ' controls" hidden>');
  AppendLine(AOutput, '<div class="diagram-control-group" role="group" ' +
    'aria-label="Zoom controls"><span class="diagram-tool-label" ' +
    'aria-hidden="true">Zoom</span>');
  AppendLine(AOutput, '<button type="button" data-diagram-zoom-out ' +
    'aria-controls="' + EscapeHTML(ADiagramID) + '">Zoom out</button>');
  AppendLine(AOutput, '<output class="diagram-zoom-status" ' +
    'data-diagram-scale aria-label="Current zoom" aria-live="polite" ' +
    'aria-atomic="true">100%</output>');
  AppendLine(AOutput, '<button type="button" data-diagram-zoom-in ' +
    'aria-controls="' + EscapeHTML(ADiagramID) + '">Zoom in</button>');
  AppendLine(AOutput, '</div>');
  AppendLine(AOutput, '<div class="diagram-control-group" role="group" ' +
    'aria-label="Pan controls"><span class="diagram-tool-label" ' +
    'aria-hidden="true">Pan</span>');
  AppendLine(AOutput, '<button type="button" class="diagram-icon-button" ' +
    'data-diagram-pan-left aria-label="Pan left" title="Pan left" ' +
    'aria-controls="' + EscapeHTML(ADiagramID) +
    '" disabled aria-hidden="true">&larr;</button>');
  AppendLine(AOutput, '<button type="button" class="diagram-icon-button" ' +
    'data-diagram-pan-up aria-label="Pan up" title="Pan up" ' +
    'aria-controls="' + EscapeHTML(ADiagramID) +
    '" disabled aria-hidden="true">&uarr;</button>');
  AppendLine(AOutput, '<button type="button" class="diagram-icon-button" ' +
    'data-diagram-pan-down aria-label="Pan down" title="Pan down" ' +
    'aria-controls="' + EscapeHTML(ADiagramID) +
    '" disabled aria-hidden="true">&darr;</button>');
  AppendLine(AOutput, '<button type="button" class="diagram-icon-button" ' +
    'data-diagram-pan-right aria-label="Pan right" title="Pan right" ' +
    'aria-controls="' + EscapeHTML(ADiagramID) +
    '" disabled aria-hidden="true">&rarr;</button>');
  AppendLine(AOutput, '</div>');
  AppendLine(AOutput, '<button type="button" data-diagram-reset ' +
    'aria-controls="' + EscapeHTML(ADiagramID) + '" disabled>Reset</button>');
  AppendLine(AOutput, '</div>');
  AppendLine(AOutput, '<p id="' + EscapeHTML(HelpID) +
    '" class="diagram-help" data-diagram-help hidden>Use the controls or ' +
    'focus the diagram: arrow keys pan, plus and minus zoom, and 0 resets. ' +
    'You can also drag with a mouse or use the scrollbars.</p>');
end;

function RelationshipSymbolLink(AUnit: TDocUnit;
  ASymbol: TDocSymbol): UTF8String;
begin
  Result := '<a href="units/' + EscapeHTML(HTMLUnitFilename(AUnit)) + '#' +
    EscapeHTML(HTMLSymbolAnchor(ASymbol)) + '"><code>' +
    EscapeHTML(ASymbol.QualifiedName) + '</code></a>';
end;

procedure RenderTypeRelationshipFallback(var AOutput: UTF8String;
  AProject: TDocProject);
var
  Edge: TRelationshipDiagramEdge;
  Edges: TObjectList;
  Nodes: TStringList;
  SortedEdges: TStringList;
  I: Integer;
  DisplaySuffix: UTF8String;
  Verb: string;
begin
  Edges := TObjectList.Create(True);
  Nodes := TStringList.Create;
  SortedEdges := TStringList.Create;
  try
    Nodes.Sorted := True;
    Nodes.CaseSensitive := True;
    Nodes.Duplicates := dupAccept;
    SortedEdges.Sorted := True;
    SortedEdges.CaseSensitive := True;
    SortedEdges.Duplicates := dupAccept;
    CollectRelationshipDiagram(AProject, Edges, SortedEdges, Nodes);
    if SortedEdges.Count = 0 then
      Exit;

    AppendLine(AOutput, '<details class="diagram-fallback ' +
      'relationship-fallback" data-diagram-fallback open>');
    AppendLine(AOutput, '<summary>Text relationship list</summary>');
    AppendLine(AOutput, '<ul>');
    for I := 0 to SortedEdges.Count - 1 do
    begin
      Edge := TRelationshipDiagramEdge(SortedEdges.Objects[I]);
      if Edge.Relationship.Kind = trkImplementation then
        Verb := ' implements '
      else
        Verb := ' inherits from ';
      if Assigned(Edge.TargetSymbol) then
      begin
        if not SameText(Edge.Relationship.DisplayName,
          Edge.TargetSymbol.Name) then
          DisplaySuffix := ' as <code>' +
            EscapeHTML(Edge.Relationship.DisplayName) + '</code>'
        else
          DisplaySuffix := '';
        AppendLine(AOutput, '<li>' + RelationshipSymbolLink(Edge.SourceUnit,
          Edge.SourceSymbol) + EscapeHTML(Verb) +
          RelationshipSymbolLink(Edge.TargetUnit, Edge.TargetSymbol) +
          DisplaySuffix + '.</li>');
      end
      else
        AppendLine(AOutput, '<li>' + RelationshipSymbolLink(Edge.SourceUnit,
          Edge.SourceSymbol) + EscapeHTML(Verb) +
          'unresolved type <code>' +
          EscapeHTML(Edge.Relationship.DisplayName) +
          '</code>.</li>');
    end;
    AppendLine(AOutput, '</ul>');
    AppendLine(AOutput, '</details>');
  finally
    SortedEdges.Free;
    Nodes.Free;
    Edges.Free;
  end;
end;

procedure RenderDependencyOverview(var AOutput: UTF8String;
  AProject: TDocProject);
begin
  if AProject.Units.Count = 0 then
    Exit;
  AppendLine(AOutput, '<section class="index-section diagram-overview ' +
    'dependency-overview" data-diagram-section ' +
    'data-dependency-overview aria-labelledby="unit-dependencies">');
  AppendLine(AOutput, '<div class="section-heading"><div><p class="eyebrow">' +
    'Architecture</p><h2 id="unit-dependencies">Unit dependencies</h2></div>' +
    '<p>Arrows point from a unit to the project unit it imports.</p></div>');
  RenderDiagramControls(AOutput, 'unit-dependency-diagram',
    'Unit dependency diagram');
  AppendLine(AOutput, '<div class="architecture-diagram ' +
    'dependency-diagram" data-diagram-container ' +
    'data-dependency-diagram id="unit-dependency-diagram" role="region" ' +
    'aria-label="Interactive unit dependency diagram" ' +
    'aria-describedby="unit-dependency-diagram-help" tabindex="0" ' +
    'aria-hidden="true" hidden>');
  AppendLine(AOutput, '<pre class="mermaid" data-mermaid>');
  AOutput := AOutput + EscapeHTML(RenderMermaidDependencyGraph(AProject));
  AppendLine(AOutput, '</pre>');
  AppendLine(AOutput, '</div>');
  RenderDependencyFallback(AOutput, AProject);
  AppendLine(AOutput, '</section>');
end;

procedure RenderTypeRelationshipOverview(var AOutput: UTF8String;
  AProject: TDocProject);
var
  Graph: UTF8String;
begin
  Graph := RenderMermaidTypeRelationshipGraph(AProject);
  if Graph = '' then
    Exit;
  AppendLine(AOutput, '<section class="index-section diagram-overview ' +
    'relationship-overview" data-diagram-section ' +
    'aria-labelledby="type-relationships">');
  AppendLine(AOutput, '<div class="section-heading"><div><p ' +
    'class="eyebrow">Architecture</p><h2 id="type-relationships">' +
    'Class and interface relationships</h2></div><p>Solid arrows show ' +
    'inheritance; dotted arrows show interface implementation.</p></div>');
  RenderDiagramControls(AOutput, 'type-relationship-diagram',
    'Class and interface relationship diagram');
  AppendLine(AOutput, '<div class="architecture-diagram ' +
    'relationship-diagram" data-diagram-container ' +
    'id="type-relationship-diagram" role="region" ' +
    'aria-label="Interactive class and interface relationship diagram" ' +
    'aria-describedby="type-relationship-diagram-help" tabindex="0" ' +
    'aria-hidden="true" hidden>');
  AppendLine(AOutput, '<pre class="mermaid" data-mermaid>');
  AOutput := AOutput + EscapeHTML(Graph);
  AppendLine(AOutput, '</pre>');
  AppendLine(AOutput, '</div>');
  RenderTypeRelationshipFallback(AOutput, AProject);
  AppendLine(AOutput, '</section>');
end;

procedure AppendPageEnd(var AOutput: UTF8String; AProject: TDocProject);
begin
  AppendLine(AOutput, '</main>');
  AppendLine(AOutput, '<footer class="site-footer"><div class="shell">' +
    'Generated by PasWeave from <code>' + EscapeHTML(AProject.SourceRoot) +
    '</code>.</div></footer>');
  AppendLine(AOutput, '</body>');
  AppendLine(AOutput, '</html>');
end;

procedure RenderSymbol(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol);
var
  I: Integer;
  ParentSymbol: TDocSymbol;
  Anchor: string;
  Relationship: TDocTypeRelationship;
  RelationshipLabel: string;
begin
  Anchor := HTMLSymbolAnchor(ASymbol);
  AppendLine(AOutput, '<article class="symbol" id="' + EscapeHTML(Anchor) +
    '">');
  AppendLine(AOutput, '<div class="symbol-heading">');
  AppendLine(AOutput, '<div><span class="kind-badge">' +
    EscapeHTML(SymbolKindName(ASymbol.Kind)) + '</span><h3><code>' +
    EscapeHTML(ASymbol.QualifiedName) + '</code></h3></div>');
  AppendLine(AOutput, '<a class="permalink" href="#' + EscapeHTML(Anchor) +
    '" aria-label="Permanent link to ' + EscapeHTML(ASymbol.QualifiedName) +
    '">#</a>');
  AppendLine(AOutput, '</div>');
  AppendLine(AOutput, '<p class="symbol-meta"><span>Visibility <code>' +
    EscapeHTML(SymbolVisibilityName(ASymbol.Visibility)) +
    '</code></span><span>Source ' + RenderSourceLocation(AProject,
    ASymbol.SourceFilename, ASymbol.SourceLine, ASymbol.SourceColumn) +
    '</span></p>');

  ParentSymbol := FindSymbolByID(AUnit, ASymbol.ParentSymbolID);
  if Assigned(ParentSymbol) and (ParentSymbol.Kind <> skUnit) then
    AppendLine(AOutput, '<p class="parent-link">Parent: ' +
      RenderHTMLSymbolLink(AProject, AUnit, ParentSymbol.ID,
      ParentSymbol.QualifiedName) + '</p>');

  if ASymbol.TypeRelationships.Count > 0 then
  begin
    AppendLine(AOutput, '<div class="type-relationships"><strong>' +
      'Relationships:</strong><ul>');
    for I := 0 to ASymbol.TypeRelationships.Count - 1 do
    begin
      Relationship := TDocTypeRelationship(ASymbol.TypeRelationships[I]);
      if Relationship.Kind = trkImplementation then
        RelationshipLabel := 'Implements'
      else
        RelationshipLabel := 'Inherits from';
      AppendLine(AOutput, '<li>' + EscapeHTML(RelationshipLabel) + ' ' +
        RenderHTMLSymbolLink(AProject, AUnit, Relationship.TargetSymbolID,
        Relationship.DisplayName) + '</li>');
    end;
    AppendLine(AOutput, '</ul></div>');
  end;

  if ASymbol.DeclarationText <> '' then
  begin
    AppendLine(AOutput, '<pre class="declaration"><code ' +
      'class="language-pascal">');
    AppendLine(AOutput, EscapeHTML(ASymbol.DeclarationText));
    AppendLine(AOutput, '</code></pre>');
  end;
  RenderDocumentation(AOutput, AProject, AUnit, ASymbol,
    'This API symbol has no documentation.');
  AppendLine(AOutput, '</article>');
end;

procedure RenderSymbolGroup(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; const AHeading, AID: string; AKinds: TSymbolKinds);
var
  Symbols: TStringList;
  I: Integer;
begin
  Symbols := SortedSymbols(AUnit, AKinds);
  try
    if Symbols.Count = 0 then
      Exit;
    AppendLine(AOutput, '<section class="symbol-group" aria-labelledby="' +
      EscapeHTML(AID) + '">');
    AppendLine(AOutput, '<div class="group-heading"><h2 id="' +
      EscapeHTML(AID) + '">' + EscapeHTML(AHeading) + '</h2><span>' +
      UTF8String(IntToStr(Symbols.Count)) + '</span></div>');
    for I := 0 to Symbols.Count - 1 do
      RenderSymbol(AOutput, AProject, AUnit,
        TDocSymbol(Symbols.Objects[I]));
    AppendLine(AOutput, '</section>');
  finally
    Symbols.Free;
  end;
end;

function RenderHTMLIndex(AProject: TDocProject): UTF8String;
var
  Units: TStringList;
  I: Integer;
  UnitModel: TDocUnit;
  PublicCount: Integer;
  DocumentedCount: Integer;
  CoveragePercent: Integer;
  Diagnostic: TDiagnostic;
begin
  Result := PageStart(AProject, AProject.Name + ' API', '',
    'API documentation for ' + AProject.Name, AProject.Units.Count > 0);
  PublicCount := 0;
  DocumentedCount := 0;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    Inc(PublicCount, RenderableSymbolCount(TDocUnit(AProject.Units[I])));
    Inc(DocumentedCount, DocumentedSymbolCount(TDocUnit(AProject.Units[I])));
  end;
  if PublicCount > 0 then
    CoveragePercent := (DocumentedCount * 100) div PublicCount
  else
    CoveragePercent := 100;

  AppendLine(Result, '<section class="hero">');
  AppendLine(Result, '<p class="eyebrow">Free Pascal API reference</p>');
  AppendLine(Result, '<h1>' + EscapeHTML(AProject.Name) + '</h1>');
  AppendLine(Result, '<p class="hero-copy">Browse units and declarations, ' +
    'or search the complete public API.</p>');
  AppendLine(Result, '<p class="source-root">Source root <code>' +
    EscapeHTML(AProject.SourceRoot) + '</code></p>');
  AppendLine(Result, '</section>');
  AppendLine(Result, '<section class="stats" aria-label="Project totals">');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(AProject.Units.Count)) +
    '</strong><span>Units</span></div>');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(AProject.SymbolCount)) +
    '</strong><span>Parsed symbols</span></div>');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(PublicCount)) +
    '</strong><span>Public API symbols</span></div>');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(CoveragePercent)) +
    '%</strong><span>Documented</span></div>');
  AppendLine(Result, '</section>');

  RenderDependencyOverview(Result, AProject);
  RenderTypeRelationshipOverview(Result, AProject);

  AppendLine(Result, '<section class="index-section">');
  AppendLine(Result, '<div class="section-heading"><div><p class="eyebrow">' +
    'Reference</p><h2>Units</h2></div><p>' +
    UTF8String(IntToStr(DocumentedCount)) + ' of ' +
    UTF8String(IntToStr(PublicCount)) + ' API symbols documented</p></div>');
  AppendLine(Result, '<div class="table-shell"><table class="unit-table">');
  AppendLine(Result, '<thead><tr><th>Unit</th><th>Source</th>' +
    '<th class="number">API symbols</th><th class="number">Documented' +
    '</th></tr></thead><tbody>');
  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      AppendLine(Result, '<tr><td><a class="unit-link" href="units/' +
        EscapeHTML(HTMLUnitFilename(UnitModel)) + '">' +
        EscapeHTML(UnitModel.Name) + '</a></td><td><code>' +
        EscapeHTML(UnitModel.SourceFilename) +
        '</code></td><td class="number">' +
        UTF8String(IntToStr(RenderableSymbolCount(UnitModel))) +
        '</td><td class="number">' +
        UTF8String(IntToStr(DocumentedSymbolCount(UnitModel))) +
        '</td></tr>');
    end;
  finally
    Units.Free;
  end;
  AppendLine(Result, '</tbody></table></div></section>');

  if (AProject.Warnings.Count > 0) or (AProject.Errors.Count > 0) then
  begin
    AppendLine(Result, '<section class="index-section diagnostics">');
    AppendLine(Result, '<div class="section-heading"><div><p ' +
      'class="eyebrow">Build</p><h2>Diagnostics</h2></div></div><ul>');
    for I := 0 to AProject.Warnings.Count - 1 do
    begin
      Diagnostic := TDiagnostic(AProject.Warnings[I]);
      AppendLine(Result, '<li><strong>Warning ' + EscapeHTML(Diagnostic.Code) +
        '</strong> <code>' +
        EscapeHTML(DiagnosticLocation(Diagnostic)) + '</code>: ' +
        EscapeHTML(Diagnostic.MessageText) + '</li>');
    end;
    for I := 0 to AProject.Errors.Count - 1 do
    begin
      Diagnostic := TDiagnostic(AProject.Errors[I]);
      AppendLine(Result, '<li><strong>Error ' + EscapeHTML(Diagnostic.Code) +
        '</strong> <code>' +
        EscapeHTML(DiagnosticLocation(Diagnostic)) + '</code>: ' +
        EscapeHTML(Diagnostic.MessageText) + '</li>');
    end;
    AppendLine(Result, '</ul></section>');
  end;
  AppendPageEnd(Result, AProject);
end;

function RenderHTMLUnit(AProject: TDocProject; AUnit: TDocUnit): UTF8String;
var
  I: Integer;
  Dependency: string;
  DependencyUnit: TDocUnit;
  ThisUnitSymbol: TDocSymbol;
begin
  Result := PageStart(AProject, AUnit.Name + ' - ' + AProject.Name, '../',
    'API documentation for unit ' + AUnit.Name, False);
  AppendLine(Result, '<nav class="breadcrumb" aria-label="Breadcrumb">' +
    '<a href="../index.html">API index</a><span aria-hidden="true">/' +
    '</span><span>' + EscapeHTML(AUnit.Name) + '</span></nav>');
  AppendLine(Result, '<section class="unit-heading">');
  AppendLine(Result, '<p class="eyebrow">Unit</p><h1><code>' +
    EscapeHTML(AUnit.Name) + '</code></h1>');
  ThisUnitSymbol := UnitSymbol(AUnit);
  if Assigned(ThisUnitSymbol) then
    AppendLine(Result, '<p>Declared in ' + RenderSourceFile(AProject,
      AUnit.SourceFilename, ThisUnitSymbol.SourceLine) + '</p></section>')
  else
    AppendLine(Result, '<p>Declared in <code>' +
      EscapeHTML(AUnit.SourceFilename) + '</code></p></section>');

  if Assigned(ThisUnitSymbol) then
    RenderDocumentation(Result, AProject, AUnit, ThisUnitSymbol,
      'This unit has no documentation.');

  AppendLine(Result, '<section class="dependency-section">');
  AppendLine(Result, '<div class="group-heading"><h2>Interface ' +
    'dependencies</h2><span>' +
    UTF8String(IntToStr(AUnit.InterfaceDependencies.Count)) +
    '</span></div>');
  if AUnit.InterfaceDependencies.Count = 0 then
    AppendLine(Result, '<p class="muted">None.</p>')
  else
  begin
    AppendLine(Result, '<ul class="dependency-list">');
    for I := 0 to AUnit.InterfaceDependencies.Count - 1 do
    begin
      Dependency := AUnit.InterfaceDependencies[I];
      DependencyUnit := FindUnitByName(AProject, Dependency);
      if Assigned(DependencyUnit) then
        AppendLine(Result, '<li><a href="' +
          EscapeHTML(HTMLUnitFilename(DependencyUnit)) + '"><code>' +
          EscapeHTML(Dependency) + '</code></a></li>')
      else
        AppendLine(Result, '<li><code>' + EscapeHTML(Dependency) +
          '</code></li>');
    end;
    AppendLine(Result, '</ul>');
  end;
  AppendLine(Result, '</section>');

  RenderSymbolGroup(Result, AProject, AUnit, 'Types', 'types', TypeKinds);
  RenderSymbolGroup(Result, AProject, AUnit, 'Routines', 'routines',
    RoutineKinds);
  RenderSymbolGroup(Result, AProject, AUnit, 'Members', 'members', MemberKinds);
  RenderSymbolGroup(Result, AProject, AUnit, 'Constants and variables',
    'values', ValueKinds);
  AppendPageEnd(Result, AProject);
end;

function SearchSummary(const AText: string): string;
var
  I: Integer;
  C: Char;
  LastWasSpace: Boolean;
begin
  Result := '';
  LastWasSpace := True;
  for I := 1 to Length(AText) do
  begin
    C := AText[I];
    if C in [#9, #10, #13, ' '] then
    begin
      if not LastWasSpace then
      begin
        Result := Result + ' ';
        LastWasSpace := True;
      end;
    end
    else if not (C in ['#', '*', '`', '[', ']']) then
    begin
      Result := Result + C;
      LastWasSpace := False;
    end;
  end;
  Result := Trim(Result);
  if Length(Result) > 180 then
    Result := Copy(Result, 1, 177) + '...';
end;

function RenderHTMLSearchIndex(AProject: TDocProject): UTF8String;
var
  Items: TJSONArray;
  Item: TJSONObject;
  Units: TStringList;
  Symbols: TStringList;
  I: Integer;
  J: Integer;
  UnitModel: TDocUnit;
  Symbol: TDocSymbol;
  URL: string;
begin
  Items := TJSONArray.Create;
  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      Symbols := SortedSymbols(UnitModel, AllKinds);
      try
        for J := 0 to Symbols.Count - 1 do
        begin
          Symbol := TDocSymbol(Symbols.Objects[J]);
          URL := 'units/' + HTMLUnitFilename(UnitModel);
          if Symbol.Kind <> skUnit then
            URL := URL + '#' + HTMLSymbolAnchor(Symbol);
          Item := TJSONObject.Create;
          Item.Add('name', Symbol.Name);
          Item.Add('qualifiedName', Symbol.QualifiedName);
          Item.Add('kind', SymbolKindName(Symbol.Kind));
          Item.Add('unit', UnitModel.Name);
          Item.Add('visibility', SymbolVisibilityName(Symbol.Visibility));
          Item.Add('documented', Trim(Symbol.MarkdownDocumentation) <> '');
          Item.Add('url', URL);
          Item.Add('summary', SearchSummary(Symbol.MarkdownDocumentation));
          Items.Add(Item);
        end;
      finally
        Symbols.Free;
      end;
    end;
    Result := 'window.PASWEAVE_SEARCH_INDEX = ' + UTF8String(Items.AsJSON) +
      ';' + #10;
  finally
    Units.Free;
    Items.Free;
  end;
end;

procedure WriteUTF8File(const AFileName: string; const AData: UTF8String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(AData) > 0 then
      Stream.WriteBuffer(AData[1], Length(AData));
  finally
    Stream.Free;
  end;
end;

procedure WriteHTMLDocumentation(AProject: TDocProject;
  const AOutputDirectory: string);
var
  UnitsDirectory: string;
  AssetsDirectory: string;
  Units: TStringList;
  I: Integer;
  UnitModel: TDocUnit;
begin
  UnitsDirectory := IncludeTrailingPathDelimiter(AOutputDirectory) + 'units';
  AssetsDirectory := IncludeTrailingPathDelimiter(AOutputDirectory) + 'assets';
  if not ForceDirectories(UnitsDirectory) then
    raise EFCreateError.CreateFmt('cannot create HTML unit directory: %s',
      [UnitsDirectory]);
  if not ForceDirectories(AssetsDirectory) then
    raise EFCreateError.CreateFmt('cannot create HTML asset directory: %s',
      [AssetsDirectory]);

  WriteThirdPartyAssets(AssetsDirectory);
  WriteUTF8File(IncludeTrailingPathDelimiter(AOutputDirectory) + 'index.html',
    RenderHTMLIndex(AProject));
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'site.css',
    HTMLStylesheet);
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'app.js',
    HTMLApplicationScript);
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'math.js',
    HTMLMathScript);
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'diagram.js',
    HTMLDiagramScript);
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) +
    'search-index.js', RenderHTMLSearchIndex(AProject));

  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      WriteUTF8File(IncludeTrailingPathDelimiter(UnitsDirectory) +
        HTMLUnitFilename(UnitModel), RenderHTMLUnit(AProject, UnitModel));
    end;
  finally
    Units.Free;
  end;
end;

end.
