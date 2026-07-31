unit PasWeave.Render.HTML;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

function HTMLUnitFilename(AUnit: TDocUnit): string;
function HTMLSymbolAnchor(ASymbol: TDocSymbol): string;
function RenderHTMLIndex(AProject: TDocProject): UTF8String;
function RenderHTMLUnit(AProject: TDocProject; AUnit: TDocUnit): UTF8String;
function RenderHTMLSearchIndex(AProject: TDocProject): UTF8String;
procedure WriteHTMLDocumentation(AProject: TDocProject;
  const AOutputDirectory: string);

implementation

uses
  Classes, SysUtils, FPJSON, PasWeave.Diagnostics,
  PasWeave.Render.Support, PasWeave.Render.HTML.Markdown,
  PasWeave.Render.HTML.Assets;

type
  TSymbolKinds = set of TSymbolKind;

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

function FindSymbolByID(AUnit: TDocUnit; const AID: string): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  if AID = '' then
    Exit;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if TDocSymbol(AUnit.Symbols[I]).ID = AID then
      Exit(TDocSymbol(AUnit.Symbols[I]));
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
      Result.AddObject(Symbol.QualifiedName + #1 + Symbol.ID, Symbol);
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

function FindSymbolReference(AProject: TDocProject; ACurrentUnit: TDocUnit;
  const AReference: string; out ATargetUnit: TDocUnit): TDocSymbol;
var
  I: Integer;
  J: Integer;
  Candidate: TDocSymbol;
  UnitModel: TDocUnit;
  UniqueNameMatch: TDocSymbol;
  UniqueNameUnit: TDocUnit;
  NameMatchCount: Integer;
begin
  Result := nil;
  ATargetUnit := nil;
  UniqueNameMatch := nil;
  UniqueNameUnit := nil;
  NameMatchCount := 0;
  if AReference = '' then
    Exit;

  for I := 0 to ACurrentUnit.Symbols.Count - 1 do
  begin
    Candidate := TDocSymbol(ACurrentUnit.Symbols[I]);
    if SameText(Candidate.ID, AReference) or
       SameText(Candidate.QualifiedName, AReference) or
       SameText(Candidate.QualifiedName,
         ACurrentUnit.Name + '.' + AReference) then
    begin
      ATargetUnit := ACurrentUnit;
      Exit(Candidate);
    end;
  end;

  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    for J := 0 to UnitModel.Symbols.Count - 1 do
    begin
      Candidate := TDocSymbol(UnitModel.Symbols[J]);
      if SameText(Candidate.ID, AReference) or
         SameText(Candidate.QualifiedName, AReference) then
      begin
        ATargetUnit := UnitModel;
        Exit(Candidate);
      end;
      if SameText(Candidate.Name, AReference) then
      begin
        Inc(NameMatchCount);
        if NameMatchCount = 1 then
        begin
          UniqueNameMatch := Candidate;
          UniqueNameUnit := UnitModel;
        end;
      end;
    end;
  end;

  if NameMatchCount = 1 then
  begin
    Result := UniqueNameMatch;
    ATargetUnit := UniqueNameUnit;
  end;
end;

function SymbolLocation(ASymbol: TDocSymbol): string;
begin
  Result := ASymbol.SourceFilename;
  if ASymbol.SourceLine > 0 then
  begin
    Result := Result + ':' + IntToStr(ASymbol.SourceLine);
    if ASymbol.SourceColumn > 0 then
      Result := Result + ':' + IntToStr(ASymbol.SourceColumn);
  end;
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

function LinkToSymbol(AProject: TDocProject; ACurrentUnit: TDocUnit;
  const AReference: string): UTF8String;
var
  TargetSymbol: TDocSymbol;
  TargetUnit: TDocUnit;
  Target: string;
begin
  TargetSymbol := FindSymbolReference(AProject, ACurrentUnit, AReference,
    TargetUnit);
  if not Assigned(TargetSymbol) or not Assigned(TargetUnit) then
    Exit('<code>' + EscapeHTML(AReference) + '</code>');
  if TargetUnit = ACurrentUnit then
    Target := '#' + HTMLSymbolAnchor(TargetSymbol)
  else
    Target := HTMLUnitFilename(TargetUnit) + '#' +
      HTMLSymbolAnchor(TargetSymbol);
  Result := '<a href="' + EscapeHTML(Target) + '"><code>' +
    EscapeHTML(AReference) + '</code></a>';
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
        AppendLine(AOutput, '<li>' + LinkToSymbol(AProject, AUnit,
          Directive.Subject) + ' &mdash; ' +
          RenderInlineMarkdown(Directive.Text) + '</li>')
      else
        AppendLine(AOutput, '<li>' + LinkToSymbol(AProject, AUnit,
          Directive.Subject) + '</li>');
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

function PageStart(AProject: TDocProject; const ATitle, ARoot,
  ADescription: string): UTF8String;
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
    'data-search-panel hidden><p class="search-status" ' +
    'data-search-status></p><ul data-search-results></ul></div>');
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
  ParentSymbol: TDocSymbol;
  Anchor: string;
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
    '</code></span><span>Source <code>' + EscapeHTML(SymbolLocation(ASymbol)) +
    '</code></span></p>');

  ParentSymbol := FindSymbolByID(AUnit, ASymbol.ParentSymbolID);
  if Assigned(ParentSymbol) and (ParentSymbol.Kind <> skUnit) then
    AppendLine(AOutput, '<p class="parent-link">Parent: <a href="#' +
      EscapeHTML(HTMLSymbolAnchor(ParentSymbol)) + '"><code>' +
      EscapeHTML(ParentSymbol.QualifiedName) + '</code></a></p>');

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
    'API documentation for ' + AProject.Name);
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
      AppendLine(Result, '<li><strong>Warning</strong> <code>' +
        EscapeHTML(DiagnosticLocation(Diagnostic)) + '</code>: ' +
        EscapeHTML(Diagnostic.MessageText) + '</li>');
    end;
    for I := 0 to AProject.Errors.Count - 1 do
    begin
      Diagnostic := TDiagnostic(AProject.Errors[I]);
      AppendLine(Result, '<li><strong>Error</strong> <code>' +
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
    'API documentation for unit ' + AUnit.Name);
  AppendLine(Result, '<nav class="breadcrumb" aria-label="Breadcrumb">' +
    '<a href="../index.html">API index</a><span aria-hidden="true">/' +
    '</span><span>' + EscapeHTML(AUnit.Name) + '</span></nav>');
  AppendLine(Result, '<section class="unit-heading">');
  AppendLine(Result, '<p class="eyebrow">Unit</p><h1><code>' +
    EscapeHTML(AUnit.Name) + '</code></h1>');
  AppendLine(Result, '<p>Declared in <code>' +
    EscapeHTML(AUnit.SourceFilename) + '</code></p></section>');

  ThisUnitSymbol := UnitSymbol(AUnit);
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

  WriteKaTeXAssets(AssetsDirectory);
  WriteUTF8File(IncludeTrailingPathDelimiter(AOutputDirectory) + 'index.html',
    RenderHTMLIndex(AProject));
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'site.css',
    HTMLStylesheet);
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'app.js',
    HTMLApplicationScript);
  WriteUTF8File(IncludeTrailingPathDelimiter(AssetsDirectory) + 'math.js',
    HTMLMathScript);
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
