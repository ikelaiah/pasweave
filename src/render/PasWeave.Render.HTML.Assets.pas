unit PasWeave.Render.HTML.Assets;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

const
  KaTeXVersion = '0.18.1';
  MermaidVersion = '11.16.0';

function HTMLStylesheet: UTF8String;
function HTMLApplicationScript: UTF8String;
function HTMLMathScript: UTF8String;
function HTMLDiagramScript: UTF8String;
procedure WriteThirdPartyAssets(const AAssetsDirectory: string);
procedure WriteKaTeXAssets(const AAssetsDirectory: string);
procedure WriteMermaidAssets(const AAssetsDirectory: string);

implementation

uses
  Classes, SysUtils, StrUtils
  {$IFDEF PASWEAVE_PORTABLE_ASSETS}
  {$IFDEF MSWINDOWS}
  , Zipper
  {$ELSE}
  {$ERROR Portable asset embedding currently requires Windows}
  {$ENDIF}
  {$ENDIF};

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
    'justify-content: space-between; gap: 12px; padding: 10px 13px; ' +
    'border: 1px solid var(--line); border-radius: 11px; background: ' +
    'var(--surface); color: var(--muted); font-size: .84rem; font-weight: 700; ' +
    'cursor: pointer; }');
  AppendLine(Result, '.unit-switcher summary::marker { color: var(--accent); }');
  AppendLine(Result, '.unit-switcher-current { min-width: 0; color: var(--text); ' +
    'font-weight: 600; overflow-wrap: anywhere; text-align: right; }');
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
  AppendLine(Result, '  .search-panel { right: -4px; width: min(94vw, 620px); }');
  AppendLine(Result, '  .search-filters { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .main-content { padding-top: 28px; }');
  AppendLine(Result, '  .unit-navigation { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .hero { padding: 32px 24px; border-radius: 20px; }');
  AppendLine(Result, '  .stats { grid-template-columns: repeat(2, 1fr); }');
  AppendLine(Result, '  .section-heading { align-items: start; flex-direction: column; }');
  AppendLine(Result, '  .symbol { padding: 20px; }');
  AppendLine(Result, '  .symbol-meta { display: grid; }');
  AppendLine(Result, '  .diagram-toolbar { align-items: flex-start; }');
  AppendLine(Result, '  .diagram-control-group { flex-wrap: wrap; }');
  AppendLine(Result, '  .architecture-diagram { max-height: 65vh; padding: 12px; }');
  AppendLine(Result, '}');
  AppendLine(Result, '@media (max-width: 480px) {');
  AppendLine(Result, '  .header-inner { flex-wrap: wrap; padding: 10px 0; }');
  AppendLine(Result, '  .site-search { width: 100%; }');
  AppendLine(Result, '  .search-panel { right: 0; width: 100%; }');
  AppendLine(Result, '  .unit-switcher-panel { position: static; width: 100%; ' +
    'min-width: 0; margin-top: 8px; box-shadow: none; }');
  AppendLine(Result, '  .page-navigator { align-items: flex-start; ' +
    'flex-direction: column; }');
  AppendLine(Result, '  .stats { grid-template-columns: 1fr; }');
  AppendLine(Result, '  .hero { padding: 28px 24px; }');
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
  AppendLine(Result, '  var unitFilter = document.querySelector("[data-search-unit]");');
  AppendLine(Result, '  var kindFilter = document.querySelector("[data-search-kind]");');
  AppendLine(Result, '  var visibilityFilter = document.querySelector("[data-search-visibility]");');
  AppendLine(Result, '  var documentationFilter = document.querySelector("[data-search-documentation]");');
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
  AppendLine(Result, '  function matchesFilters(item) {');
  AppendLine(Result, '    if (unitFilter.value && item.unit !== unitFilter.value) return false;');
  AppendLine(Result, '    if (kindFilter.value && item.kind !== kindFilter.value) return false;');
  AppendLine(Result, '    if (visibilityFilter.value && item.visibility !== visibilityFilter.value) return false;');
  AppendLine(Result, '    if (documentationFilter.value === "documented" && !item.documented) return false;');
  AppendLine(Result, '    if (documentationFilter.value === "undocumented" && item.documented) return false;');
  AppendLine(Result, '    return true;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function hasActiveFilter() {');
  AppendLine(Result, '    return unitFilter.value || kindFilter.value || visibilityFilter.value || documentationFilter.value;');
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
  AppendLine(Result, '  function openSearch() {');
  AppendLine(Result, '    panel.hidden = false;');
  AppendLine(Result, '    input.setAttribute("aria-expanded", "true");');
  AppendLine(Result, '    if (!input.value.trim() && !hasActiveFilter()) status.textContent = "Type to search or choose filters.";');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function resultLinks() {');
  AppendLine(Result, '    return Array.prototype.slice.call(list.querySelectorAll("a.search-result"));');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function moveResultFocus(current, offset) {');
  AppendLine(Result, '    var links = resultLinks();');
  AppendLine(Result, '    if (!links.length) return;');
  AppendLine(Result, '    var index = links.indexOf(current);');
  AppendLine(Result, '    links[(index + offset + links.length) % links.length].focus();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function update() {');
  AppendLine(Result, '    var query = input.value.trim().toLowerCase();');
  AppendLine(Result, '    list.replaceChildren();');
  AppendLine(Result, '    if (!query && !hasActiveFilter()) { closeSearch(); return; }');
  AppendLine(Result, '    var matches = entries.map(function (item) {');
  AppendLine(Result, '      return { item: item, score: score(item, query) };');
  AppendLine(Result, '    }).filter(function (match) { return match.score >= 0 && matchesFilters(match.item); });');
  AppendLine(Result, '    matches.sort(function (left, right) {');
  AppendLine(Result, '      return right.score - left.score || ' +
    'left.item.qualifiedName.localeCompare(right.item.qualifiedName);');
  AppendLine(Result, '    });');
  AppendLine(Result, '    matches.slice(0, 24).forEach(function (match) { addResult(match.item); });');
  AppendLine(Result, '    status.textContent = matches.length ? ' +
    'matches.length + (matches.length === 1 ? " result" : " results") + ' +
    '(matches.length > 24 ? "; first 24 shown" : "") : ' +
    '"No symbols match the current search and filters.";');
  AppendLine(Result, '    panel.hidden = false;');
  AppendLine(Result, '    input.setAttribute("aria-expanded", "true");');
  AppendLine(Result, '  }');
  AppendLine(Result, '  input.addEventListener("input", update);');
  AppendLine(Result, '  input.addEventListener("focus", openSearch);');
  AppendLine(Result, '  input.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    if (event.key === "Escape") { closeSearch(); input.blur(); }');
  AppendLine(Result, '    else if (event.key === "ArrowDown") {');
  AppendLine(Result, '      var links = resultLinks();');
  AppendLine(Result, '      if (links.length) { event.preventDefault(); links[0].focus(); }');
  AppendLine(Result, '    }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  list.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    var link = event.target.closest("a.search-result");');
  AppendLine(Result, '    if (!link) return;');
  AppendLine(Result, '    if (event.key === "ArrowDown") { event.preventDefault(); moveResultFocus(link, 1); }');
  AppendLine(Result, '    else if (event.key === "ArrowUp") { event.preventDefault(); moveResultFocus(link, -1); }');
  AppendLine(Result, '    else if (event.key === "Escape") { event.preventDefault(); input.focus(); closeSearch(); }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  panel.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    if (event.key === "Escape" && !event.target.closest("[data-search-results]")) {');
  AppendLine(Result, '      event.preventDefault(); input.focus(); closeSearch();');
  AppendLine(Result, '    }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  [unitFilter, kindFilter, visibilityFilter, documentationFilter].forEach(function (filter) {');
  AppendLine(Result, '    filter.addEventListener("change", update);');
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
  AppendLine(Result, '  var unitSwitcher = document.querySelector("[data-unit-switcher]");');
  AppendLine(Result, '  if (!unitSwitcher) return;');
  AppendLine(Result, '  var unitInput = unitSwitcher.querySelector("[data-unit-switcher-filter]");');
  AppendLine(Result, '  var unitList = unitSwitcher.querySelector("[data-unit-switcher-list]");');
  AppendLine(Result, '  var unitStatus = unitSwitcher.querySelector("[data-unit-switcher-status]");');
  AppendLine(Result, '  var unitSummary = unitSwitcher.querySelector("summary");');
  AppendLine(Result, '  var unitItems = Array.prototype.slice.call(unitList.querySelectorAll("li"));');
  AppendLine(Result, '  function visibleUnitLinks() {');
  AppendLine(Result, '    return unitItems.filter(function (item) { return !item.hidden; })');
  AppendLine(Result, '      .map(function (item) { return item.querySelector("a"); });');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function updateUnitSwitcher() {');
  AppendLine(Result, '    var query = unitInput.value.trim().toLowerCase();');
  AppendLine(Result, '    unitItems.forEach(function (item) {');
  AppendLine(Result, '      var link = item.querySelector("a");');
  AppendLine(Result, '      item.hidden = link.textContent.toLowerCase().indexOf(query) < 0;');
  AppendLine(Result, '    });');
  AppendLine(Result, '    var count = visibleUnitLinks().length;');
  AppendLine(Result, '    unitStatus.textContent = count ? count + (count === 1 ? " unit" : " units") : ' +
    '"No units match “" + unitInput.value.trim() + "”.";');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function moveUnitFocus(current, offset) {');
  AppendLine(Result, '    var links = visibleUnitLinks();');
  AppendLine(Result, '    if (!links.length) return;');
  AppendLine(Result, '    var index = links.indexOf(current);');
  AppendLine(Result, '    links[(index + offset + links.length) % links.length].focus();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function closeUnitSwitcher() {');
  AppendLine(Result, '    unitSwitcher.open = false;');
  AppendLine(Result, '    unitSummary.focus();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  unitInput.addEventListener("input", updateUnitSwitcher);');
  AppendLine(Result, '  unitInput.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    if (event.key === "ArrowDown") {');
  AppendLine(Result, '      var links = visibleUnitLinks();');
  AppendLine(Result, '      if (links.length) { event.preventDefault(); links[0].focus(); }');
  AppendLine(Result, '    } else if (event.key === "Escape") {');
  AppendLine(Result, '      event.preventDefault(); unitInput.value = ""; updateUnitSwitcher(); closeUnitSwitcher();');
  AppendLine(Result, '    }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  unitList.addEventListener("keydown", function (event) {');
  AppendLine(Result, '    var link = event.target.closest("a");');
  AppendLine(Result, '    if (!link) return;');
  AppendLine(Result, '    if (event.key === "ArrowDown") { event.preventDefault(); moveUnitFocus(link, 1); }');
  AppendLine(Result, '    else if (event.key === "ArrowUp") { event.preventDefault(); moveUnitFocus(link, -1); }');
  AppendLine(Result, '    else if (event.key === "Escape") { event.preventDefault(); closeUnitSwitcher(); }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  unitSwitcher.addEventListener("toggle", function () {');
  AppendLine(Result, '    if (unitSwitcher.open) unitInput.focus();');
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

function HTMLDiagramScript: UTF8String;
begin
  Result := '';
  AppendLine(Result, '(function () {');
  AppendLine(Result, '  "use strict";');
  AppendLine(Result, '  var MIN_SCALE = 0.5;');
  AppendLine(Result, '  var MAX_SCALE = 3;');
  AppendLine(Result, '  var SCALE_STEP = 0.25;');
  AppendLine(Result, '  var PAN_STEP = 96;');
  AppendLine(Result, '  var diagrams = Array.prototype.slice.call(' +
    'document.querySelectorAll("[data-mermaid]"));');
  AppendLine(Result, '  if (!diagrams.length) return;');
  AppendLine(Result, '  var reducedMotion = window.matchMedia && ' +
    'window.matchMedia("(prefers-reduced-motion: reduce)").matches;');
  AppendLine(Result, '  function interactionElements(diagram) {');
  AppendLine(Result, '    var section = diagram.closest(' +
    '"[data-diagram-section]");');
  AppendLine(Result, '    return {');
  AppendLine(Result, '      section: section,');
  AppendLine(Result, '      toolbar: section && section.querySelector(' +
    '"[data-diagram-toolbar]"),');
  AppendLine(Result, '      help: section && section.querySelector(' +
    '"[data-diagram-help]")');
  AppendLine(Result, '    };');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function hideDiagram(diagram) {');
  AppendLine(Result, '    var container = diagram.closest(' +
    '"[data-diagram-container]");');
  AppendLine(Result, '    var elements = interactionElements(diagram);');
  AppendLine(Result, '    if (container) {');
  AppendLine(Result, '      container.hidden = true;');
  AppendLine(Result, '      container.removeAttribute("data-diagram-rendering");');
  AppendLine(Result, '      container.setAttribute("aria-hidden", "true");');
  AppendLine(Result, '    }');
  AppendLine(Result, '    if (elements.toolbar) elements.toolbar.hidden = true;');
  AppendLine(Result, '    if (elements.help) elements.help.hidden = true;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function setDisabled(control, disabled) {');
  AppendLine(Result, '    if (control) control.disabled = disabled;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function setupInteraction(diagram, container, section) {');
  AppendLine(Result, '    var svg = diagram.querySelector("svg");');
  AppendLine(Result, '    var toolbar = section && section.querySelector(' +
    '"[data-diagram-toolbar]");');
  AppendLine(Result, '    var help = section && section.querySelector(' +
    '"[data-diagram-help]");');
  AppendLine(Result, '    if (!svg || !container || !toolbar) return;');
  AppendLine(Result, '    var zoomOut = toolbar.querySelector(' +
    '"[data-diagram-zoom-out]");');
  AppendLine(Result, '    var zoomIn = toolbar.querySelector(' +
    '"[data-diagram-zoom-in]");');
  AppendLine(Result, '    var scaleOutput = toolbar.querySelector(' +
    '"[data-diagram-scale]");');
  AppendLine(Result, '    var panLeft = toolbar.querySelector(' +
    '"[data-diagram-pan-left]");');
  AppendLine(Result, '    var panUp = toolbar.querySelector(' +
    '"[data-diagram-pan-up]");');
  AppendLine(Result, '    var panDown = toolbar.querySelector(' +
    '"[data-diagram-pan-down]");');
  AppendLine(Result, '    var panRight = toolbar.querySelector(' +
    '"[data-diagram-pan-right]");');
  AppendLine(Result, '    var reset = toolbar.querySelector(' +
    '"[data-diagram-reset]");');
  AppendLine(Result, '    var panControls = [panLeft, panUp, panDown, panRight];');
  AppendLine(Result, '    var scale = 1;');
  AppendLine(Result, '    var drag = null;');
  AppendLine(Result, '    var suppressClick = false;');
  AppendLine(Result, '    function updateControls() {');
  AppendLine(Result, '      var maxLeft = Math.max(0, container.scrollWidth - ' +
    'container.clientWidth);');
  AppendLine(Result, '      var maxTop = Math.max(0, container.scrollHeight - ' +
    'container.clientHeight);');
  AppendLine(Result, '      var left = Math.max(0, Math.min(maxLeft, ' +
    'container.scrollLeft));');
  AppendLine(Result, '      var top = Math.max(0, Math.min(maxTop, ' +
    'container.scrollTop));');
  AppendLine(Result, '      if (scaleOutput) scaleOutput.textContent = ' +
    'Math.round(scale * 100) + "%";');
  AppendLine(Result, '      container.setAttribute("data-diagram-scale", ' +
    'String(Math.round(scale * 100)));');
  AppendLine(Result, '      container.setAttribute("data-diagram-pan-x", ' +
    'String(Math.round(left)));');
  AppendLine(Result, '      container.setAttribute("data-diagram-pan-y", ' +
    'String(Math.round(top)));');
  AppendLine(Result, '      setDisabled(zoomOut, scale <= MIN_SCALE);');
  AppendLine(Result, '      setDisabled(zoomIn, scale >= MAX_SCALE);');
  AppendLine(Result, '      setDisabled(panLeft, left <= 1);');
  AppendLine(Result, '      setDisabled(panUp, top <= 1);');
  AppendLine(Result, '      setDisabled(panRight, left >= maxLeft - 1);');
  AppendLine(Result, '      setDisabled(panDown, top >= maxTop - 1);');
  AppendLine(Result, '      setDisabled(reset, scale === 1 && left <= 1 && top <= 1);');
  AppendLine(Result, '    }');
  AppendLine(Result, '    function applyScale(nextScale) {');
  AppendLine(Result, '      nextScale = Math.max(MIN_SCALE, Math.min(MAX_SCALE, ' +
    'Math.round(nextScale * 100) / 100));');
  AppendLine(Result, '      if (nextScale === scale) return;');
  AppendLine(Result, '      var oldWidth = Math.max(1, container.scrollWidth);');
  AppendLine(Result, '      var oldHeight = Math.max(1, container.scrollHeight);');
  AppendLine(Result, '      var centerX = (container.scrollLeft + ' +
    'container.clientWidth / 2) / oldWidth;');
  AppendLine(Result, '      var centerY = (container.scrollTop + ' +
    'container.clientHeight / 2) / oldHeight;');
  AppendLine(Result, '      scale = nextScale;');
  AppendLine(Result, '      svg.style.maxWidth = "none";');
  AppendLine(Result, '      svg.style.width = Math.round(scale * 100) + "%";');
  AppendLine(Result, '      container.scrollLeft = Math.max(0, centerX * ' +
    'container.scrollWidth - container.clientWidth / 2);');
  AppendLine(Result, '      container.scrollTop = Math.max(0, centerY * ' +
    'container.scrollHeight - container.clientHeight / 2);');
  AppendLine(Result, '      updateControls();');
  AppendLine(Result, '    }');
  AppendLine(Result, '    function pan(left, top) {');
  AppendLine(Result, '      container.scrollBy({');
  AppendLine(Result, '        left: left, top: top,');
  AppendLine(Result, '        behavior: reducedMotion ? "auto" : "smooth"');
  AppendLine(Result, '      });');
  AppendLine(Result, '    }');
  AppendLine(Result, '    function resetView() {');
  AppendLine(Result, '      scale = 1;');
  AppendLine(Result, '      svg.style.maxWidth = "none";');
  AppendLine(Result, '      svg.style.width = "100%";');
  AppendLine(Result, '      container.scrollLeft = 0;');
  AppendLine(Result, '      container.scrollTop = 0;');
  AppendLine(Result, '      updateControls();');
  AppendLine(Result, '    }');
  AppendLine(Result, '    if (zoomOut) zoomOut.addEventListener("click", ' +
    'function () { applyScale(scale - SCALE_STEP); });');
  AppendLine(Result, '    if (zoomIn) zoomIn.addEventListener("click", ' +
    'function () { applyScale(scale + SCALE_STEP); });');
  AppendLine(Result, '    if (panLeft) panLeft.addEventListener("click", ' +
    'function () { pan(-PAN_STEP, 0); });');
  AppendLine(Result, '    if (panUp) panUp.addEventListener("click", ' +
    'function () { pan(0, -PAN_STEP); });');
  AppendLine(Result, '    if (panDown) panDown.addEventListener("click", ' +
    'function () { pan(0, PAN_STEP); });');
  AppendLine(Result, '    if (panRight) panRight.addEventListener("click", ' +
    'function () { pan(PAN_STEP, 0); });');
  AppendLine(Result, '    if (reset) reset.addEventListener("click", resetView);');
  AppendLine(Result, '    container.addEventListener("keydown", function (event) {');
  AppendLine(Result, '      if (event.target !== container) return;');
  AppendLine(Result, '      if (event.altKey || event.ctrlKey || event.metaKey) return;');
  AppendLine(Result, '      var handled = true;');
  AppendLine(Result, '      if (event.key === "ArrowLeft") pan(-PAN_STEP, 0);');
  AppendLine(Result, '      else if (event.key === "ArrowRight") pan(PAN_STEP, 0);');
  AppendLine(Result, '      else if (event.key === "ArrowUp") pan(0, -PAN_STEP);');
  AppendLine(Result, '      else if (event.key === "ArrowDown") pan(0, PAN_STEP);');
  AppendLine(Result, '      else if (event.key === "+" || event.key === "=") ' +
    'applyScale(scale + SCALE_STEP);');
  AppendLine(Result, '      else if (event.key === "-" || event.key === "_") ' +
    'applyScale(scale - SCALE_STEP);');
  AppendLine(Result, '      else if (event.key === "0") resetView();');
  AppendLine(Result, '      else handled = false;');
  AppendLine(Result, '      if (handled) event.preventDefault();');
  AppendLine(Result, '    });');
  AppendLine(Result, '    container.addEventListener("scroll", updateControls, ' +
    '{ passive: true });');
  AppendLine(Result, '    container.addEventListener("pointerdown", function (event) {');
  AppendLine(Result, '      if (event.button !== 0 || event.pointerType === "touch" || ' +
    'event.target.closest("a, button")) return;');
  AppendLine(Result, '      drag = { id: event.pointerId, x: event.clientX, ' +
    'y: event.clientY, left: container.scrollLeft, ' +
    'top: container.scrollTop };');
  AppendLine(Result, '      suppressClick = false;');
  AppendLine(Result, '      container.setPointerCapture(event.pointerId);');
  AppendLine(Result, '      container.setAttribute("data-diagram-dragging", "");');
  AppendLine(Result, '      event.preventDefault();');
  AppendLine(Result, '    });');
  AppendLine(Result, '    container.addEventListener("pointermove", function (event) {');
  AppendLine(Result, '      if (!drag || drag.id !== event.pointerId) return;');
  AppendLine(Result, '      var deltaX = event.clientX - drag.x;');
  AppendLine(Result, '      var deltaY = event.clientY - drag.y;');
  AppendLine(Result, '      if (Math.abs(deltaX) > 3 || Math.abs(deltaY) > 3) ' +
    'suppressClick = true;');
  AppendLine(Result, '      container.scrollLeft = drag.left - deltaX;');
  AppendLine(Result, '      container.scrollTop = drag.top - deltaY;');
  AppendLine(Result, '      event.preventDefault();');
  AppendLine(Result, '    });');
  AppendLine(Result, '    function endDrag(event) {');
  AppendLine(Result, '      if (!drag || drag.id !== event.pointerId) return;');
  AppendLine(Result, '      drag = null;');
  AppendLine(Result, '      container.removeAttribute("data-diagram-dragging");');
  AppendLine(Result, '      if (container.hasPointerCapture(event.pointerId)) ' +
    'container.releasePointerCapture(event.pointerId);');
  AppendLine(Result, '      window.setTimeout(function () { suppressClick = false; }, 0);');
  AppendLine(Result, '    }');
  AppendLine(Result, '    container.addEventListener("pointerup", endDrag);');
  AppendLine(Result, '    container.addEventListener("pointercancel", endDrag);');
  AppendLine(Result, '    container.addEventListener("click", function (event) {');
  AppendLine(Result, '      if (!suppressClick) return;');
  AppendLine(Result, '      event.preventDefault();');
  AppendLine(Result, '      event.stopPropagation();');
  AppendLine(Result, '    }, true);');
  AppendLine(Result, '    svg.style.maxWidth = "none";');
  AppendLine(Result, '    svg.style.width = "100%";');
  AppendLine(Result, '    container.setAttribute("data-diagram-interactive", "");');
  AppendLine(Result, '    container.setAttribute("aria-keyshortcuts", ' +
    '"ArrowLeft ArrowRight ArrowUp ArrowDown + - 0");');
  AppendLine(Result, '    panControls.forEach(function (control) {');
  AppendLine(Result, '      if (control) control.removeAttribute("aria-hidden");');
  AppendLine(Result, '    });');
  AppendLine(Result, '    toolbar.hidden = false;');
  AppendLine(Result, '    if (help) help.hidden = false;');
  AppendLine(Result, '    if (window.ResizeObserver) ' +
    'new window.ResizeObserver(updateControls).observe(container);');
  AppendLine(Result, '    updateControls();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function unavailable(error) {');
  AppendLine(Result, '    document.documentElement.classList.add(' +
    '"diagram-unavailable");');
  AppendLine(Result, '    diagrams.forEach(hideDiagram);');
  AppendLine(Result, '    console.warn("PasWeave could not render the architecture ' +
    'diagrams.", error || "local Mermaid runtime unavailable");');
  AppendLine(Result, '  }');
  AppendLine(Result, '  if (!window.mermaid || typeof window.mermaid.run !== "function") {');
  AppendLine(Result, '    unavailable();');
  AppendLine(Result, '    return;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  var dark = window.matchMedia && ' +
    'window.matchMedia("(prefers-color-scheme: dark)").matches;');
  AppendLine(Result, '  try {');
  AppendLine(Result, '    window.mermaid.initialize({');
  AppendLine(Result, '      startOnLoad: false,');
  AppendLine(Result, '      securityLevel: "loose",');
  AppendLine(Result, '      deterministicIds: true,');
  AppendLine(Result, '      deterministicIDSeed: "pasweave-architecture-diagrams",');
  AppendLine(Result, '      theme: dark ? "dark" : "neutral",');
  AppendLine(Result, '      flowchart: { htmlLabels: false, useMaxWidth: true }');
  AppendLine(Result, '    });');
  AppendLine(Result, '    diagrams.forEach(function (diagram) {');
  AppendLine(Result, '      var container = diagram.closest(' +
    '"[data-diagram-container]");');
  AppendLine(Result, '      if (container) {');
  AppendLine(Result, '        container.hidden = false;');
  AppendLine(Result, '        container.setAttribute("data-diagram-rendering", "");');
  AppendLine(Result, '      }');
  AppendLine(Result, '    });');
  AppendLine(Result, '    Promise.resolve(window.mermaid.run({');
  AppendLine(Result, '      nodes: diagrams, suppressErrors: true');
  AppendLine(Result, '    })).then(function () {');
  AppendLine(Result, '      diagrams.forEach(function (diagram) {');
  AppendLine(Result, '        var section = diagram.closest(' +
    '"[data-diagram-section]");');
  AppendLine(Result, '        var container = diagram.closest(' +
    '"[data-diagram-container]");');
  AppendLine(Result, '        var fallback = section && section.querySelector(' +
    '"[data-diagram-fallback]");');
  AppendLine(Result, '        if (!diagram.querySelector("svg")) {');
  AppendLine(Result, '          hideDiagram(diagram);');
  AppendLine(Result, '          return;');
  AppendLine(Result, '        }');
  AppendLine(Result, '        diagram.setAttribute("data-diagram-rendered", "true");');
  AppendLine(Result, '        if (container) {');
  AppendLine(Result, '          container.removeAttribute("data-diagram-rendering");');
  AppendLine(Result, '          container.removeAttribute("aria-hidden");');
  AppendLine(Result, '        }');
  AppendLine(Result, '        setupInteraction(diagram, container, section);');
  AppendLine(Result, '        if (fallback) fallback.removeAttribute("open");');
  AppendLine(Result, '      });');
  AppendLine(Result, '    }).catch(unavailable);');
  AppendLine(Result, '  } catch (error) {');
  AppendLine(Result, '    unavailable(error);');
  AppendLine(Result, '  }');
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

function IsMermaidAssetsDirectory(const ADirectory: string): Boolean;
var
  Root: string;
begin
  Root := IncludeTrailingPathDelimiter(ADirectory);
  Result := FileExists(Root + 'mermaid.tiny.js') and
    FileExists(Root + 'LICENSE');
end;

function FindMermaidAssetsDirectory: string;
var
  Candidates: TStringList;
  ExecutableDirectory: string;
  EnvironmentDirectory: string;
  I: Integer;
begin
  Result := '';
  Candidates := TStringList.Create;
  try
    EnvironmentDirectory := GetEnvironmentVariable(
      'PASWEAVE_MERMAID_ASSETS');
    if EnvironmentDirectory <> '' then
      Candidates.Add(ExpandFileName(EnvironmentDirectory));

    ExecutableDirectory := ExtractFileDir(ExpandFileName(ParamStr(0)));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim +
      'assets' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'assets' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + 'share' + PathDelim + 'pasweave' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(ExecutableDirectory + PathDelim + '..' +
      PathDelim + '..' + PathDelim + 'assets' + PathDelim + 'mermaid'));
    Candidates.Add(ExpandFileName(GetCurrentDir + PathDelim + 'assets' +
      PathDelim + 'mermaid'));

    for I := 0 to Candidates.Count - 1 do
      if IsMermaidAssetsDirectory(Candidates[I]) then
        Exit(Candidates[I]);
  finally
    Candidates.Free;
  end;
  raise Exception.Create('cannot locate Mermaid ' + MermaidVersion +
    ' assets; set PASWEAVE_MERMAID_ASSETS or install assets/mermaid beside ' +
    'PasWeave');
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

procedure WriteMermaidAssets(const AAssetsDirectory: string);
var
  SourceDirectory: string;
  DestinationDirectory: string;
begin
  SourceDirectory := FindMermaidAssetsDirectory;
  DestinationDirectory := IncludeTrailingPathDelimiter(AAssetsDirectory) +
    'mermaid';
  if not ForceDirectories(DestinationDirectory) then
    raise EFCreateError.CreateFmt('cannot create Mermaid asset directory: %s',
      [DestinationDirectory]);
  CopyFileBytes(IncludeTrailingPathDelimiter(SourceDirectory) +
    'mermaid.tiny.js', IncludeTrailingPathDelimiter(DestinationDirectory) +
    'mermaid.tiny.js');
  CopyFileBytes(IncludeTrailingPathDelimiter(SourceDirectory) + 'LICENSE',
    IncludeTrailingPathDelimiter(DestinationDirectory) + 'LICENSE');
end;

{$IFDEF PASWEAVE_PORTABLE_ASSETS}
type
  TEmbeddedAssetExtractor = class
  private
    procedure CloseInputStream(Sender: TObject; var AStream: TStream);
    procedure OpenInputStream(Sender: TObject; var AStream: TStream);
  public
    procedure ExtractTo(const AAssetsDirectory: string);
  end;

const
  WindowsRCDATAResourceType = 10;

procedure TEmbeddedAssetExtractor.OpenInputStream(Sender: TObject;
  var AStream: TStream);
begin
  AStream := TResourceStream.Create(HInstance, 'PASWEAVE_ASSETS',
    PChar(PtrUInt(WindowsRCDATAResourceType)));
end;

procedure TEmbeddedAssetExtractor.CloseInputStream(Sender: TObject;
  var AStream: TStream);
begin
  FreeAndNil(AStream);
end;

procedure TEmbeddedAssetExtractor.ExtractTo(const AAssetsDirectory: string);
var
  UnZipper: TUnZipper;
begin
  if not ForceDirectories(AAssetsDirectory) then
    raise EFCreateError.CreateFmt('cannot create HTML asset directory: %s',
      [AAssetsDirectory]);
  UnZipper := TUnZipper.Create;
  try
    UnZipper.OutputPath := AAssetsDirectory;
    UnZipper.UseUTF8 := True;
    UnZipper.OnOpenInputStream := @OpenInputStream;
    UnZipper.OnCloseInputStream := @CloseInputStream;
    UnZipper.UnZipAllFiles;
  finally
    UnZipper.Free;
  end;

  if not IsKaTeXAssetsDirectory(IncludeTrailingPathDelimiter(
    AAssetsDirectory) + 'katex') then
    raise Exception.Create('embedded KaTeX assets are incomplete');
  if not IsMermaidAssetsDirectory(IncludeTrailingPathDelimiter(
    AAssetsDirectory) + 'mermaid') then
    raise Exception.Create('embedded Mermaid assets are incomplete');
end;
{$ENDIF}

procedure WriteThirdPartyAssets(const AAssetsDirectory: string);
{$IFDEF PASWEAVE_PORTABLE_ASSETS}
var
  Extractor: TEmbeddedAssetExtractor;
{$ENDIF}
begin
  {$IFDEF PASWEAVE_PORTABLE_ASSETS}
  Extractor := TEmbeddedAssetExtractor.Create;
  try
    Extractor.ExtractTo(AAssetsDirectory);
  finally
    Extractor.Free;
  end;
  {$ELSE}
  WriteKaTeXAssets(AAssetsDirectory);
  WriteMermaidAssets(AAssetsDirectory);
  {$ENDIF}
end;

end.
