unit PasWeave.Render.HTML.Diagrams;

{$mode objfpc}{$H+}{$J+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

function RenderMermaidDependencyGraph(AProject: TDocProject): UTF8String;
function RenderMermaidTypeRelationshipGraph(AProject: TDocProject): UTF8String;
procedure RenderDependencyOverview(var AOutput: UTF8String;
  AProject: TDocProject);
procedure RenderTypeRelationshipOverview(var AOutput: UTF8String;
  AProject: TDocProject);

implementation

uses
  Classes, Contnrs, SysUtils, PasWeave.Render.Support;

type
  TRelationshipDiagramEdge = class
  public
    SourceUnit: TDocUnit;
    SourceSymbol: TDocSymbol;
    Relationship: TDocTypeRelationship;
    TargetUnit: TDocUnit;
    TargetSymbol: TDocSymbol;
    UnresolvedIndex: Integer;
  end;

function UnitPageFilename(AUnit: TDocUnit): string;
begin
  Result := SafeFileNameBase(AUnit.Name) + '.html';
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
        DependencyIndex := IndexOfObject(Units, DependencyUnit);
        if DependencyIndex >= 0 then
          AppendLine(Result, '  ' + MermaidNodeID(I) + ' --> ' +
            MermaidNodeID(DependencyIndex));
      end;
    end;

    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      AppendLine(Result, '  click ' + MermaidNodeID(I) + ' "units/' +
        EscapeMermaidString(UnitPageFilename(UnitModel)) + '" "Open ' +
        EscapeMermaidString(UnitModel.Name) + ' documentation" _self');
    end;
  finally
    Units.Free;
  end;
end;

procedure AddRelationshipNode(ANodes: TStringList; ASymbol: TDocSymbol);
begin
  if IndexOfObject(ANodes, ASymbol) < 0 then
    ANodes.AddObject(ASymbol.QualifiedName + DocumentationSortSeparator +
      ASymbol.ID, ASymbol);
end;

function RelationshipEdgeKey(AEdge: TRelationshipDiagramEdge): string;
var
  TargetKey: string;
begin
  if Assigned(AEdge.TargetSymbol) then
    TargetKey := AEdge.TargetSymbol.QualifiedName +
      DocumentationSortSeparator +
      AEdge.TargetSymbol.ID
  else
    TargetKey := AEdge.Relationship.TargetName + DocumentationSortSeparator +
      AEdge.Relationship.DisplayName;
  Result := AEdge.SourceSymbol.QualifiedName + DocumentationSortSeparator +
    TypeRelationshipKindName(AEdge.Relationship.Kind) +
    DocumentationSortSeparator + TargetKey + DocumentationSortSeparator +
    AEdge.SourceSymbol.ID;
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
  Nodes := TOrdinalStringList.Create;
  SortedEdges := TOrdinalStringList.Create;
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
        EscapeMermaidString(UnitPageFilename(SymbolUnit)) + '#' +
        EscapeMermaidString(DocumentationSymbolAnchor(Symbol)) + '" "Open ' +
        EscapeMermaidString(Symbol.QualifiedName) + ' documentation" _self');
    end;
  finally
    SortedEdges.Free;
    Nodes.Free;
    Edges.Free;
  end;
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
          EscapeHTML(UnitPageFilename(UnitModel)) + '"><code>' +
          EscapeHTML(UnitModel.Name) + '</code></a> uses <a href="units/' +
          EscapeHTML(UnitPageFilename(DependencyUnit)) + '"><code>' +
          EscapeHTML(DependencyUnit.Name) + '</code></a>.</li>');
      end;
      if not HasProjectDependency then
        AppendLine(AOutput, '<li><a href="units/' +
          EscapeHTML(UnitPageFilename(UnitModel)) + '"><code>' +
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
  Result := '<a href="units/' + EscapeHTML(UnitPageFilename(AUnit)) + '#' +
    EscapeHTML(DocumentationSymbolAnchor(ASymbol)) + '"><code>' +
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
  Nodes := TOrdinalStringList.Create;
  SortedEdges := TOrdinalStringList.Create;
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

end.
