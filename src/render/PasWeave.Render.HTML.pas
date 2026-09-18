unit PasWeave.Render.HTML;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

/// Route-relative filename of a unit page, for example `Demo.Core.html`.
function HTMLUnitFilename(AUnit: TDocUnit): string;
/// Fixed filename of the symbol index page.
function HTMLSymbolIndexFilename: string;
/// Stable anchor of a symbol on its unit page.
function HTMLSymbolAnchor(ASymbol: TDocSymbol): string;
/// Mermaid source for the unit dependency graph.
function RenderMermaidDependencyGraph(AProject: TDocProject): UTF8String;
/// Mermaid source for the class/interface relationship graph; empty when the
/// project has no relationships.
function RenderMermaidTypeRelationshipGraph(
  AProject: TDocProject): UTF8String;
/// Renders the project index page (summary, Browse API, units, diagrams).
function RenderHTMLIndex(AProject: TDocProject): UTF8String;
/// Renders the A-Z/# symbol index page.
function RenderHTMLSymbolIndex(AProject: TDocProject): UTF8String;
/// Renders one unit page with symbols, anchors, and source links.
function RenderHTMLUnit(AProject: TDocProject; AUnit: TDocUnit): UTF8String;
/// Renders the offline search index as a JavaScript asset.
function RenderHTMLSearchIndex(AProject: TDocProject): UTF8String;
/// Writes the complete HTML site, including offline assets, under
/// `AOutputDirectory`.
procedure WriteHTMLDocumentation(AProject: TDocProject;
  const AOutputDirectory: string);

implementation

uses
  Classes, Contnrs, SysUtils, FPJSON, PasWeave.Diagnostics,
  PasWeave.Render.Support, PasWeave.Render.HTML.Diagrams,
  PasWeave.Render.HTML.Markdown,
  PasWeave.Render.HTML.Assets, PasWeave.Render.Links, PasWeave.SourceLinks,
  PasWeave.Output;

type
  TIndexedSymbolEntry = class
  public
    Symbol: TDocSymbol;
    UnitModel: TDocUnit;
    constructor Create(ASymbol: TDocSymbol; AUnitModel: TDocUnit);
  end;

constructor TIndexedSymbolEntry.Create(ASymbol: TDocSymbol;
  AUnitModel: TDocUnit);
begin
  inherited Create;
  Symbol := ASymbol;
  UnitModel := AUnitModel;
end;

function HTMLUnitFilename(AUnit: TDocUnit): string;
begin
  Result := SafeFileNameBase(AUnit.Name) + '.html';
end;

function HTMLSymbolIndexFilename: string;
begin
  Result := 'symbols.html';
end;

function HTMLSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := DocumentationSymbolAnchor(ASymbol);
end;


{ Public API wrappers: the diagram implementation lives in
  PasWeave.Render.HTML.Diagrams. }
function RenderMermaidDependencyGraph(AProject: TDocProject): UTF8String;
begin
  Result := PasWeave.Render.HTML.Diagrams.RenderMermaidDependencyGraph(AProject);
end;

function RenderMermaidTypeRelationshipGraph(
  AProject: TDocProject): UTF8String;
begin
  Result := PasWeave.Render.HTML.Diagrams.RenderMermaidTypeRelationshipGraph(
    AProject);
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
  Kinds := TOrdinalStringList.Create;
  Visibilities := TOrdinalStringList.Create;
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

function HasRenderableSymbols(AUnit: TDocUnit;
  AKinds: TSymbolKinds): Boolean;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := False;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if (Symbol.Kind in AKinds) and IsEffectivelyRenderable(AUnit, Symbol) then
      Exit(True);
  end;
end;

procedure RenderUnitSwitcher(var AOutput: UTF8String;
  AProject: TDocProject; ACurrentUnit: TDocUnit);
var
  I: Integer;
  UnitCountLabel: string;
  UnitModel: TDocUnit;
  Units: TStringList;
