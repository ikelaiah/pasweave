unit PasWeave.Render.HTML.CSS;

{$mode objfpc}{$H+}{$J+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

function HTMLStylesheet(AProject: TDocProject): UTF8String;

implementation

uses
  Classes, SysUtils, PasWeave.Render.Support;

function HTMLStylesheet(AProject: TDocProject): UTF8String;
var
  Accent: string;
  AccentAlt: string;
  FontFamily: string;
  AccentDark: string;
  AccentAltDark: string;
begin
  Result := '';
  { The CLI validates these tokens, but the model is public API: fall back to
    the documented defaults so a programmatic caller cannot inject CSS. }
  if IsValidThemeColor(AProject.ThemeAccent) then
    Accent := AProject.ThemeAccent
  else
    Accent := DefaultThemeAccent;
  if IsValidThemeColor(AProject.ThemeAccentAlt) then
    AccentAlt := AProject.ThemeAccentAlt
  else
    AccentAlt := DefaultThemeAccentAlt;
  if IsValidThemeFont(AProject.ThemeFont) then
    FontFamily := AProject.ThemeFont
  else
    FontFamily := DefaultThemeFont;
  if Accent = DefaultThemeAccent then
    AccentDark := '#a99eff'
  else
    AccentDark := LightenThemeColor(Accent, 40);
  if AccentAlt = DefaultThemeAccentAlt then
    AccentAltDark := '#63d7ca'
  else
    AccentAltDark := LightenThemeColor(AccentAlt, 40);
  AppendLine(Result, ':root, :root[data-theme="system"] {');
  AppendLine(Result, '  color-scheme: light;');
  AppendLine(Result, '  --scheme: light;');
  AppendLine(Result, '  --bg: #f7f8fc; --surface: #ffffff; --surface-2: #eef1f8;');
  AppendLine(Result, '  --text: #172033; --muted: #667085; --line: #dbe1ec;');
  AppendLine(Result, '  --accent: ' + Accent + '; --accent-2: ' +
    AccentAlt + '; --code: #182034;');
  AppendLine(Result, '  --font-family: "' + FontFamily + '";');
  AppendLine(Result, '  --warning-bg: #fff8e6; --warning-line: #e5a923; ' +
    '--warning-text: #5e460e;');
  AppendLine(Result, '  --danger-bg: #fff0f3; --danger-line: #d13f61; ' +
    '--danger-text: #751b31;');
  AppendLine(Result, '  --error-text: #b42318;');
  AppendLine(Result, '  --shadow: 0 18px 48px rgba(31, 42, 68, .09);');
  AppendLine(Result, '}');
  AppendLine(Result, ':root[data-theme="dark"] {');
  AppendLine(Result, '  color-scheme: dark;');
  AppendLine(Result, '  --scheme: dark;');
  AppendLine(Result, '  --bg: #10131c; --surface: #171c28; --surface-2: #202637;');
  AppendLine(Result, '  --text: #e8ebf4; --muted: #9ba5ba; --line: #30384c;');
  AppendLine(Result, '  --accent: ' + AccentDark + '; --accent-2: ' +
    AccentAltDark + '; --code: #0b0e15;');
  AppendLine(Result, '  --warning-bg: #332a13; --warning-line: #e5b94f; ' +
    '--warning-text: #ffe5a6;');
  AppendLine(Result, '  --danger-bg: #361922; --danger-line: #d13f61; ' +
    '--danger-text: #ffb7c6;');
  AppendLine(Result, '  --error-text: #fda29b;');
  AppendLine(Result, '  --shadow: 0 18px 48px rgba(0,0,0,.28);');
  AppendLine(Result, '}');
  AppendLine(Result, '@media (prefers-color-scheme: dark) {');
  AppendLine(Result, '  :root:not([data-theme="light"]) {');
  AppendLine(Result, '    color-scheme: dark;');
  AppendLine(Result, '    --scheme: dark;');
  AppendLine(Result, '    --bg: #10131c; --surface: #171c28; ' +
    '--surface-2: #202637;');
  AppendLine(Result, '    --text: #e8ebf4; --muted: #9ba5ba; ' +
    '--line: #30384c;');
  AppendLine(Result, '    --accent: ' + AccentDark + '; --accent-2: ' +
    AccentAltDark + '; --code: #0b0e15;');
  AppendLine(Result, '    --warning-bg: #332a13; --warning-line: #e5b94f; ' +
    '--warning-text: #ffe5a6;');
  AppendLine(Result, '    --danger-bg: #361922; --danger-line: #d13f61; ' +
    '--danger-text: #ffb7c6;');
  AppendLine(Result, '    --error-text: #fda29b;');
  AppendLine(Result, '    --shadow: 0 18px 48px rgba(0,0,0,.28);');
  AppendLine(Result, '  }');
  AppendLine(Result, '}');
  AppendLine(Result, '* { box-sizing: border-box; }');
  AppendLine(Result, 'html { scroll-behavior: smooth; }');
  AppendLine(Result, 'body { margin: 0; background: var(--bg); color: var(--text); ' +
    'font: 16px/1.65 var(--font-family, "Inter"), ui-sans-serif, system-ui, ' +
    '-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }');
  AppendLine(Result, 'a { color: var(--accent); text-decoration-thickness: .08em; ' +
    'text-underline-offset: .18em; }');
  AppendLine(Result, 'a:hover { color: var(--accent-2); }');
  AppendLine(Result, ':where(a, button, input, select, summary):focus-visible { ' +
    'outline: 3px solid color-mix(in srgb, var(--accent) 45%, transparent); ' +
    'outline-offset: 2px; }');
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
  AppendLine(Result, '.search-filters { display: grid; grid-template-columns: ' +
    'repeat(2, minmax(0, 1fr)); gap: 10px; margin: 0 0 10px; padding: 4px 8px 12px; ' +
    'min-width: 0; border: 0; border-bottom: 1px solid var(--line); }');
  AppendLine(Result, '.search-filters label { display: grid; gap: 4px; color: ' +
    'var(--muted); font-size: .72rem; font-weight: 750; letter-spacing: .04em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, '.search-filters select { min-width: 0; height: 34px; padding: ' +
    '0 8px; border: 1px solid var(--line); border-radius: 8px; background: ' +
    'var(--surface); color: var(--text); font: inherit; font-weight: 500; ' +
    'letter-spacing: normal; text-transform: none; }');
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
  AppendLine(Result, '.unit-navigation { position: relative; display: grid; ' +
    'grid-template-columns: minmax(240px, 360px) minmax(0, 1fr); ' +
    'align-items: start; gap: 18px; margin: 24px 0 0; }');
  AppendLine(Result, '.unit-switcher { position: relative; min-width: 0; }');
  AppendLine(Result, '.unit-switcher summary { display: flex; align-items: center; ' +
    'justify-content: flex-start; gap: 9px; padding: 10px 13px; ' +
    'border: 1px solid var(--line); border-radius: 11px; background: ' +
    'var(--surface); color: var(--muted); font-size: .84rem; font-weight: 700; ' +
    'cursor: pointer; }');
  AppendLine(Result, '.unit-switcher summary::before { content: "\25B8"; ' +
    'flex: 0 0 auto; color: var(--accent); }');
  AppendLine(Result, '.unit-switcher[open] summary::before { ' +
    'transform: rotate(90deg); }');
  AppendLine(Result, '.unit-switcher-current { min-width: 0; color: var(--text); ' +
    'margin-left: auto; font-weight: 600; overflow-wrap: anywhere; ' +
    'text-align: right; }');
  AppendLine(Result, '.unit-switcher-panel { position: absolute; z-index: 10; ' +
    'top: calc(100% + 8px); left: 0; width: 100%; min-width: min(320px, 90vw); ' +
    'padding: 13px; border: 1px solid var(--line); border-radius: 13px; ' +
    'background: var(--surface); box-shadow: var(--shadow); }');
  AppendLine(Result, '.unit-switcher-panel label { display: block; margin-bottom: ' +
    '5px; color: var(--muted); font-size: .72rem; font-weight: 750; ' +
    'letter-spacing: .04em; text-transform: uppercase; }');
  AppendLine(Result, '.unit-switcher-panel input { width: 100%; height: 38px; ' +
    'padding: 0 10px; border: 1px solid var(--line); border-radius: 9px; ' +
    'background: var(--surface-2); color: var(--text); font: inherit; }');
  AppendLine(Result, '.unit-switcher-status { margin: 8px 2px; color: ' +
    'var(--muted); font-size: .78rem; }');
  AppendLine(Result, '.unit-switcher-list { max-height: min(44vh, 340px); ' +
    'overflow-y: auto; overscroll-behavior: contain; list-style: none; ' +
    'margin: 0; padding: 0; }');
  AppendLine(Result, '.unit-switcher-list li[hidden] { display: none; }');
  AppendLine(Result, '.unit-switcher-list a { display: block; padding: 8px 9px; ' +
    'border-radius: 8px; color: var(--text); text-decoration: none; ' +
    'overflow-wrap: anywhere; }');
  AppendLine(Result, '.unit-switcher-list a:hover { background: var(--surface-2); }');
  AppendLine(Result, '.unit-switcher-list a[aria-current="page"] { background: ' +
    'color-mix(in srgb, var(--accent) 12%, transparent); color: var(--accent); ' +
    'font-weight: 750; }');
  AppendLine(Result, '.page-navigator { display: flex; align-items: baseline; ' +
    'gap: 12px; min-width: 0; padding: 8px 0; }');
  AppendLine(Result, '.page-navigator > span { flex: 0 0 auto; color: var(--muted); ' +
    'font-size: .76rem; font-weight: 800; letter-spacing: .05em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, '.page-navigator ul { display: flex; flex-wrap: wrap; gap: ' +
    '6px 14px; list-style: none; margin: 0; padding: 0; }');
  AppendLine(Result, '.page-navigator a { font-size: .86rem; font-weight: 700; }');
  AppendLine(Result, '.unit-heading { margin: 34px 0 28px; }');
  AppendLine(Result, '.unit-heading h1 { margin: 0; font-size: clamp(2rem, 6vw, 4rem); ' +
    'overflow-wrap: anywhere; }');
  AppendLine(Result, '.unit-heading > p:last-child { color: var(--muted); }');
  AppendLine(Result, '.dependency-section, .symbol-group { margin-top: 46px; }');
  AppendLine(Result, '.symbol-group { scroll-margin-top: 94px; }');
  AppendLine(Result, '.dependency-list { display: flex; flex-wrap: wrap; gap: 9px; ' +
    'list-style: none; margin: 0; padding: 0; }');
  AppendLine(Result, '.dependency-list li { padding: 7px 11px; border: 1px solid ' +
    'var(--line); border-radius: 999px; background: var(--surface); }');
  AppendLine(Result, '.diagram-overview { position: relative; }');
  AppendLine(Result, '.diagram-toolbar { display: flex; flex-wrap: wrap; ' +
    'align-items: center; gap: 8px 12px; margin: 0 0 12px; }');
  AppendLine(Result, '.diagram-toolbar[hidden], .diagram-help[hidden] { ' +
    'display: none; }');
  AppendLine(Result, '.diagram-control-group { display: inline-flex; ' +
    'align-items: center; gap: 6px; }');
  AppendLine(Result, '.diagram-tool-label { color: var(--muted); ' +
    'font-size: .78rem; font-weight: 750; letter-spacing: .04em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, '.diagram-toolbar button { min-height: 36px; padding: ' +
    '6px 10px; border: 1px solid var(--line); border-radius: 9px; ' +
    'background: var(--surface); color: var(--text); font: inherit; ' +
    'font-size: .82rem; font-weight: 700; cursor: pointer; }');
  AppendLine(Result, '.diagram-toolbar button:hover:not(:disabled) { ' +
    'border-color: var(--accent); color: var(--accent); }');
  AppendLine(Result, '.diagram-toolbar button:focus-visible, ' +
    '.architecture-diagram:focus-visible { outline: 3px solid ' +
    'color-mix(in srgb, var(--accent) 45%, transparent); ' +
    'outline-offset: 2px; }');
  AppendLine(Result, '.diagram-toolbar button:disabled { opacity: .42; ' +
    'cursor: not-allowed; }');
  AppendLine(Result, '.diagram-icon-button { width: 36px; padding-inline: ' +
    '0 !important; }');
  AppendLine(Result, '.diagram-zoom-status { min-width: 4.25rem; color: ' +
    'var(--muted); font-size: .82rem; font-variant-numeric: tabular-nums; ' +
    'text-align: center; }');
  AppendLine(Result, '.diagram-help { margin: 0 0 12px; color: ' +
    'var(--muted); font-size: .82rem; }');
  AppendLine(Result, '.architecture-diagram { overflow: auto; max-height: ' +
    'min(72vh, 720px); padding: 20px; border: 1px solid var(--line); ' +
    'border-radius: 16px; background: var(--surface); ' +
    'overscroll-behavior: contain; }');
  AppendLine(Result, '.architecture-diagram[data-diagram-interactive] { ' +
    'cursor: grab; }');
  AppendLine(Result, '.architecture-diagram[data-diagram-dragging] { ' +
    'cursor: grabbing; user-select: none; }');
  AppendLine(Result, '.architecture-diagram[data-diagram-rendering] { position: ' +
    'absolute; width: 100%; visibility: hidden; pointer-events: none; }');
  AppendLine(Result, '.architecture-diagram pre.mermaid { overflow: visible; ' +
    'margin: 0; padding: 0; background: transparent; color: inherit; ' +
    'white-space: pre-wrap; }');
  AppendLine(Result, '.architecture-diagram svg { display: block; max-width: 100%; ' +
    'height: auto; margin: 0 auto; transform-origin: top left; }');
  AppendLine(Result, '.diagram-fallback { margin-top: 14px; padding: 0 16px; ' +
    'border: 1px solid var(--line); border-radius: 12px; background: ' +
    'var(--surface); }');
  AppendLine(Result, '.diagram-fallback summary { padding: 12px 0; ' +
    'font-weight: 700; cursor: pointer; }');
  AppendLine(Result, '.diagram-fallback ul { margin: 0 0 16px; }');
  AppendLine(Result, '.diagram-fallback p { margin: 0 0 16px; color: ' +
    'var(--muted); }');
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
  AppendLine(Result, '.type-relationships { margin: 12px 0; font-size: .9rem; }');
  AppendLine(Result, '.type-relationships ul { margin: 6px 0 0; }');
  AppendLine(Result, 'pre { overflow: auto; margin: 18px 0; padding: 18px; ' +
    'border-radius: 13px; background: var(--code); color: #eef2ff; line-height: 1.55; }');
  AppendLine(Result, 'pre code { font-size: .84rem; }');
  AppendLine(Result, '.notice { margin: 18px 0; padding: 12px 15px; ' +
    'border-left: 4px solid var(--warning-line); border-radius: 8px; ' +
    'background: var(--warning-bg); color: var(--warning-text); }');
  AppendLine(Result, '.deprecated { border-left-color: var(--danger-line); ' +
    'background: var(--danger-bg); color: var(--danger-text); }');
  AppendLine(Result, '.prose { max-width: 78ch; }');
  AppendLine(Result, '.prose blockquote { margin-left: 0; padding-left: 18px; ' +
    'border-left: 3px solid var(--line); color: var(--muted); }');
  AppendLine(Result, '.math-display { overflow-x: auto; margin: 20px 0; padding: 18px; ' +
    'border: 1px solid var(--line); border-radius: 12px; background: var(--surface-2); ' +
    'font-family: "Cambria Math", serif; white-space: pre-wrap; text-align: center; }');
  AppendLine(Result, '.math-inline { font-family: "Cambria Math", serif; }');
  AppendLine(Result, '.math-display[data-math-rendered="true"] { white-space: normal; }');
  AppendLine(Result, '.math-inline[data-math-rendered="true"] { font-family: inherit; }');
  AppendLine(Result, '.math-error { color: var(--error-text); ' +
    'text-decoration: underline dotted; text-underline-offset: .18em; }');
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
  AppendLine(Result, '  .header-tools { gap: 12px; }');
  AppendLine(Result, '  .brand small { display: none; }');
  AppendLine(Result, '  .site-search { width: 52vw; }');
  AppendLine(Result, '  .search-panel { right: -4px; width: min(94vw, 620px); }');
  AppendLine(Result, '  .search-filters { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .main-content { padding-top: 28px; }');
  AppendLine(Result, '  .unit-navigation { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .hero { padding: 32px 24px; border-radius: 20px; }');
  AppendLine(Result, '  .stats { grid-template-columns: repeat(2, 1fr); }');
  AppendLine(Result, '  .browse-section { grid-template-columns: ' +
    'repeat(2, minmax(0, 1fr)); }');
  AppendLine(Result, '  .section-heading { align-items: start; flex-direction: column; }');
  AppendLine(Result, '  .symbol { padding: 20px; }');
  AppendLine(Result, '  .symbol-meta { display: grid; }');
  AppendLine(Result, '  .diagram-toolbar { align-items: flex-start; }');
  AppendLine(Result, '  .diagram-control-group { flex-wrap: wrap; }');
  AppendLine(Result, '  .architecture-diagram { max-height: 65vh; padding: 12px; }');
  AppendLine(Result, '}');
  AppendLine(Result, '@media (max-width: 480px) {');
  AppendLine(Result, '  .header-inner { flex-wrap: wrap; padding: 10px 0; }');
  AppendLine(Result, '  .header-tools { flex-wrap: wrap; width: 100%; ' +
    'gap: 10px 14px; }');
  AppendLine(Result, '  .site-search { width: 100%; }');
  AppendLine(Result, '  .search-panel { right: 0; width: 100%; }');
  AppendLine(Result, '  .unit-switcher-panel { position: static; width: 100%; ' +
    'min-width: 0; margin-top: 8px; box-shadow: none; }');
  AppendLine(Result, '  .page-navigator { align-items: flex-start; ' +
    'flex-direction: column; }');
  AppendLine(Result, '  .browse-section { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .symbol-index-list { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .symbol-index-entry { grid-template-columns: ' +
    'auto minmax(0, 1fr) auto; }');
  AppendLine(Result, '  .stats { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .hero { padding: 28px 24px; }');
  AppendLine(Result, '}');
  AppendLine(Result, '.header-tools { display: flex; align-items: center; ' +
    'justify-content: flex-end; gap: 18px; min-width: 0; }');
  AppendLine(Result, '.site-nav { display: flex; align-items: center; ' +
    'gap: 2px; }');
  AppendLine(Result, '.site-nav a { padding: 7px 10px; border-radius: 9px; ' +
    'color: var(--muted); font-size: .86rem; font-weight: 700; ' +
    'text-decoration: none; white-space: nowrap; }');
  AppendLine(Result, '.site-nav a:hover { color: var(--text); ' +
    'background: var(--surface-2); }');
  AppendLine(Result, '.site-nav a[aria-current="page"] { color: var(--accent); }');
  AppendLine(Result, '.theme-control { display: flex; align-items: center; ' +
    'gap: 8px; color: var(--muted); font-size: .72rem; font-weight: 750; ' +
    'letter-spacing: .05em; text-transform: uppercase; white-space: nowrap; }');
  AppendLine(Result, '.theme-control[hidden] { display: none; }');
  AppendLine(Result, '.theme-control select { height: 34px; padding: 0 8px; ' +
    'border: 1px solid var(--line); border-radius: 8px; background: ' +
    'var(--surface); color: var(--text); font: inherit; font-size: .84rem; ' +
    'font-weight: 600; letter-spacing: normal; text-transform: none; }');
  AppendLine(Result, '.browse-section { display: grid; grid-template-columns: ' +
    'repeat(3, minmax(0, 1fr)); gap: 12px; }');
  AppendLine(Result, '.browse-section .section-heading { grid-column: 1 / -1; ' +
    'margin-bottom: 2px; }');
  AppendLine(Result, '.browse-card { display: block; padding: 22px; border: ' +
    '1px solid var(--line); border-radius: 16px; background: var(--surface); ' +
    'color: var(--text); text-decoration: none; box-shadow: 0 6px 18px ' +
    'rgba(31,42,68,.035); }');
  AppendLine(Result, '.browse-card:hover { border-color: var(--accent); }');
  AppendLine(Result, '.browse-card strong { display: block; font-size: 1.15rem; }');
  AppendLine(Result, '.browse-card span { display: block; margin-top: 6px; ' +
    'color: var(--muted); font-size: .86rem; }');
  AppendLine(Result, '.browse-card .browse-count { font-size: 1.6rem; ' +
    'line-height: 1; color: var(--accent); }');
  AppendLine(Result, '.symbol-index { margin-top: 8px; }');
  AppendLine(Result, '.symbol-index-heading { margin: 34px 0 24px; }');
  AppendLine(Result, '.symbol-index-heading h1 { margin: 0; ' +
    'font-size: clamp(2rem, 6vw, 4rem); }');
  AppendLine(Result, '.symbol-index-heading > p { color: var(--muted); }');
  AppendLine(Result, '.letter-bar { display: flex; flex-wrap: wrap; gap: 4px; ' +
    'margin: 18px 0 20px; }');
  AppendLine(Result, '.letter-bar a { display: inline-grid; place-items: ' +
    'center; min-width: 30px; height: 30px; padding: 0 6px; border: 1px solid ' +
    'var(--line); border-radius: 8px; color: var(--muted); font-size: .8rem; ' +
    'font-weight: 700; text-decoration: none; }');
  AppendLine(Result, '.letter-bar a:hover { color: var(--accent); ' +
    'border-color: var(--accent); }');
  AppendLine(Result, '.symbol-filters { display: flex; flex-wrap: wrap; gap: ' +
    '8px 18px; margin: 0 0 18px; padding: 0; border: 0; }');
  AppendLine(Result, '.symbol-filters legend { color: var(--muted); ' +
    'font-size: .76rem; font-weight: 800; letter-spacing: .05em; ' +
    'text-transform: uppercase; }');
  AppendLine(Result, '.symbol-filters label { display: inline-flex; ' +
    'align-items: center; gap: 7px; padding: 7px 11px; border: 1px solid ' +
    'var(--line); border-radius: 999px; background: var(--surface); ' +
    'color: var(--text); font-size: .84rem; font-weight: 650; cursor: pointer; }');
  AppendLine(Result, '.symbol-filters label:has(input:checked) { ' +
    'border-color: var(--accent); background: color-mix(in srgb, ' +
    'var(--accent) 10%, var(--surface)); }');
  AppendLine(Result, '.symbol-filters input { accent-color: var(--accent); }');
  AppendLine(Result, '.symbol-status { margin: 0 0 20px; color: var(--muted); ' +
    'font-size: .86rem; }');
  AppendLine(Result, '.symbol-letter { margin: 0 0 34px; scroll-margin-top: 94px; }');
  AppendLine(Result, '.symbol-letter h2 { display: flex; align-items: center; ' +
    'gap: 14px; margin: 0 0 14px; font-size: 1.5rem; }');
  AppendLine(Result, '.symbol-letter h2::after { content: ""; flex: 1; ' +
    'height: 1px; background: var(--line); }');
  AppendLine(Result, '.symbol-index-list { display: grid; grid-template-columns: ' +
    'repeat(2, minmax(0, 1fr)); gap: 8px 22px; list-style: none; margin: 0; ' +
    'padding: 0; }');
  AppendLine(Result, '.symbol-index-entry { display: grid; grid-template-columns: ' +
    'auto minmax(0, 1fr) auto; align-items: center; gap: 10px; padding: 8px 10px; ' +
    'border-radius: 9px; }');
  AppendLine(Result, '.symbol-index-entry:hover { background: var(--surface-2); }');
  AppendLine(Result, '.symbol-index-entry[hidden] { display: none; }');
  AppendLine(Result, '.symbol-index-entry code { overflow-wrap: anywhere; ' +
    'font-weight: 700; }');
  AppendLine(Result, '.symbol-index-unit { min-width: 0; color: var(--muted); ' +
    'font-size: .78rem; overflow-wrap: anywhere; text-align: right; }');
  AppendLine(Result, '.symbol-index-entry .kind-badge { font-size: .64rem; }');
end;

end.
