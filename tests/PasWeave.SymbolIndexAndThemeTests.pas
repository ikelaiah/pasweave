unit PasWeave.SymbolIndexAndThemeTests;

{$mode objfpc}{$H+}

interface

procedure RunSymbolIndexAndThemeTests;

implementation

uses
  SysUtils, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.HTML, PasWeave.Render.HTML.Assets,
  PasWeave.Render.Support;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('discovery test failed: ' + AMessage);
end;

function FindUnit(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
end;

procedure CheckSymbolIndexContracts;
var
  AttemptedCount: Integer;
  IndexHTML: UTF8String;
  LetterPositions: array[1..5] of Integer;
  Project: TDocProject;
  SymbolHTML: UTF8String;
begin
  Check(HTMLSymbolIndexFilename = 'symbols.html',
    'the A–Z symbol index should use a stable route');
  Project := BuildProject('tests/fixtures/SimpleUnit.pas',
    'Symbol index', AttemptedCount);
  try
    Check((AttemptedCount = 1) and (Project.Units.Count = 1),
      'symbol index fixture should parse one unit');
    SymbolHTML := RenderHTMLSymbolIndex(Project);
    Check(Pos('<!doctype html>', string(SymbolHTML)) = 1,
      'the symbol index should be a complete HTML document');
    Check(Pos('<section class="symbol-index" data-symbol-index>',
      string(SymbolHTML)) > 0,
      'the symbol index should expose its progressive-enhancement hook');
    Check(Pos('data-symbol-filter', string(SymbolHTML)) > 0,
      'the symbol index should expose kind filters');
    Check(Pos('data-symbol-entry', string(SymbolHTML)) > 0,
      'the symbol index should tag every entry for client filtering');
    Check(Pos('data-symbol-kind="types"', string(SymbolHTML)) > 0,
      'symbol entries should carry their kind group');
    Check(Pos('value="types"', string(SymbolHTML)) > 0,
      'the symbol index should expose a types filter');
    Check(Pos('value="routines"', string(SymbolHTML)) > 0,
      'the symbol index should expose a routines filter');
    Check(Pos('value="members"', string(SymbolHTML)) > 0,
      'the symbol index should expose a members filter');
    Check(Pos('value="constants"', string(SymbolHTML)) > 0,
      'the symbol index should expose a constants filter');
    Check(Pos('value="variables"', string(SymbolHTML)) > 0,
      'the symbol index should expose a variables filter');
    Check(Pos('data-symbol-kind="unit"', string(SymbolHTML)) = 0,
      'the symbol index should omit unit symbols');
    Check(Pos('class="letter-bar"', string(SymbolHTML)) > 0,
      'the symbol index should provide alphabetical section links');
    Check(Pos('data-symbol-letter', string(SymbolHTML)) > 0,
      'the symbol index should group symbols into letter sections');
    Check(Pos('data-symbol-status', string(SymbolHTML)) > 0,
      'the symbol index should announce its live filtered count');
    Check(Pos('>7 symbols</p>', string(SymbolHTML)) > 0,
      'the symbol index should count every renderable non-unit symbol');
    Check(Pos('href="units/SimpleUnit.html#', string(SymbolHTML)) > 0,
      'the symbol index should link every entry to its stable anchor');
    Check(Pos('aria-current="page"', string(SymbolHTML)) > 0,
      'the symbol index should mark itself as the current section');
    Check(Pos('href="symbols.html" aria-current="page">Symbols Index</a>',
      string(SymbolHTML)) > 0,
      'the header should mark the symbol index as current');
    Check(Pos('<h1>Symbols Index</h1>', string(SymbolHTML)) > 0,
      'the symbol index should use the professional visible label');
    Check(Pos('href="index.html">Units</a>', string(SymbolHTML)) > 0,
      'the symbol index header should retain the units destination');
    LetterPositions[1] := Pos('id="symbol-a"', string(SymbolHTML));
    LetterPositions[2] := Pos('id="symbol-g"', string(SymbolHTML));
    LetterPositions[3] := Pos('id="symbol-r"', string(SymbolHTML));
    LetterPositions[4] := Pos('id="symbol-t"', string(SymbolHTML));
    LetterPositions[5] := Pos('id="symbol-v"', string(SymbolHTML));
    Check((LetterPositions[1] > 0) and (LetterPositions[2] > 0) and
      (LetterPositions[3] > 0) and (LetterPositions[4] > 0) and
      (LetterPositions[5] > 0),
      'the symbol index should render every present letter section');
    Check(Pos('id="symbol-b"', string(SymbolHTML)) = 0,
      'the symbol index should omit empty letter sections');
    Check(SymbolHTML = RenderHTMLSymbolIndex(Project),
      'repeated symbol-index rendering should be deterministic');

    IndexHTML := RenderHTMLIndex(Project);
    Check(Pos('<h2>Browse API</h2>', string(IndexHTML)) > 0,
      'the project index should lead readers toward the A–Z symbol index');
    Check(Pos('href="symbols.html"', string(IndexHTML)) > 0,
      'the project index should link the A–Z symbol index');
    Check(Pos('class="browse-count">7</span>', string(IndexHTML)) > 0,
      'the Browse API card should report the indexed symbol total');
    Check(Pos('href="symbols.html#types"', string(IndexHTML)) > 0,
      'the Browse API section should link the types category');
    Check(Pos('href="symbols.html#routines"', string(IndexHTML)) > 0,
      'the Browse API section should link the routines category');
    Check(Pos('href="symbols.html#members"', string(IndexHTML)) > 0,
      'the Browse API section should link the members category');
    Check(Pos('href="symbols.html#constants"', string(IndexHTML)) > 0,
      'the Browse API section should link the constants category');
    Check(Pos('href="symbols.html#variables"', string(IndexHTML)) > 0,
      'the Browse API section should link the variables category');
    Check(Pos('aria-current="page"', string(IndexHTML)) > 0,
      'the project index should mark itself as the current section');
    Check(Pos('href="index.html" aria-current="page"',
      string(IndexHTML)) > 0,
      'the header should mark the units destination as current');
    Check(Pos('href="symbols.html"', string(IndexHTML)) > 0,
      'the header should persist the symbol-index destination');
  finally
    Project.Free;
  end;

  Project := BuildProject('tests/fixtures/dependencies',
    'Index ordering', AttemptedCount);
  try
    IndexHTML := RenderHTMLIndex(Project);
    LetterPositions[1] := Pos('<h2>Browse API</h2>', string(IndexHTML));
    LetterPositions[2] := Pos('<h2>Units</h2>', string(IndexHTML));
    LetterPositions[3] := Pos('<h2 id="unit-dependencies">',
      string(IndexHTML));
    LetterPositions[4] := Pos('<h2>Diagnostics</h2>', string(IndexHTML));
    Check((LetterPositions[1] > 0) and (LetterPositions[2] > 0) and
      (LetterPositions[3] > 0) and
      (LetterPositions[1] < LetterPositions[2]) and
      (LetterPositions[2] < LetterPositions[3]),
      'the project index should order summary, Browse API, units, then ' +
      'architecture');
  finally
    Project.Free;
  end;

  Project := BuildProject('tests/fixtures/relationships',
    'Relationship ordering', AttemptedCount);
  try
    IndexHTML := RenderHTMLIndex(Project);
    LetterPositions[1] := Pos('<h2>Units</h2>', string(IndexHTML));
    LetterPositions[2] := Pos('<h2 id="unit-dependencies">',
      string(IndexHTML));
    LetterPositions[3] := Pos('<h2 id="type-relationships">',
      string(IndexHTML));
    Check((LetterPositions[1] > 0) and (LetterPositions[2] > 0) and
      (LetterPositions[3] > 0) and
      (LetterPositions[1] < LetterPositions[2]) and
      (LetterPositions[2] < LetterPositions[3]),
      'relationship diagrams should follow the units table and dependency ' +
      'overview');
  finally
    Project.Free;
  end;

  Project := BuildProject('tests/fixtures/partial',
    'Diagnostics ordering', AttemptedCount);
  try
    IndexHTML := RenderHTMLIndex(Project);
    LetterPositions[1] := Pos('<h2>Browse API</h2>', string(IndexHTML));
    LetterPositions[2] := Pos('<h2>Units</h2>', string(IndexHTML));
    LetterPositions[3] := Pos('<h2 id="unit-dependencies">',
      string(IndexHTML));
    LetterPositions[4] := Pos('<h2>Diagnostics</h2>', string(IndexHTML));
    Check((LetterPositions[1] > 0) and (LetterPositions[2] > 0) and
      (LetterPositions[3] > 0) and (LetterPositions[4] > 0) and
      (LetterPositions[1] < LetterPositions[2]) and
      (LetterPositions[2] < LetterPositions[3]) and
      (LetterPositions[3] < LetterPositions[4]),
      'diagnostics should remain the final index section');
  finally
    Project.Free;
  end;
end;

procedure CheckThemeContracts;
var
  AttemptedCount: Integer;
  IndexHTML: UTF8String;
  Project: TDocProject;
  Script: UTF8String;
  Stylesheet: UTF8String;
  UnitHTML: UTF8String;
  UnitModel: TDocUnit;
  Bootstrap: UTF8String;
begin
  Bootstrap := HTMLThemeBootstrap;
  Check(Pos('"use strict"', string(Bootstrap)) > 0,
    'theme bootstrap should be a strict dependency-free script');
  Check(Pos('window.localStorage.getItem("pasweave-theme")',
    string(Bootstrap)) > 0,
    'theme bootstrap should read the persisted reader choice');
  Check(Pos('catch (error)', string(Bootstrap)) > 0,
    'theme bootstrap should tolerate unavailable browser storage');
  Check(Pos('stored = null', string(Bootstrap)) > 0,
    'theme bootstrap should fall back when storage is rejected');
  Check(Pos('"system"', string(Bootstrap)) > 0,
    'theme bootstrap should default to the System scheme');
  Check(Pos('setAttribute("data-theme", theme)', string(Bootstrap)) > 0,
    'theme bootstrap should publish the scheme before rendering');

  Project := BuildProject('tests/fixtures/SimpleUnit.pas',
    'Reader themes', AttemptedCount);
  try
    UnitModel := TDocUnit(Project.Units[0]);
    IndexHTML := RenderHTMLIndex(Project);
    UnitHTML := RenderHTMLUnit(Project, UnitModel);
    Check(Pos('data-theme-control', string(IndexHTML)) > 0,
      'every page should expose the reader theme control');
    Check(Pos('data-theme-select', string(IndexHTML)) > 0,
      'the theme control should expose a labelled select');
    Check(Pos('<option value="system">System</option>',
      string(IndexHTML)) > 0,
      'the theme control should offer the System choice');
    Check(Pos('<option value="light">Light</option>',
      string(IndexHTML)) > 0,
      'the theme control should offer the Light choice');
    Check(Pos('<option value="dark">Dark</option>',
      string(IndexHTML)) > 0,
      'the theme control should offer the Dark choice');
    Check(Pos('class="theme-control" hidden data-theme-control>',
      string(IndexHTML)) > 0,
      'the theme control should stay hidden until JavaScript runs');
    Check(Pos('data-theme-control', string(UnitHTML)) > 0,
      'unit pages should expose the same theme control');
    Check(Pos('href="index.html"', string(IndexHTML)) > 0,
      'the header should link the units destination');
    Check(Pos('href="symbols.html"', string(IndexHTML)) > 0,
      'the header should link the symbol-index destination on the index');
    Check(Pos('href="../symbols.html"', string(UnitHTML)) > 0,
      'the header should link the symbol-index destination on unit pages');
    Check(Pos('data-theme', string(IndexHTML)) > 0,
      'the theme bootstrap should be embedded in the project index');
    Check(Pos('data-theme', string(UnitHTML)) > 0,
      'the theme bootstrap should be embedded in every unit page');

    Stylesheet := HTMLStylesheet(Project);
    Check(Pos('--accent: #5b4ee6;', string(Stylesheet)) > 0,
      'the default stylesheet should retain the primary accent token');
    Check(Pos('--accent-2: #0e8f81;', string(Stylesheet)) > 0,
      'the default stylesheet should retain the secondary accent token');
    Check(Pos('--font-family: "Inter";', string(Stylesheet)) > 0,
      'the default stylesheet should retain the default font token');
    Check(Pos('color-scheme: light;', string(Stylesheet)) > 0,
      'light pages should expose a light native color scheme');
    Check(Pos(':root[data-theme="dark"]', string(Stylesheet)) > 0,
      'an explicit dark choice should select dark tokens');
    Check(Pos(':root:not([data-theme="light"])', string(Stylesheet)) > 0,
      'the System scheme should follow prefers-color-scheme');
    Check(Pos('@media (prefers-color-scheme: dark)', string(Stylesheet)) > 0,
      'the System scheme should follow the operating system');
    Check(Pos('color-scheme: dark;', string(Stylesheet)) > 0,
      'dark pages should expose a dark native color scheme');

    Project.ThemeAccent := '#123456';
    Project.ThemeAccentAlt := '#abcdef';
    Project.ThemeFont := 'Avenir Next';
    Project.ProjectMark := 'FPC';
    Stylesheet := HTMLStylesheet(Project);
    Check(Pos('--accent: #123456;', string(Stylesheet)) > 0,
      'custom accent tokens should reach the stylesheet');
    Check(Pos('--accent-2: #abcdef;', string(Stylesheet)) > 0,
      'custom secondary accent tokens should reach the stylesheet');
    Check(Pos('--font-family: "Avenir Next";', string(Stylesheet)) > 0,
      'custom typography tokens should reach the stylesheet');
    Check(LightenThemeColor('#123456', 40) = '#708599',
      'custom accents should receive a deterministic dark variant');
    IndexHTML := RenderHTMLIndex(Project);
    Check(Pos('brand-mark" aria-hidden="true">FPC<',
      string(IndexHTML)) > 0,
      'a custom project mark should replace the brand mark');
    Check(Pos('"projectMark" : "FPC"', string(ProjectToJSON(Project))) > 0,
      'JSON should expose the configured project mark');
    Check(Pos('"themeAccent" : "#123456"', string(ProjectToJSON(Project))) > 0,
      'JSON should expose the configured accent token');
    Check(Pos('"themeAccentAlt" : "#abcdef"',
      string(ProjectToJSON(Project))) > 0,
      'JSON should expose the configured secondary accent token');
    Check(Pos('"themeFont" : "Avenir Next"',
      string(ProjectToJSON(Project))) > 0,
      'JSON should expose the configured typography token');
  finally
    Project.Free;
  end;

  Script := HTMLApplicationScript;
  Check(Pos('[data-theme-control]', string(Script)) > 0,
    'the application script should wire the theme control');
  Check(Pos('[data-theme-select]', string(Script)) > 0,
    'the application script should read the theme select');
  Check(Pos('pasweave-theme', string(Script)) > 0,
    'the application script should persist the reader choice');
  Check(Pos('window.localStorage.setItem', string(Script)) > 0,
    'the application script should write the stored choice');
  Check(Pos('catch (error)', string(Script)) > 0,
    'the application script should tolerate storage rejection');
  Check(Pos('pasweave:themechange', string(Script)) > 0,
    'the application script should announce theme changes');
  Check(Pos('new window.CustomEvent', string(Script)) > 0,
    'the theme change announcement should use a CustomEvent');
  Check(Pos('[data-symbol-filter]', string(Script)) > 0,
    'the application script should filter the symbol index by kind');
  Check(Pos('[data-symbol-entry]', string(Script)) > 0,
    'the application script should read symbol-index entries');
  Check(Pos('entry.hidden = !shown', string(Script)) > 0,
    'symbol filtering should hide non-matching native entries');
  Check(Pos('symbolStatus.textContent', string(Script)) > 0,
    'symbol filtering should announce the live filtered count');
  Check(Pos('applySymbolHash', string(Script)) > 0,
    'symbol filtering should honour category deep links');

  Script := HTMLDiagramScript;
  Check(Pos('function activeScheme()', string(Script)) > 0,
    'diagram rendering should resolve the active reader scheme');
  Check(Pos('getAttribute("data-theme")', string(Script)) > 0,
    'diagram rendering should read the published scheme');
  Check(Pos('pasweave:themechange', string(Script)) > 0,
    'diagrams should re-render when the reader scheme changes');
  Check(Pos('renderDiagrams()', string(Script)) > 0,
    'diagram rendering should be re-invocable');
end;

procedure CheckBrandingValidation;
begin
  Check(IsValidProjectMark('PW'), 'the default mark should be valid');
  Check(IsValidProjectMark('FPC'), 'three-character marks should be valid');
  Check(IsValidProjectMark('Z9'), 'alphanumeric marks should be valid');
  Check(not IsValidProjectMark(''), 'empty marks should be rejected');
  Check(not IsValidProjectMark('TOOLONG'), 'overlong marks should be rejected');
  Check(not IsValidProjectMark('A B'), 'marks with spaces should be rejected');
  Check(not IsValidProjectMark('A-B'), 'marks with symbols should be rejected');

  Check(IsValidThemeColor('#5b4ee6'), 'six-digit colors should be valid');
  Check(IsValidThemeColor('#abc'), 'three-digit colors should be valid');
  Check(IsValidThemeColor('#aabbccdd'), 'eight-digit colors should be valid');
  Check(not IsValidThemeColor('5b4ee6'), 'colors need a leading hash');
  Check(not IsValidThemeColor('#5b4e'), 'invalid digit counts should fail');
  Check(not IsValidThemeColor('#zzzzzz'), 'non-hex digits should fail');
  Check(not IsValidThemeColor('#5b4ee6;'), 'CSS injection should fail');

  Check(IsValidThemeFont('Inter'), 'single family names should be valid');
  Check(IsValidThemeFont('Avenir Next'), 'multi-word names should be valid');
  Check(IsValidThemeFont('Fira Code 2'), 'names with digits should be valid');
  Check(not IsValidThemeFont(''), 'empty font names should be rejected');
  Check(not IsValidThemeFont('-Inter'), 'leading hyphens should be rejected');
  Check(not IsValidThemeFont('Inter;'), 'CSS injection should fail');
  Check(not IsValidThemeFont('Inter}/style'), 'symbols should be rejected');
end;

procedure RunSymbolIndexAndThemeTests;
begin
  CheckSymbolIndexContracts;
  CheckThemeContracts;
  CheckBrandingValidation;
end;

end.