begin
  Units := SortedUnits(AProject);
  try
    if Units.Count = 1 then
      UnitCountLabel := ' unit'
    else
      UnitCountLabel := ' units';
    AppendLine(AOutput,
      '<details class="unit-switcher" data-unit-switcher>');
    AppendLine(AOutput, '<summary>Switch unit <span ' +
      'class="unit-switcher-current"><code>' +
      EscapeHTML(ACurrentUnit.Name) + '</code></span></summary>');
    AppendLine(AOutput, '<div class="unit-switcher-panel">');
    AppendLine(AOutput, '<label for="unit-switcher-filter">Find a unit' +
      '</label>');
    AppendLine(AOutput, '<input id="unit-switcher-filter" ' +
      'data-unit-switcher-filter type="search" autocomplete="off" ' +
      'placeholder="Filter units…">');
    AppendLine(AOutput, '<p class="unit-switcher-status" ' +
      'data-unit-switcher-status role="status" aria-live="polite">' +
      UTF8String(IntToStr(Units.Count)) + UnitCountLabel + '</p>');
    AppendLine(AOutput,
      '<ul class="unit-switcher-list" data-unit-switcher-list>');
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      if UnitModel = ACurrentUnit then
        AppendLine(AOutput, '<li><a href="' +
          EscapeHTML(HTMLUnitFilename(UnitModel)) +
          '" aria-current="page"><code>' + EscapeHTML(UnitModel.Name) +
          '</code></a></li>')
      else
        AppendLine(AOutput, '<li><a href="' +
          EscapeHTML(HTMLUnitFilename(UnitModel)) + '"><code>' +
          EscapeHTML(UnitModel.Name) + '</code></a></li>');
    end;
    AppendLine(AOutput, '</ul></div></details>');
  finally
    Units.Free;
  end;
end;

procedure RenderPageNavigator(var AOutput: UTF8String; AUnit: TDocUnit);
var
  HasMembers: Boolean;
  HasRoutines: Boolean;
  HasTypes: Boolean;
  HasValues: Boolean;
begin
  HasTypes := HasRenderableSymbols(AUnit, TypeKinds);
  HasRoutines := HasRenderableSymbols(AUnit, RoutineKinds);
  HasMembers := HasRenderableSymbols(AUnit, MemberKinds);
  HasValues := HasRenderableSymbols(AUnit, ValueKinds);
  if not (HasTypes or HasRoutines or HasMembers or HasValues) then
    Exit;

  AppendLine(AOutput,
    '<nav class="page-navigator" aria-label="On this page">');
  AppendLine(AOutput, '<span>On this page</span><ul>');
  if HasTypes then
    AppendLine(AOutput, '<li><a href="#types">Types</a></li>');
  if HasRoutines then
    AppendLine(AOutput, '<li><a href="#routines">Routines</a></li>');
  if HasMembers then
    AppendLine(AOutput, '<li><a href="#members">Members</a></li>');
  if HasValues then
    AppendLine(AOutput, '<li><a href="#values">' +
      'Constants and variables</a></li>');
  AppendLine(AOutput, '</ul></nav>');
end;

procedure RenderUnitPageNavigation(var AOutput: UTF8String;
  AProject: TDocProject; AUnit: TDocUnit);
begin
  AppendLine(AOutput, '<div class="unit-navigation">');
  RenderUnitSwitcher(AOutput, AProject, AUnit);
  RenderPageNavigator(AOutput, AUnit);
  AppendLine(AOutput, '</div>');
end;

