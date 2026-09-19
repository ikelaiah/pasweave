unit PasWeave.Render.HTML.Scripts;

{$mode objfpc}{$H+}{$J+}
{$codepage utf8}

interface

function HTMLThemeBootstrap: UTF8String;
function HTMLApplicationScript: UTF8String;
function HTMLMathScript: UTF8String;
function HTMLDiagramScript: UTF8String;

implementation

uses
  Classes, SysUtils, PasWeave.Render.Support;

function HTMLThemeBootstrap: UTF8String;
begin
  Result := '';
  AppendLine(Result, '(function () {');
  AppendLine(Result, '  "use strict";');
  AppendLine(Result, '  var stored = null;');
  AppendLine(Result, '  try {');
  AppendLine(Result, '    stored = window.localStorage.getItem("pasweave-theme");');
  AppendLine(Result, '  } catch (error) {');
  AppendLine(Result, '    stored = null;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  var theme = "system";');
  AppendLine(Result, '  if (stored === "system" || stored === "light" || ' +
    'stored === "dark") {');
  AppendLine(Result, '    theme = stored;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  document.documentElement.setAttribute("data-theme", theme);');
  AppendLine(Result, '}());');
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
  AppendLine(Result, '  var themeControl = document.querySelector(' +
    '"[data-theme-control]");');
  AppendLine(Result, '  if (themeControl) {');
  AppendLine(Result, '    var themeSelect = themeControl.querySelector(' +
    '"[data-theme-select]");');
  AppendLine(Result, '    var currentTheme = ' +
    'document.documentElement.getAttribute("data-theme") || "system";');
  AppendLine(Result, '    if (["system", "light", "dark"].indexOf(' +
    'currentTheme) < 0) currentTheme = "system";');
  AppendLine(Result, '    if (themeSelect) {');
  AppendLine(Result, '      themeSelect.value = currentTheme;');
  AppendLine(Result, '      themeSelect.addEventListener("change", function () {');
  AppendLine(Result, '        var next = themeSelect.value;');
  AppendLine(Result, '        document.documentElement.setAttribute(' +
    '"data-theme", next);');
  AppendLine(Result, '        try {');
  AppendLine(Result, '          window.localStorage.setItem(' +
    '"pasweave-theme", next);');
  AppendLine(Result, '        } catch (error) {');
  AppendLine(Result, '          /* storage unavailable; keep the choice for ' +
    'this page */');
  AppendLine(Result, '        }');
  AppendLine(Result, '        document.dispatchEvent(new window.CustomEvent(' +
    '"pasweave:themechange", { detail: { theme: next } }));');
  AppendLine(Result, '      });');
  AppendLine(Result, '    }');
  AppendLine(Result, '    themeControl.hidden = false;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  var symbolIndex = document.querySelector(' +
    '"[data-symbol-index]");');
  AppendLine(Result, '  if (symbolIndex) {');
  AppendLine(Result, '    var symbolFilters = Array.prototype.slice.call(' +
    'symbolIndex.querySelectorAll("[data-symbol-filter]"));');
  AppendLine(Result, '    var symbolEntries = Array.prototype.slice.call(' +
    'symbolIndex.querySelectorAll("[data-symbol-entry]"));');
  AppendLine(Result, '    var symbolSections = Array.prototype.slice.call(' +
    'symbolIndex.querySelectorAll("[data-symbol-letter]"));');
  AppendLine(Result, '    var symbolStatus = symbolIndex.querySelector(' +
    '"[data-symbol-status]");');
  AppendLine(Result, '    function symbolGroups() {');
  AppendLine(Result, '      return symbolFilters.filter(function (filter) ' +
    '{ return filter.checked; })');
  AppendLine(Result, '        .map(function (filter) { return filter.value; });');
  AppendLine(Result, '    }');
  AppendLine(Result, '    function updateSymbolIndex() {');
  AppendLine(Result, '      var groups = symbolGroups();');
  AppendLine(Result, '      var visible = 0;');
  AppendLine(Result, '      symbolEntries.forEach(function (entry) {');
  AppendLine(Result, '        var shown = groups.indexOf(entry.getAttribute(' +
    '"data-symbol-kind")) >= 0;');
  AppendLine(Result, '        entry.hidden = !shown;');
  AppendLine(Result, '        if (shown) visible += 1;');
  AppendLine(Result, '      });');
  AppendLine(Result, '      symbolSections.forEach(function (section) {');
  AppendLine(Result, '        var any = section.querySelector(' +
    '"[data-symbol-entry]:not([hidden])");');
  AppendLine(Result, '        section.hidden = !any;');
  AppendLine(Result, '      });');
  AppendLine(Result, '      if (symbolStatus) {');
  AppendLine(Result, '        symbolStatus.textContent = visible + ' +
    '(visible === 1 ? " symbol" : " symbols");');
  AppendLine(Result, '      }');
  AppendLine(Result, '    }');
  AppendLine(Result, '    symbolFilters.forEach(function (filter) {');
  AppendLine(Result, '      filter.addEventListener("change", updateSymbolIndex);');
  AppendLine(Result, '    });');
  AppendLine(Result, '    function applySymbolHash() {');
  AppendLine(Result, '      var hash = window.location.hash.replace(/^#/, "");');
  AppendLine(Result, '      var known = ["types", "routines", "members", ' +
    '"constants", "variables"];');
  AppendLine(Result, '      if (known.indexOf(hash) < 0) return;');
  AppendLine(Result, '      symbolFilters.forEach(function (filter) {');
  AppendLine(Result, '        filter.checked = filter.value === hash;');
  AppendLine(Result, '      });');
  AppendLine(Result, '      updateSymbolIndex();');
  AppendLine(Result, '    }');
  AppendLine(Result, '    applySymbolHash();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  var unitSwitcher = document.querySelector(' +
    '"[data-unit-switcher]");');
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
  AppendLine(Result, '  diagrams.forEach(function (diagram) {');
  AppendLine(Result, '    if (diagram.getAttribute("data-mermaid-source") == null) {');
  AppendLine(Result, '      diagram.setAttribute("data-mermaid-source", ' +
    'diagram.textContent);');
  AppendLine(Result, '    }');
  AppendLine(Result, '  });');
  AppendLine(Result, '  function activeScheme() {');
  AppendLine(Result, '    var attr = document.documentElement.getAttribute(' +
    '"data-theme");');
  AppendLine(Result, '    if (attr === "dark") return "dark";');
  AppendLine(Result, '    if (attr === "light") return "light";');
  AppendLine(Result, '    return window.matchMedia && window.matchMedia(' +
    '"(prefers-color-scheme: dark)").matches ? "dark" : "light";');
  AppendLine(Result, '  }');
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
  AppendLine(Result, '    var toolbar = section && section.querySelector(' +
    '"[data-diagram-toolbar]");');
  AppendLine(Result, '    var help = section && section.querySelector(' +
    '"[data-diagram-help]");');
  AppendLine(Result, '    if (!container || !toolbar) return;');
  AppendLine(Result, '    var state = container._pasweaveDiagramState;');
  AppendLine(Result, '    if (!state) {');
  AppendLine(Result, '      state = container._pasweaveDiagramState = {');
  AppendLine(Result, '        scale: 1, drag: null, suppressClick: false');
  AppendLine(Result, '      };');
  AppendLine(Result, '      var zoomOut = toolbar.querySelector(' +
    '"[data-diagram-zoom-out]");');
  AppendLine(Result, '      var zoomIn = toolbar.querySelector(' +
    '"[data-diagram-zoom-in]");');
  AppendLine(Result, '      var scaleOutput = toolbar.querySelector(' +
    '"[data-diagram-scale]");');
  AppendLine(Result, '      var panLeft = toolbar.querySelector(' +
    '"[data-diagram-pan-left]");');
  AppendLine(Result, '      var panUp = toolbar.querySelector(' +
    '"[data-diagram-pan-up]");');
  AppendLine(Result, '      var panDown = toolbar.querySelector(' +
    '"[data-diagram-pan-down]");');
  AppendLine(Result, '      var panRight = toolbar.querySelector(' +
    '"[data-diagram-pan-right]");');
  AppendLine(Result, '      var reset = toolbar.querySelector(' +
    '"[data-diagram-reset]");');
  AppendLine(Result, '      var panControls = [panLeft, panUp, panDown, panRight];');
  AppendLine(Result, '      function currentSvg() {');
  AppendLine(Result, '        return diagram.querySelector("svg");');
  AppendLine(Result, '      }');
  AppendLine(Result, '      function updateControls() {');
  AppendLine(Result, '        var maxLeft = Math.max(0, container.scrollWidth - ' +
    'container.clientWidth);');
  AppendLine(Result, '        var maxTop = Math.max(0, container.scrollHeight - ' +
    'container.clientHeight);');
  AppendLine(Result, '        var left = Math.max(0, Math.min(maxLeft, ' +
    'container.scrollLeft));');
  AppendLine(Result, '        var top = Math.max(0, Math.min(maxTop, ' +
    'container.scrollTop));');
  AppendLine(Result, '        if (scaleOutput) scaleOutput.textContent = ' +
    'Math.round(state.scale * 100) + "%";');
  AppendLine(Result, '        container.setAttribute("data-diagram-scale", ' +
    'String(Math.round(state.scale * 100)));');
  AppendLine(Result, '        container.setAttribute("data-diagram-pan-x", ' +
    'String(Math.round(left)));');
  AppendLine(Result, '        container.setAttribute("data-diagram-pan-y", ' +
    'String(Math.round(top)));');
  AppendLine(Result, '        setDisabled(zoomOut, state.scale <= MIN_SCALE);');
  AppendLine(Result, '        setDisabled(zoomIn, state.scale >= MAX_SCALE);');
  AppendLine(Result, '        setDisabled(panLeft, left <= 1);');
  AppendLine(Result, '        setDisabled(panUp, top <= 1);');
  AppendLine(Result, '        setDisabled(panRight, left >= maxLeft - 1);');
  AppendLine(Result, '        setDisabled(panDown, top >= maxTop - 1);');
  AppendLine(Result, '        setDisabled(reset, state.scale === 1 && ' +
    'left <= 1 && top <= 1);');
  AppendLine(Result, '      }');
  AppendLine(Result, '      function applyScale(nextScale) {');
  AppendLine(Result, '        var svg = currentSvg();');
  AppendLine(Result, '        if (!svg) return;');
  AppendLine(Result, '        nextScale = Math.max(MIN_SCALE, ' +
    'Math.min(MAX_SCALE, Math.round(nextScale * 100) / 100));');
  AppendLine(Result, '        if (nextScale === state.scale) return;');
  AppendLine(Result, '        var oldWidth = Math.max(1, ' +
    'container.scrollWidth);');
  AppendLine(Result, '        var oldHeight = Math.max(1, ' +
    'container.scrollHeight);');
  AppendLine(Result, '        var centerX = (container.scrollLeft + ' +
    'container.clientWidth / 2) / oldWidth;');
  AppendLine(Result, '        var centerY = (container.scrollTop + ' +
    'container.clientHeight / 2) / oldHeight;');
  AppendLine(Result, '        state.scale = nextScale;');
  AppendLine(Result, '        svg.style.maxWidth = "none";');
  AppendLine(Result, '        svg.style.width = Math.round(state.scale * 100) + ' +
    '"%";');
  AppendLine(Result, '        container.scrollLeft = Math.max(0, centerX * ' +
    'container.scrollWidth - container.clientWidth / 2);');
  AppendLine(Result, '        container.scrollTop = Math.max(0, centerY * ' +
    'container.scrollHeight - container.clientHeight / 2);');
  AppendLine(Result, '        updateControls();');
  AppendLine(Result, '      }');
  AppendLine(Result, '      function pan(left, top) {');
  AppendLine(Result, '        container.scrollBy({');
  AppendLine(Result, '          left: left, top: top,');
  AppendLine(Result, '          behavior: reducedMotion ? "auto" : "smooth"');
  AppendLine(Result, '        });');
  AppendLine(Result, '      }');
  AppendLine(Result, '      function resetView() {');
  AppendLine(Result, '        var svg = currentSvg();');
  AppendLine(Result, '        state.scale = 1;');
  AppendLine(Result, '        if (svg) {');
  AppendLine(Result, '          svg.style.maxWidth = "none";');
  AppendLine(Result, '          svg.style.width = "100%";');
  AppendLine(Result, '        }');
  AppendLine(Result, '        container.scrollLeft = 0;');
  AppendLine(Result, '        container.scrollTop = 0;');
  AppendLine(Result, '        updateControls();');
  AppendLine(Result, '      }');
  AppendLine(Result, '      if (zoomOut) zoomOut.addEventListener("click", ' +
    'function () { applyScale(state.scale - SCALE_STEP); });');
  AppendLine(Result, '      if (zoomIn) zoomIn.addEventListener("click", ' +
    'function () { applyScale(state.scale + SCALE_STEP); });');
  AppendLine(Result, '      if (panLeft) panLeft.addEventListener("click", ' +
    'function () { pan(-PAN_STEP, 0); });');
  AppendLine(Result, '      if (panUp) panUp.addEventListener("click", ' +
    'function () { pan(0, -PAN_STEP); });');
  AppendLine(Result, '      if (panDown) panDown.addEventListener("click", ' +
    'function () { pan(0, PAN_STEP); });');
  AppendLine(Result, '      if (panRight) panRight.addEventListener("click", ' +
    'function () { pan(PAN_STEP, 0); });');
  AppendLine(Result, '      if (reset) reset.addEventListener("click", ' +
    'resetView);');
  AppendLine(Result, '      container.addEventListener("keydown", ' +
    'function (event) {');
  AppendLine(Result, '        if (event.target !== container) return;');
  AppendLine(Result, '        if (event.altKey || event.ctrlKey || ' +
    'event.metaKey) return;');
  AppendLine(Result, '        var handled = true;');
  AppendLine(Result, '        if (event.key === "ArrowLeft") pan(-PAN_STEP, 0);');
  AppendLine(Result, '        else if (event.key === "ArrowRight") ' +
    'pan(PAN_STEP, 0);');
  AppendLine(Result, '        else if (event.key === "ArrowUp") pan(0, -PAN_STEP);');
  AppendLine(Result, '        else if (event.key === "ArrowDown") pan(0, PAN_STEP);');
  AppendLine(Result, '        else if (event.key === "+" || event.key === "=") ' +
    'applyScale(state.scale + SCALE_STEP);');
  AppendLine(Result, '        else if (event.key === "-" || event.key === "_") ' +
    'applyScale(state.scale - SCALE_STEP);');
  AppendLine(Result, '        else if (event.key === "0") resetView();');
  AppendLine(Result, '        else handled = false;');
  AppendLine(Result, '        if (handled) event.preventDefault();');
  AppendLine(Result, '      });');
  AppendLine(Result, '      container.addEventListener("scroll", updateControls, ' +
    '{ passive: true });');
  AppendLine(Result, '      container.addEventListener("pointerdown", ' +
    'function (event) {');
  AppendLine(Result, '        if (event.button !== 0 || ' +
    'event.pointerType === "touch" || event.target.closest("a, button")) ' +
    'return;');
  AppendLine(Result, '        state.drag = { id: event.pointerId, ' +
    'x: event.clientX, y: event.clientY, left: container.scrollLeft, ' +
    'top: container.scrollTop };');
  AppendLine(Result, '        state.suppressClick = false;');
  AppendLine(Result, '        container.setPointerCapture(event.pointerId);');
  AppendLine(Result, '        container.setAttribute("data-diagram-dragging", "");');
  AppendLine(Result, '        event.preventDefault();');
  AppendLine(Result, '      });');
  AppendLine(Result, '      container.addEventListener("pointermove", ' +
    'function (event) {');
  AppendLine(Result, '        if (!state.drag || state.drag.id !== ' +
    'event.pointerId) return;');
  AppendLine(Result, '        var deltaX = event.clientX - state.drag.x;');
  AppendLine(Result, '        var deltaY = event.clientY - state.drag.y;');
  AppendLine(Result, '        if (Math.abs(deltaX) > 3 || Math.abs(deltaY) > 3) ' +
    'state.suppressClick = true;');
  AppendLine(Result, '        container.scrollLeft = state.drag.left - deltaX;');
  AppendLine(Result, '        container.scrollTop = state.drag.top - deltaY;');
  AppendLine(Result, '        event.preventDefault();');
  AppendLine(Result, '      });');
  AppendLine(Result, '      function endDrag(event) {');
  AppendLine(Result, '        if (!state.drag || state.drag.id !== ' +
    'event.pointerId) return;');
  AppendLine(Result, '        state.drag = null;');
  AppendLine(Result, '        container.removeAttribute("data-diagram-dragging");');
  AppendLine(Result, '        if (container.hasPointerCapture(event.pointerId)) ' +
    'container.releasePointerCapture(event.pointerId);');
  AppendLine(Result, '        window.setTimeout(function () { ' +
    'state.suppressClick = false; }, 0);');
  AppendLine(Result, '      }');
  AppendLine(Result, '      container.addEventListener("pointerup", endDrag);');
  AppendLine(Result, '      container.addEventListener("pointercancel", endDrag);');
  AppendLine(Result, '      container.addEventListener("click", ' +
    'function (event) {');
  AppendLine(Result, '        if (!state.suppressClick) return;');
  AppendLine(Result, '        event.preventDefault();');
  AppendLine(Result, '        event.stopPropagation();');
  AppendLine(Result, '      }, true);');
  AppendLine(Result, '      if (window.ResizeObserver) ' +
    'new window.ResizeObserver(updateControls).observe(container);');
  AppendLine(Result, '      state.updateControls = updateControls;');
  AppendLine(Result, '      state.panControls = panControls;');
  AppendLine(Result, '    }');
  AppendLine(Result, '    var svg = diagram.querySelector("svg");');
  AppendLine(Result, '    state.scale = 1;');
  AppendLine(Result, '    state.drag = null;');
  AppendLine(Result, '    state.suppressClick = false;');
  AppendLine(Result, '    if (svg) {');
  AppendLine(Result, '      svg.style.maxWidth = "none";');
  AppendLine(Result, '      svg.style.width = "100%";');
  AppendLine(Result, '    }');
  AppendLine(Result, '    container.scrollLeft = 0;');
  AppendLine(Result, '    container.scrollTop = 0;');
  AppendLine(Result, '    container.setAttribute("data-diagram-interactive", "");');
  AppendLine(Result, '    container.setAttribute("aria-keyshortcuts", ' +
    '"ArrowLeft ArrowRight ArrowUp ArrowDown + - 0");');
  AppendLine(Result, '    if (state.panControls) state.panControls.forEach(' +
    'function (control) {');
  AppendLine(Result, '      if (control) control.removeAttribute("aria-hidden");');
  AppendLine(Result, '    });');
  AppendLine(Result, '    toolbar.hidden = false;');
  AppendLine(Result, '    if (help) help.hidden = false;');
  AppendLine(Result, '    if (state.updateControls) state.updateControls();');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function unavailable(error) {');
  AppendLine(Result, '    document.documentElement.classList.add(' +
    '"diagram-unavailable");');
  AppendLine(Result, '    diagrams.forEach(hideDiagram);');
  AppendLine(Result, '    console.warn("PasWeave could not render the architecture ' +
    'diagrams.", error || "local Mermaid runtime unavailable");');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function prepareDiagrams() {');
  AppendLine(Result, '    diagrams.forEach(function (diagram) {');
  AppendLine(Result, '      var container = diagram.closest(' +
    '"[data-diagram-container]");');
  AppendLine(Result, '      var source = diagram.getAttribute(' +
    '"data-mermaid-source");');
  AppendLine(Result, '      if (source != null) diagram.textContent = source;');
  AppendLine(Result, '      diagram.removeAttribute("data-diagram-rendered");');
  AppendLine(Result, '      if (container) {');
  AppendLine(Result, '        container.hidden = false;');
  AppendLine(Result, '        container.setAttribute("data-diagram-rendering", "");');
  AppendLine(Result, '        container.setAttribute("aria-hidden", "true");');
  AppendLine(Result, '        container.removeAttribute("data-diagram-interactive");');
  AppendLine(Result, '      }');
  AppendLine(Result, '    });');
  AppendLine(Result, '  }');
  AppendLine(Result, '  function renderDiagrams() {');
  AppendLine(Result, '    prepareDiagrams();');
  AppendLine(Result, '    var theme = activeScheme();');
  AppendLine(Result, '    try {');
  AppendLine(Result, '      window.mermaid.initialize({');
  AppendLine(Result, '        startOnLoad: false,');
  AppendLine(Result, '        securityLevel: "loose",');
  AppendLine(Result, '        deterministicIds: true,');
  AppendLine(Result, '        deterministicIDSeed: ' +
    '"pasweave-architecture-diagrams",');
  AppendLine(Result, '        theme: theme === "dark" ? "dark" : "neutral",');
  AppendLine(Result, '        flowchart: { htmlLabels: false, ' +
    'useMaxWidth: true }');
  AppendLine(Result, '      });');
  AppendLine(Result, '      Promise.resolve(window.mermaid.run({');
  AppendLine(Result, '        nodes: diagrams, suppressErrors: true');
  AppendLine(Result, '      })).then(function () {');
  AppendLine(Result, '        diagrams.forEach(function (diagram) {');
  AppendLine(Result, '          var section = diagram.closest(' +
    '"[data-diagram-section]");');
  AppendLine(Result, '          var container = diagram.closest(' +
    '"[data-diagram-container]");');
  AppendLine(Result, '          var fallback = section && section.querySelector(' +
    '"[data-diagram-fallback]");');
  AppendLine(Result, '          if (!diagram.querySelector("svg")) {');
  AppendLine(Result, '            hideDiagram(diagram);');
  AppendLine(Result, '            return;');
  AppendLine(Result, '          }');
  AppendLine(Result, '          diagram.setAttribute("data-diagram-rendered", ' +
    '"true");');
  AppendLine(Result, '          if (container) {');
  AppendLine(Result, '            container.removeAttribute(' +
    '"data-diagram-rendering");');
  AppendLine(Result, '            container.removeAttribute("aria-hidden");');
  AppendLine(Result, '          }');
  AppendLine(Result, '          setupInteraction(diagram, container, section);');
  AppendLine(Result, '          if (fallback) fallback.removeAttribute("open");');
  AppendLine(Result, '        });');
  AppendLine(Result, '      }).catch(unavailable);');
  AppendLine(Result, '    } catch (error) {');
  AppendLine(Result, '      unavailable(error);');
  AppendLine(Result, '    }');
  AppendLine(Result, '  }');
  AppendLine(Result, '  if (!window.mermaid || ' +
    'typeof window.mermaid.run !== "function") {');
  AppendLine(Result, '    unavailable();');
  AppendLine(Result, '    return;');
  AppendLine(Result, '  }');
  AppendLine(Result, '  renderDiagrams();');
  AppendLine(Result, '  document.addEventListener("pasweave:themechange", ' +
    'function () { renderDiagrams(); });');
  AppendLine(Result, '}());');
end;

end.
