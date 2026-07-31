unit PasWeave.Render.HTML.Assets;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

const
  KaTeXVersion = '0.18.1';

function HTMLStylesheet: UTF8String;
function HTMLApplicationScript: UTF8String;
function HTMLMathScript: UTF8String;
procedure WriteKaTeXAssets(const AAssetsDirectory: string);

implementation

uses
  Classes, SysUtils, StrUtils;

procedure AppendLine(var AOutput: UTF8String; const ALine: UTF8String = '');
begin
  AOutput := AOutput + ALine + #10;
end;

function HTMLStylesheet: UTF8String;
begin
  Result := '';
  AppendLine(Result, ':root {');
  AppendLine(Result, '  color-scheme: light dark;');
  AppendLine(Result, '  --bg: #f7f8fc; --surface: #ffffff; --surface-2: #eef1f8;');
  AppendLine(Result, '  --text: #172033; --muted: #667085; --line: #dbe1ec;');
  AppendLine(Result, '  --accent: #5b4ee6; --accent-2: #0e8f81; --code: #182034;');
  AppendLine(Result, '  --warning-bg: #fff8e6; --warning-line: #e5a923;');
  AppendLine(Result, '  --shadow: 0 18px 48px rgba(31, 42, 68, .09);');
  AppendLine(Result, '}');
  AppendLine(Result, '* { box-sizing: border-box; }');
  AppendLine(Result, 'html { scroll-behavior: smooth; }');
  AppendLine(Result, 'body { margin: 0; background: var(--bg); color: var(--text); ' +
    'font: 16px/1.65 Inter, ui-sans-serif, system-ui, -apple-system, ' +
    'BlinkMacSystemFont, "Segoe UI", sans-serif; }');
  AppendLine(Result, 'a { color: var(--accent); text-decoration-thickness: .08em; ' +
    'text-underline-offset: .18em; }');
  AppendLine(Result, 'a:hover { color: var(--accent-2); }');
  AppendLine(Result, 'code { font-family: "Cascadia Code", "SFMono-Regular", ' +
    'Consolas, monospace; font-size: .9em; }');
  AppendLine(Result, '.shell { width: min(1180px, calc(100% - 40px)); margin: 0 auto; }');
  AppendLine(Result, '.skip-link { position: fixed; left: 16px; top: -80px; ' +
    'z-index: 100; padding: 10px 14px; background: var(--text); color: ' +
    'var(--surface); border-radius: 8px; }');
  AppendLine(Result, '.skip-link:focus { top: 12px; }');
  AppendLine(Result, '.site-header { position: sticky; top: 0; z-index: 20; ' +
    'background: color-mix(in srgb, var(--surface) 90%, transparent); ' +
    'backdrop-filter: blur(16px); border-bottom: 1px solid var(--line); }');
  AppendLine(Result, '.header-inner { min-height: 72px; display: flex; ' +
    'align-items: center; justify-content: space-between; gap: 28px; }');
  AppendLine(Result, '.brand { display: inline-flex; align-items: center; gap: 12px; ' +
    'color: var(--text); text-decoration: none; line-height: 1.15; }');
  AppendLine(Result, '.brand-mark { width: 38px; height: 38px; display: grid; ' +
    'place-items: center; border-radius: 11px; color: white; font-weight: 800; ' +
    'font-size: .78rem; letter-spacing: .04em; background: linear-gradient(' +
    '135deg, var(--accent), var(--accent-2)); box-shadow: var(--shadow); }');
  AppendLine(Result, '.brand small { display: block; margin-top: 3px; color: ' +
    'var(--muted); font-size: .72rem; font-weight: 600; letter-spacing: .06em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, '.site-search { position: relative; width: min(440px, 48vw); }');
  AppendLine(Result, '.site-search input { width: 100%; height: 42px; padding: ' +
    '0 15px; border: 1px solid var(--line); border-radius: 12px; background: ' +
    'var(--surface-2); color: var(--text); font: inherit; outline: none; }');
  AppendLine(Result, '.site-search input:focus { border-color: var(--accent); ' +
    'box-shadow: 0 0 0 4px color-mix(in srgb, var(--accent) 16%, transparent); }');
  AppendLine(Result, '.search-panel { position: absolute; top: 50px; right: 0; ' +
    'width: min(620px, 88vw); max-height: min(65vh, 560px); overflow: auto; ' +
    'padding: 10px; border: 1px solid var(--line); border-radius: 14px; ' +
    'background: var(--surface); box-shadow: var(--shadow); }');
  AppendLine(Result, '.search-panel[hidden] { display: none; }');
  AppendLine(Result, '.search-status { margin: 4px 8px 8px; color: var(--muted); ' +
    'font-size: .84rem; }');
  AppendLine(Result, '.search-panel ul { list-style: none; margin: 0; padding: 0; }');
  AppendLine(Result, '.search-panel li + li { border-top: 1px solid var(--line); }');
  AppendLine(Result, '.search-result { display: grid; grid-template-columns: 1fr auto; ' +
    'gap: 4px 12px; padding: 10px; color: var(--text); text-decoration: none; ' +
    'border-radius: 9px; }');
  AppendLine(Result, '.search-result:hover { background: var(--surface-2); }');
  AppendLine(Result, '.search-result strong { overflow-wrap: anywhere; }');
  AppendLine(Result, '.search-result small, .search-result span { color: var(--muted); }');
  AppendLine(Result, '.search-result span { font-size: .75rem; text-transform: uppercase; ' +
    'letter-spacing: .06em; }');
  AppendLine(Result, '.search-result small { grid-column: 1 / -1; }');
  AppendLine(Result, '.main-content { padding: 48px 0 80px; }');
  AppendLine(Result, '.hero { padding: 54px; overflow: hidden; border: 1px solid ' +
    'color-mix(in srgb, var(--accent) 24%, var(--line)); border-radius: 28px; ' +
    'background: radial-gradient(circle at 88% 12%, rgba(14,143,129,.18), ' +
    'transparent 32%), linear-gradient(135deg, rgba(91,78,230,.12), ' +
    'var(--surface) 62%); box-shadow: var(--shadow); }');
  AppendLine(Result, '.eyebrow { margin: 0 0 8px; color: var(--accent-2); ' +
    'font-size: .77rem; font-weight: 800; letter-spacing: .13em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, 'h1, h2, h3, h4 { line-height: 1.2; letter-spacing: -.025em; }');
  AppendLine(Result, '.hero h1 { margin: 0; font-size: clamp(2.8rem, 8vw, 5.8rem); }');
  AppendLine(Result, '.hero-copy { max-width: 620px; margin: 18px 0 8px; ' +
    'font-size: 1.2rem; color: var(--muted); }');
  AppendLine(Result, '.source-root { margin: 24px 0 0; color: var(--muted); }');
  AppendLine(Result, '.stats { display: grid; grid-template-columns: repeat(4, 1fr); ' +
    'gap: 14px; margin: 22px 0 52px; }');
  AppendLine(Result, '.stat { padding: 22px; border: 1px solid var(--line); ' +
    'border-radius: 16px; background: var(--surface); }');
  AppendLine(Result, '.stat strong { display: block; font-size: 1.8rem; line-height: 1; }');
  AppendLine(Result, '.stat span { display: block; margin-top: 8px; color: var(--muted); ' +
    'font-size: .85rem; }');
  AppendLine(Result, '.index-section { margin-top: 44px; }');
  AppendLine(Result, '.section-heading, .group-heading { display: flex; align-items: ' +
    'end; justify-content: space-between; gap: 20px; margin-bottom: 18px; }');
  AppendLine(Result, '.section-heading h2, .group-heading h2 { margin: 0; font-size: 1.8rem; }');
  AppendLine(Result, '.section-heading > p { margin: 0; color: var(--muted); }');
  AppendLine(Result, '.group-heading span { min-width: 32px; padding: 3px 9px; ' +
    'border-radius: 999px; background: var(--surface-2); color: var(--muted); ' +
    'font-size: .8rem; text-align: center; }');
  AppendLine(Result, '.table-shell { overflow-x: auto; border: 1px solid var(--line); ' +
    'border-radius: 16px; background: var(--surface); }');
  AppendLine(Result, 'table { width: 100%; border-collapse: collapse; }');
  AppendLine(Result, 'th, td { padding: 13px 16px; border-bottom: 1px solid var(--line); ' +
    'text-align: left; vertical-align: top; }');
  AppendLine(Result, 'tr:last-child td { border-bottom: 0; }');
  AppendLine(Result, 'th { color: var(--muted); font-size: .76rem; letter-spacing: .05em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, '.number { text-align: right; font-variant-numeric: tabular-nums; }');
  AppendLine(Result, '.unit-link { font-weight: 750; }');
  AppendLine(Result, '.diagnostics li { margin: 9px 0; }');
  AppendLine(Result, '.breadcrumb { display: flex; gap: 9px; color: var(--muted); ' +
    'font-size: .86rem; }');
  AppendLine(Result, '.unit-heading { margin: 34px 0 28px; }');
  AppendLine(Result, '.unit-heading h1 { margin: 0; font-size: clamp(2rem, 6vw, 4rem); ' +
    'overflow-wrap: anywhere; }');
  AppendLine(Result, '.unit-heading > p:last-child { color: var(--muted); }');
  AppendLine(Result, '.dependency-section, .symbol-group { margin-top: 46px; }');
  AppendLine(Result, '.dependency-list { display: flex; flex-wrap: wrap; gap: 9px; ' +
    'list-style: none; margin: 0; padding: 0; }');
  AppendLine(Result, '.dependency-list li { padding: 7px 11px; border: 1px solid ' +
    'var(--line); border-radius: 999px; background: var(--surface); }');
  AppendLine(Result, '.symbol { margin: 0 0 22px; padding: 28px; border: 1px solid ' +
    'var(--line); border-radius: 18px; background: var(--surface); ' +
    'box-shadow: 0 6px 18px rgba(31,42,68,.035); scroll-margin-top: 94px; }');
  AppendLine(Result, '.symbol:target { border-color: var(--accent); box-shadow: ' +
    '0 0 0 4px color-mix(in srgb, var(--accent) 13%, transparent), var(--shadow); }');
  AppendLine(Result, '.symbol-heading { display: flex; align-items: start; ' +
    'justify-content: space-between; gap: 20px; }');
  AppendLine(Result, '.symbol-heading h3 { margin: 7px 0 0; font-size: 1.18rem; ' +
    'overflow-wrap: anywhere; }');
  AppendLine(Result, '.kind-badge { display: inline-block; padding: 3px 8px; ' +
    'border-radius: 999px; color: var(--accent-2); background: ' +
    'color-mix(in srgb, var(--accent-2) 10%, transparent); font-size: .7rem; ' +
    'font-weight: 800; letter-spacing: .07em; text-transform: uppercase; }');
  AppendLine(Result, '.permalink { color: var(--muted); font-size: 1.15rem; ' +
    'font-weight: 700; text-decoration: none; }');
  AppendLine(Result, '.symbol-meta { display: flex; flex-wrap: wrap; gap: 8px 20px; ' +
    'margin: 16px 0; color: var(--muted); font-size: .82rem; }');
  AppendLine(Result, '.parent-link { font-size: .9rem; }');
  AppendLine(Result, 'pre { overflow: auto; margin: 18px 0; padding: 18px; ' +
    'border-radius: 13px; background: var(--code); color: #eef2ff; line-height: 1.55; }');
  AppendLine(Result, 'pre code { font-size: .84rem; }');
  AppendLine(Result, '.notice { margin: 18px 0; padding: 12px 15px; ' +
    'border-left: 4px solid var(--warning-line); border-radius: 8px; ' +
    'background: var(--warning-bg); color: #5e460e; }');
  AppendLine(Result, '.deprecated { border-left-color: #d13f61; background: #fff0f3; ' +
    'color: #751b31; }');
  AppendLine(Result, '.prose { max-width: 78ch; }');
  AppendLine(Result, '.prose blockquote { margin-left: 0; padding-left: 18px; ' +
    'border-left: 3px solid var(--line); color: var(--muted); }');
  AppendLine(Result, '.math-display { overflow-x: auto; margin: 20px 0; padding: 18px; ' +
    'border: 1px solid var(--line); border-radius: 12px; background: var(--surface-2); ' +
    'font-family: "Cambria Math", serif; white-space: pre-wrap; text-align: center; }');
  AppendLine(Result, '.math-inline { font-family: "Cambria Math", serif; }');
  AppendLine(Result, '.math-display[data-math-rendered="true"] { white-space: normal; }');
  AppendLine(Result, '.math-inline[data-math-rendered="true"] { font-family: inherit; }');
  AppendLine(Result, '.math-error { color: #b42318; text-decoration: underline dotted; ' +
    'text-underline-offset: .18em; }');
  AppendLine(Result, '.math-display.math-error { text-align: left; }');
  AppendLine(Result, '.directive-section { margin-top: 22px; }');
  AppendLine(Result, '.directive-section h4 { margin-bottom: 9px; }');
  AppendLine(Result, '.directive-section .table-shell { border-radius: 11px; }');
  AppendLine(Result, '.muted { color: var(--muted); }');
  AppendLine(Result, '.site-footer { padding: 28px 0; border-top: 1px solid ' +
    'var(--line); color: var(--muted); font-size: .82rem; }');
  AppendLine(Result, '.sr-only { position: absolute; width: 1px; height: 1px; ' +
    'padding: 0; margin: -1px; overflow: hidden; clip: rect(0,0,0,0); ' +
    'white-space: nowrap; border: 0; }');
  AppendLine(Result, '@media (max-width: 760px) {');
  AppendLine(Result, '  .shell { width: min(100% - 24px, 1180px); }');
  AppendLine(Result, '  .header-inner { min-height: 64px; gap: 12px; }');
  AppendLine(Result, '  .brand small { display: none; }');
  AppendLine(Result, '  .site-search { width: 52vw; }');
  AppendLine(Result, '  .main-content { padding-top: 28px; }');
  AppendLine(Result, '  .hero { padding: 32px 24px; border-radius: 20px; }');
  AppendLine(Result, '  .stats { grid-template-columns: repeat(2, 1fr); }');
  AppendLine(Result, '  .section-heading { align-items: start; flex-direction: column; }');
  AppendLine(Result, '  .symbol { padding: 20px; }');
  AppendLine(Result, '  .symbol-meta { display: grid; }');
  AppendLine(Result, '}');
  AppendLine(Result, '@media (prefers-color-scheme: dark) {');
  AppendLine(Result, '  :root { --bg: #10131c; --surface: #171c28; ' +
    '--surface-2: #202637; --text: #e8ebf4; --muted: #9ba5ba; ' +
    '--line: #30384c; --accent: #a99eff; --accent-2: #63d7ca; ' +
    '--code: #0b0e15; --warning-bg: #332a13; --warning-line: #e5b94f; ' +
    '--shadow: 0 18px 48px rgba(0,0,0,.28); }');
  AppendLine(Result, '  .notice { color: #ffe5a6; }');
  AppendLine(Result, '  .deprecated { background: #361922; color: #ffb7c6; }');
  AppendLine(Result, '}');
end;

function HTMLApplicationScript: UTF8String;
begin
  Result := '';
  AppendLine(Result, '(function () {');
  AppendLine(Result, '  "use strict";');
  AppendLine(Result, '  var input = document.querySelector("[data-search-input]");');
  AppendLine(Result, '  if (!input) return;');
  AppendLine(Result, '  var panel = document.querySelector("[data-search-panel]");');
  AppendLine(Result, '  var list = document.querySelector("[data-search-results]");');
  AppendLine(Result, '  var status = document.querySelector("[data-search-status]");');
  AppendLine(Result, '  var entries = window.PASWEAVE_SEARCH_INDEX || [];');
  AppendLine(Result, '  var root = document.body.dataset.siteRoot || "";');
  AppendLine(Result, '  function searchable(item) {');
  AppendLine(Result, '    return [item.name, item.qualifiedName, item.kind, item.unit, ' +
    'item.summary].join(" ").toLowerCase();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function score(item, query) {');
  AppendLine(Result, '    var name = item.name.toLowerCase();');
  AppendLine(Result, '    var qualified = item.qualifiedName.toLowerCase();');
  AppendLine(Result, '    var value = searchable(item);');
  AppendLine(Result, '    var tokens = query.split(/\s+/).filter(Boolean);');
  AppendLine(Result, '    if (!tokens.every(function (token) { return value.indexOf(token) >= 0; })) return -1;');
  AppendLine(Result, '    var result = item.summary ? 4 : 0;');
  AppendLine(Result, '    if (name === query) result += 1000;');
  AppendLine(Result, '    else if (name.indexOf(query) === 0) result += 500;');
  AppendLine(Result, '    else if (qualified.indexOf(query) === 0) result += 220;');
  AppendLine(Result, '    else if (name.indexOf(query) >= 0) result += 120;');
  AppendLine(Result, '    return result;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function addResult(item) {');
  AppendLine(Result, '    var li = document.createElement("li");');
  AppendLine(Result, '    var link = document.createElement("a");');
  AppendLine(Result, '    link.className = "search-result";');
  AppendLine(Result, '    link.href = root + item.url;');
  AppendLine(Result, '    var title = document.createElement("strong");');
  AppendLine(Result, '    title.textContent = item.qualifiedName;');
  AppendLine(Result, '    var kind = document.createElement("span");');
  AppendLine(Result, '    kind.textContent = item.kind;');
  AppendLine(Result, '    link.appendChild(title);');
  AppendLine(Result, '    link.appendChild(kind);');
  AppendLine(Result, '    if (item.summary) {');
  AppendLine(Result, '      var summary = document.createElement("small");');
  AppendLine(Result, '      summary.textContent = item.summary;');
  AppendLine(Result, '      link.appendChild(summary);');
  AppendLine(Result, '    }');
  AppendLine(Result, '    li.appendChild(link);');
  AppendLine(Result, '    list.appendChild(li);');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function closeSearch() {');
  AppendLine(Result, '    panel.hidden = true;');
  AppendLine(Result, '    input.setAttribute("aria-expanded", "false");');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function update() {');
  AppendLine(Result, '    var query = input.value.trim().toLowerCase();');
  AppendLine(Result, '    list.replaceChildren();');
  AppendLine(Result, '    if (!query) { closeSearch(); return; }');
  AppendLine(Result, '    var matches = entries.map(function (item) {');
  AppendLine(Result, '      return { item: item, score: score(item, query) };');
  AppendLine(Result, '    }).filter(function (match) { return match.score >= 0; });');
  AppendLine(Result, '    matches.sort(function (left, right) {');
  AppendLine(Result, '      return right.score - left.score || ' +
    'left.item.qualifiedName.localeCompare(right.item.qualifiedName);');
  AppendLine(Result, '    });');
  AppendLine(Result, '    matches.slice(0, 24).forEach(function (match) { addResult(match.item); });');
  AppendLine(Result, '    status.textContent = matches.length ? ' +
    'matches.length + (matches.length === 1 ? " result" : " results") : "No results";');
  AppendLine(Result, '    panel.hidden = false;');
  AppendLine(Result, '    input.setAttribute("aria-expanded", "true");');
  AppendLine(Result, '  }');
  AppendLine(Result, '  input.addEventListener("input", update);');
  AppendLine(Result, '  input.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    if (event.key === "Escape") { closeSearch(); input.blur(); }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  document.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    var tag = document.activeElement && document.activeElement.tagName;');
  AppendLine(Result, '    if (event.key === "/" && tag !== "INPUT" && tag !== "TEXTAREA") {');
  AppendLine(Result, '      event.preventDefault(); input.focus();');
  AppendLine(Result, '    }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  document.addEventListener("click", function (event) {');
  AppendLine(Result, '    if (!event.target.closest("[data-search-container]")) closeSearch();');
  AppendLine(Result, '  });');
  AppendLine(Result, '}());');
end;

function HTMLMathScript: UTF8String;
begin
  Result := '';
  AppendLine(Result, '(function () {');
  AppendLine(Result, '  "use strict";');
  AppendLine(Result, '  function sourceText(element, displayMode) {');
  AppendLine(Result, '    var source = element.textContent.trim();');
  AppendLine(Result, '    var delimiter = displayMode ? "$$" : "$";');
  AppendLine(Result, '    if (source.indexOf(delimiter) === 0 && ' +
    'source.slice(-delimiter.length) === delimiter) {');
  AppendLine(Result, '      source = source.slice(delimiter.length, ' +
    '-delimiter.length);');
  AppendLine(Result, '    }');
  AppendLine(Result, '    return source.trim();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function renderElement(element) {');
  AppendLine(Result, '    var displayMode = element.hasAttribute("data-math-display");');
  AppendLine(Result, '    var original = element.textContent;');
  AppendLine(Result, '    var source = sourceText(element, displayMode);');
  AppendLine(Result, '    try {');
  AppendLine(Result, '      window.katex.render(source, element, {');
  AppendLine(Result, '        displayMode: displayMode,');
  AppendLine(Result, '        throwOnError: true,');
  AppendLine(Result, '        strict: "warn",');
  AppendLine(Result, '        trust: false');
  AppendLine(Result, '      });');
  AppendLine(Result, '      element.setAttribute("data-math-rendered", "true");');
  AppendLine(Result, '    } catch (error) {');
  AppendLine(Result, '      var message = error && error.message ? error.message : ' +
    '"unknown KaTeX error";');
  AppendLine(Result, '      element.textContent = original;');
  AppendLine(Result, '      element.classList.add("math-error");');
  AppendLine(Result, '      element.setAttribute("data-math-error", "true");');
  AppendLine(Result, '      element.setAttribute("title", "KaTeX: " + message);');
  AppendLine(Result, '      console.warn("PasWeave could not render mathematics:", ' +
    'source, error);');
  AppendLine(Result, '    }');
  AppendLine(Result, '  }');
  AppendLine(Result, '  if (!window.katex || typeof window.katex.render !== "function") {');
  AppendLine(Result, '    document.documentElement.classList.add("math-unavailable");');
  AppendLine(Result, '    console.warn("PasWeave could not load the local KaTeX runtime.");');
  AppendLine(Result, '    return;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  document.querySelectorAll(' +
    '"[data-math-inline], [data-math-display]").forEach(renderElement);');
  AppendLine(Result, '}());');
end;

function HasAllKaTeXFontAssets(const ADirectory: string): Boolean;
var
  CSS: TStringList;
  CSSContent: string;
  CloseAt: Integer;
  FontCount: Integer;
  FontFilename: string;
  OpenAt: Integer;
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(ADirectory);
  CSS := TStringList.Create;
  try
    CSS.LoadFromFile(Root + 'katex.min.css');
    CSSContent := CSS.Text;
  finally
    CSS.Free;
  end;

  FontCount := 0;
  OpenAt := PosEx('url(fonts/', CSSContent, 1);
  while OpenAt > 0 do
  begin
    Inc(OpenAt, Length('url(fonts/'));
    CloseAt := PosEx(')', CSSContent, OpenAt);
    if CloseAt = 0 then
      Exit(False);
    FontFilename := Copy(CSSContent, OpenAt, CloseAt - OpenAt);
    if (FontFilename = '') or not FileExists(Root + 'fonts' + PathDelim +
      FontFilename) then
      Exit(False);
    Inc(FontCount);
    OpenAt := PosEx('url(fonts/', CSSContent, CloseAt + 1);
  end;
  Result := FontCount > 0;
end;

function IsKaTeXAssetsDirectory(const ADirectory: string): Boolean;
var
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(ADirectory);
  Result := FileExists(Root + 'katex.min.js') and
    FileExists(Root + 'katex.min.css') and FileExists(Root + 'LICENSE');
  if Result then
    Result := HasAllKaTeXFontAssets(ADirectory);
end;

function FindKaTeXAssetsDirectory: string;
var
  Candidates: TStringList;
  ExecutableDirectory: string;
  EnvironmentDirectory: string;
  I: Integer;
begin
  Result := '';
  Candidates := TStringList.Create;
  try
    EnvironmentDirectory := GetEnvironmentVariable('PASWEAVE_KATEX_ASSETS');
    if EnvironmentDirectory <> '' then
      Candidates.Add(ExpandFileName(EnvironmentDirectory));

    ExecutableDirectory := ExtractFileDir(ExpandFileName(ParamStr(0)));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim +
      'assets' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'assets' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'share' + PathDelim + 'pasweave' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + '..' + PathDelim + 'assets' + PathDelim + 'katex'));
    Candidates.Add(ExpandFileName(GetCurrentDir + PathDelim + 'assets' +
      PathDelim + 'katex'));

    for I := 0 to Candidates.Count - 1 do
      if IsKaTeXAssetsDirectory(Candidates[I]) then
        Exit(Candidates[I]);
  finally
    Candidates.Free;
  end;
  raise Exception.Create('cannot locate KaTeX ' + KaTeXVersion +
    ' assets; set PASWEAVE_KATEX_ASSETS or install assets/katex beside PasWeave');
end;

procedure CopyFileBytes(const ASourceFilename, ADestinationFilename: string);
var
  SourceStream: TFileStream;
  DestinationStream: TFileStream;
begin
  SourceStream := TFileStream.Create(ASourceFilename,
    fmOpenRead or fmShareDenyWrite);
  try
    DestinationStream := TFileStream.Create(ADestinationFilename, fmCreate);
    try
      DestinationStream.CopyFrom(SourceStream, 0);
    finally
      DestinationStream.Free;
    end;
  finally
    SourceStream.Free;
  end;
end;

procedure CopyFontFiles(const ASourceDirectory, ADestinationDirectory: string);
var
  Search: TSearchRec;
  Filenames: TStringList;
  I: Integer;
begin
  if not ForceDirectories(ADestinationDirectory) then
    raise EFCreateError.CreateFmt('cannot create KaTeX font directory: %s',
      [ADestinationDirectory]);
  Filenames := TStringList.Create;
  try
    Filenames.Sorted := True;
    if FindFirst(IncludeTrailingPathDelimiter(ASourceDirectory) + '*',
      faAnyFile, Search) = 0 then
    try
      repeat
        if (Search.Attr and faDirectory) = 0 then
          Filenames.Add(Search.Name);
      until FindNext(Search) <> 0;
    finally
      FindClose(Search);
    end;
    for I := 0 to Filenames.Count - 1 do
      CopyFileBytes(IncludeTrailingPathDelimiter(ASourceDirectory) +
        Filenames[I], IncludeTrailingPathDelimiter(ADestinationDirectory) +
        Filenames[I]);
  finally
    Filenames.Free;
  end;
end;

procedure WriteKaTeXAssets(const AAssetsDirectory: string);
var
  SourceDirectory: string;
  DestinationDirectory: string;
begin
  SourceDirectory := FindKaTeXAssetsDirectory;
  DestinationDirectory := IncludeTrailingPathDelimiter(AAssetsDirectory) +
    'katex';
  if not ForceDirectories(DestinationDirectory) then
    raise EFCreateError.CreateFmt('cannot create KaTeX asset directory: %s',
      [DestinationDirectory]);
  CopyFileBytes(IncludeTrailingPathDelimiter(SourceDirectory) + 'katex.min.js',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'katex.min.js');
  CopyFileBytes(IncludeTrailingPathDelimiter(SourceDirectory) + 'katex.min.css',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'katex.min.css');
  CopyFileBytes(IncludeTrailingPathDelimiter(SourceDirectory) + 'LICENSE',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'LICENSE');
  CopyFontFiles(IncludeTrailingPathDelimiter(SourceDirectory) + 'fonts',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'fonts');
end;

end.