function PageStart(AProject: TDocProject; const ATitle, ARoot,
  ADescription: string; AIncludeDiagram: Boolean;
  const ACurrentSection: string = ''): UTF8String;
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
  AppendLine(Result, '<script>');
  Result := Result + HTMLThemeBootstrap;
  AppendLine(Result, '</script>');
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
    'index.html"><span class="brand-mark" aria-hidden="true">' +
    EscapeHTML(AProject.ProjectMark) + '</span>' +
    '<span><strong>' + EscapeHTML(AProject.Name) +
    '</strong><small>API documentation</small></span></a>');
  AppendLine(Result, '<div class="header-tools">');
  AppendLine(Result, '<nav class="site-nav" aria-label="Site">');
  if ACurrentSection = 'index' then
    AppendLine(Result, '<a href="' + EscapeHTML(ARoot) +
      'index.html" aria-current="page">Units</a>')
  else
    AppendLine(Result, '<a href="' + EscapeHTML(ARoot) +
      'index.html">Units</a>');
  if ACurrentSection = 'symbols' then
    AppendLine(Result, '<a href="' + EscapeHTML(ARoot) +
      'symbols.html" aria-current="page">Symbols Index</a>')
  else
    AppendLine(Result, '<a href="' + EscapeHTML(ARoot) +
      'symbols.html">Symbols Index</a>');
  AppendLine(Result, '</nav>');
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
  AppendLine(Result, '<div class="theme-control" hidden data-theme-control>');
  AppendLine(Result, '<label for="pasweave-theme-select">Theme</label>');
  AppendLine(Result, '<select id="pasweave-theme-select" ' +
    'data-theme-select>');
  AppendLine(Result, '<option value="system">System</option>');
  AppendLine(Result, '<option value="light">Light</option>');
  AppendLine(Result, '<option value="dark">Dark</option>');
  AppendLine(Result, '</select>');
  AppendLine(Result, '</div>');
  AppendLine(Result, '</div>');
  AppendLine(Result, '</div>');
  AppendLine(Result, '</header>');
  AppendLine(Result, '<main id="main-content" class="shell main-content">');
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

function SymbolIndexGroupName(AKind: TSymbolKind): string;
begin
  if AKind in TypeKinds then
    Exit('types');
  if AKind in RoutineKinds then
    Exit('routines');
  if AKind in MemberKinds then
    Exit('members');
  if AKind in ConstantKinds then
    Exit('constants');
  if AKind in VariableKinds then
    Exit('variables');
  Result := '';
end;

function SymbolIndexSortKey(ASymbol: TDocSymbol): string;
begin
  Result := LowerCase(ASymbol.Name) + DocumentationSortSeparator +
    ASymbol.QualifiedName + DocumentationSortSeparator + ASymbol.ID;
end;

function CountIndexedSymbols(AProject: TDocProject;
  AKinds: TSymbolKinds): Integer;
var
  I: Integer;
  J: Integer;
  Symbol: TDocSymbol;
  UnitModel: TDocUnit;
begin
  Result := 0;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    for J := 0 to UnitModel.Symbols.Count - 1 do
    begin
      Symbol := TDocSymbol(UnitModel.Symbols[J]);
      if (Symbol.Kind in AKinds) and
        IsEffectivelyRenderable(UnitModel, Symbol) then
        Inc(Result);
    end;
  end;
end;

function TotalIndexedSymbolCount(AProject: TDocProject): Integer;
begin
  Result := CountIndexedSymbols(AProject, TypeKinds) +
    CountIndexedSymbols(AProject, RoutineKinds) +
    CountIndexedSymbols(AProject, MemberKinds) +
    CountIndexedSymbols(AProject, ConstantKinds) +
    CountIndexedSymbols(AProject, VariableKinds);
end;

function TotalDocumentedIndexedSymbolCount(AProject: TDocProject): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to AProject.Units.Count - 1 do
    Inc(Result, DocumentedIndexedSymbolCount(TDocUnit(AProject.Units[I])));
end;

procedure RenderBrowseAPISection(var AOutput: UTF8String;
  AProject: TDocProject);
begin
  AppendLine(AOutput, '<section class="index-section browse-section">');
  AppendLine(AOutput, '<div class="section-heading"><div><p ' +
    'class="eyebrow">Reference</p><h2>Browse API</h2></div><p>Browse ' +
    'symbols by name or filter by kind.</p></div>');
  AppendLine(AOutput, '<a class="browse-card" href="' +
    HTMLSymbolIndexFilename + '">');
  AppendLine(AOutput, '<span class="browse-count">' +
    UTF8String(IntToStr(TotalIndexedSymbolCount(AProject))) + '</span>');
  AppendLine(AOutput, '<strong>Symbols Index</strong><span>Every public API ' +
    'symbol, indexed by name and filterable by kind.</span></a>');
  AppendLine(AOutput, '<a class="browse-card" href="' +
    HTMLSymbolIndexFilename + '#types"><strong>Types</strong><span>' +
    UTF8String(IntToStr(CountIndexedSymbols(AProject,
    TypeKinds))) + ' symbols</span></a>');
  AppendLine(AOutput, '<a class="browse-card" href="' +
    HTMLSymbolIndexFilename + '#routines"><strong>Routines</strong><span>' +
    UTF8String(IntToStr(CountIndexedSymbols(AProject,
    RoutineKinds))) + ' symbols</span></a>');
  AppendLine(AOutput, '<a class="browse-card" href="' +
    HTMLSymbolIndexFilename + '#members"><strong>Members</strong><span>' +
    UTF8String(IntToStr(CountIndexedSymbols(AProject,
    MemberKinds))) + ' symbols</span></a>');
  AppendLine(AOutput, '<a class="browse-card" href="' +
    HTMLSymbolIndexFilename + '#constants"><strong>Constants</strong><span>' +
    UTF8String(IntToStr(CountIndexedSymbols(AProject,
    ConstantKinds))) + ' symbols</span></a>');
  AppendLine(AOutput, '<a class="browse-card" href="' +
    HTMLSymbolIndexFilename + '#variables"><strong>Variables</strong><span>' +
    UTF8String(IntToStr(CountIndexedSymbols(AProject,
    VariableKinds))) + ' symbols</span></a>');
  AppendLine(AOutput, '</section>');
end;

function SymbolIndexLetter(ASymbol: TDocSymbol): Char;
var
  C: Char;
begin
  if Length(ASymbol.Name) = 0 then
    Exit('#');
  C := UpCase(ASymbol.Name[1]);
  if (C >= 'A') and (C <= 'Z') then
    Result := C
  else
    Result := '#';
end;

function SymbolLetterSectionID(ALetter: Char): string;
begin
  if ALetter = '#' then
    Result := 'symbol-other'
  else
    Result := 'symbol-' + LowerCase(ALetter);
end;

function RenderHTMLSymbolIndex(AProject: TDocProject): UTF8String;
var
  Entries: TStringList;
  Entry: TIndexedSymbolEntry;
  GroupName: string;
  I: Integer;
  J: Integer;
  Letter: Char;
  PresentLetters: TStringList;
  Symbol: TDocSymbol;
  UnitModel: TDocUnit;
begin
  Result := PageStart(AProject, AProject.Name + ' symbols', '',
    'Symbol index for ' + AProject.Name, False, 'symbols');
  AppendLine(Result, '<nav class="breadcrumb" aria-label="Breadcrumb">' +
    '<a href="index.html">API index</a><span aria-hidden="true">/' +
    '</span><span>Symbols Index</span></nav>');
  AppendLine(Result, '<section class="symbol-index-heading">');
  AppendLine(Result, '<p class="eyebrow">Reference</p><h1>Symbols Index</h1>');
  AppendLine(Result, '<p>Public API symbols indexed by name and grouped ' +
    'into navigable sections.</p>');
  AppendLine(Result, '</section>');
  AppendLine(Result, '<section class="symbol-index" data-symbol-index>');

  Entries := TOrdinalStringList.Create;
  PresentLetters := TStringList.Create;
  try
    Entries.Sorted := True;
    Entries.CaseSensitive := True;
    Entries.Duplicates := dupAccept;
    PresentLetters.Duplicates := dupIgnore;
    for I := 0 to AProject.Units.Count - 1 do
    begin
      UnitModel := TDocUnit(AProject.Units[I]);
      for J := 0 to UnitModel.Symbols.Count - 1 do
      begin
        Symbol := TDocSymbol(UnitModel.Symbols[J]);
        if not IsEffectivelyRenderable(UnitModel, Symbol) then
          Continue;
        if SymbolIndexGroupName(Symbol.Kind) = '' then
          Continue;
        Entry := TIndexedSymbolEntry.Create(Symbol, UnitModel);
        Entries.AddObject(SymbolIndexSortKey(Symbol), Entry);
        Letter := SymbolIndexLetter(Symbol);
        PresentLetters.Add(Letter);
      end;
    end;

    AppendLine(Result, '<nav class="letter-bar" aria-label="Symbol index ' +
      'sections">');
    for Letter := 'A' to 'Z' do
      if PresentLetters.IndexOf(Letter) >= 0 then
        AppendLine(Result, '<a href="#' + SymbolLetterSectionID(Letter) +
          '">' + Letter + '</a>');
    if PresentLetters.IndexOf('#') >= 0 then
      AppendLine(Result, '<a href="#' + SymbolLetterSectionID('#') + '">#</a>');
    AppendLine(Result, '</nav>');

    AppendLine(Result, '<fieldset class="symbol-filters">');
    AppendLine(Result, '<legend>Filter categories</legend>');
    AppendLine(Result, '<label><input type="checkbox" value="types" ' +
      'data-symbol-filter checked> Types</label>');
    AppendLine(Result, '<label><input type="checkbox" value="routines" ' +
      'data-symbol-filter checked> Routines</label>');
    AppendLine(Result, '<label><input type="checkbox" value="members" ' +
      'data-symbol-filter checked> Members</label>');
    AppendLine(Result, '<label><input type="checkbox" value="constants" ' +
      'data-symbol-filter checked> Constants</label>');
    AppendLine(Result, '<label><input type="checkbox" value="variables" ' +
      'data-symbol-filter checked> Variables</label>');
    AppendLine(Result, '</fieldset>');
    AppendLine(Result, '<p class="symbol-status" data-symbol-status ' +
      'role="status" aria-live="polite">' +
      UTF8String(IntToStr(Entries.Count)) + ' symbols</p>');

    for Letter := 'A' to 'Z' do
    begin
      if PresentLetters.IndexOf(Letter) < 0 then
        Continue;
      AppendLine(Result, '<section id="' + SymbolLetterSectionID(Letter) +
        '" class="symbol-letter" data-symbol-letter>');
      AppendLine(Result, '<h2>' + Letter + '</h2>');
      AppendLine(Result, '<ul class="symbol-index-list">');
      for I := 0 to Entries.Count - 1 do
      begin
        Entry := TIndexedSymbolEntry(Entries.Objects[I]);
        if SymbolIndexLetter(Entry.Symbol) <> Letter then
          Continue;
        GroupName := SymbolIndexGroupName(Entry.Symbol.Kind);
        AppendLine(Result, '<li class="symbol-index-entry" ' +
          'data-symbol-entry data-symbol-kind="' + GroupName + '"><span ' +
          'class="kind-badge">' +
          EscapeHTML(SymbolKindName(Entry.Symbol.Kind)) + '</span><a href="' +
          'units/' + EscapeHTML(HTMLUnitFilename(Entry.UnitModel)) + '#' +
          EscapeHTML(HTMLSymbolAnchor(Entry.Symbol)) + '"><code>' +
          EscapeHTML(Entry.Symbol.Name) + '</code></a><span ' +
          'class="symbol-index-unit">' + EscapeHTML(Entry.UnitModel.Name) +
          '</span></li>');
      end;
      AppendLine(Result, '</ul></section>');
    end;

    if PresentLetters.IndexOf('#') >= 0 then
    begin
      AppendLine(Result, '<section id="' + SymbolLetterSectionID('#') +
        '" class="symbol-letter" data-symbol-letter>');
      AppendLine(Result, '<h2>#</h2>');
      AppendLine(Result, '<ul class="symbol-index-list">');
      for I := 0 to Entries.Count - 1 do
      begin
        Entry := TIndexedSymbolEntry(Entries.Objects[I]);
        if SymbolIndexLetter(Entry.Symbol) <> '#' then
          Continue;
        GroupName := SymbolIndexGroupName(Entry.Symbol.Kind);
        AppendLine(Result, '<li class="symbol-index-entry" ' +
          'data-symbol-entry data-symbol-kind="' + GroupName + '"><span ' +
          'class="kind-badge">' +
          EscapeHTML(SymbolKindName(Entry.Symbol.Kind)) + '</span><a href="' +
          'units/' + EscapeHTML(HTMLUnitFilename(Entry.UnitModel)) + '#' +
          EscapeHTML(HTMLSymbolAnchor(Entry.Symbol)) + '"><code>' +
          EscapeHTML(Entry.Symbol.Name) + '</code></a><span ' +
          'class="symbol-index-unit">' + EscapeHTML(Entry.UnitModel.Name) +
          '</span></li>');
      end;
      AppendLine(Result, '</ul></section>');
    end;
  finally
    PresentLetters.Free;
    for I := 0 to Entries.Count - 1 do
      TIndexedSymbolEntry(Entries.Objects[I]).Free;
    Entries.Free;
  end;
  AppendLine(Result, '</section>');
  AppendPageEnd(Result, AProject);
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
    'API documentation for ' + AProject.Name, AProject.Units.Count > 0,
    'index');
  PublicCount := TotalIndexedSymbolCount(AProject);
  DocumentedCount := TotalDocumentedIndexedSymbolCount(AProject);
  if PublicCount > 0 then
    CoveragePercent := (DocumentedCount * 100) div PublicCount
  else
    CoveragePercent := 100;

  AppendLine(Result, '<section class="hero">');
  AppendLine(Result, '<p class="eyebrow">Free Pascal API reference</p>');
  AppendLine(Result, '<h1>' + EscapeHTML(AProject.Name) + '</h1>');
  AppendLine(Result, '<p class="hero-copy">Browse the API using the ' +
    'symbol index, explore individual units, or search the complete public ' +
    'API reference.</p>');
  AppendLine(Result, '<p class="source-root">Source root <code>' +
    EscapeHTML(AProject.SourceRoot) + '</code></p>');
  AppendLine(Result, '</section>');
  AppendLine(Result, '<section class="stats" aria-label="Project totals">');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(AProject.Units.Count)) +
    '</strong><span>Units</span></div>');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(AProject.SymbolCount)) +
    '</strong><span>Parsed declarations</span></div>');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(PublicCount)) +
    '</strong><span>Public API symbols</span></div>');
  AppendLine(Result, '<div class="stat"><strong>' +
    UTF8String(IntToStr(CoveragePercent)) +
    '%</strong><span>Documented</span></div>');
  AppendLine(Result, '</section>');

  RenderBrowseAPISection(Result, AProject);

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
        UTF8String(IntToStr(IndexedSymbolCount(UnitModel))) +
        '</td><td class="number">' +
        UTF8String(IntToStr(DocumentedIndexedSymbolCount(UnitModel))) +
        '</td></tr>');
    end;
  finally
    Units.Free;
  end;
  AppendLine(Result, '</tbody></table></div></section>');

  RenderDependencyOverview(Result, AProject);
  RenderTypeRelationshipOverview(Result, AProject);

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
  RenderUnitPageNavigation(Result, AProject, AUnit);
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
  WriteOutputFile(IncludeTrailingPathDelimiter(AOutputDirectory) + 'index.html',
    RenderHTMLIndex(AProject));
  WriteOutputFile(IncludeTrailingPathDelimiter(AOutputDirectory) +
    HTMLSymbolIndexFilename, RenderHTMLSymbolIndex(AProject));
  WriteOutputFile(IncludeTrailingPathDelimiter(AssetsDirectory) + 'site.css',
    HTMLStylesheet(AProject));
  WriteOutputFile(IncludeTrailingPathDelimiter(AssetsDirectory) + 'app.js',
    HTMLApplicationScript);
  WriteOutputFile(IncludeTrailingPathDelimiter(AssetsDirectory) + 'math.js',
    HTMLMathScript);
  WriteOutputFile(IncludeTrailingPathDelimiter(AssetsDirectory) + 'diagram.js',
    HTMLDiagramScript);
  WriteOutputFile(IncludeTrailingPathDelimiter(AssetsDirectory) +
    'search-index.js', RenderHTMLSearchIndex(AProject));

  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      WriteOutputFile(IncludeTrailingPathDelimiter(UnitsDirectory) +
        HTMLUnitFilename(UnitModel), RenderHTMLUnit(AProject, UnitModel));
    end;
  finally
    Units.Free;
  end;
end;

end.
