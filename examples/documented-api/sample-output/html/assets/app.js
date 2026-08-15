(function () {
  "use strict";
  var input = document.querySelector("[data-search-input]");
  if (!input) return;
  var panel = document.querySelector("[data-search-panel]");
  var list = document.querySelector("[data-search-results]");
  var status = document.querySelector("[data-search-status]");
  var unitFilter = document.querySelector("[data-search-unit]");
  var kindFilter = document.querySelector("[data-search-kind]");
  var visibilityFilter = document.querySelector("[data-search-visibility]");
  var documentationFilter = document.querySelector("[data-search-documentation]");
  var entries = window.PASWEAVE_SEARCH_INDEX || [];
  var root = document.body.dataset.siteRoot || "";
  function searchable(item) {
    return [item.name, item.qualifiedName, item.kind, item.unit, item.summary].join(" ").toLowerCase();
  }
  function score(item, query) {
    var name = item.name.toLowerCase();
    var qualified = item.qualifiedName.toLowerCase();
    var value = searchable(item);
    var tokens = query.split(/\s+/).filter(Boolean);
    if (!tokens.every(function (token) { return value.indexOf(token) >= 0; })) return -1;
    var result = item.summary ? 4 : 0;
    if (name === query) result += 1000;
    else if (name.indexOf(query) === 0) result += 500;
    else if (qualified.indexOf(query) === 0) result += 220;
    else if (name.indexOf(query) >= 0) result += 120;
    return result;
  }
  function matchesFilters(item) {
    if (unitFilter.value && item.unit !== unitFilter.value) return false;
    if (kindFilter.value && item.kind !== kindFilter.value) return false;
    if (visibilityFilter.value && item.visibility !== visibilityFilter.value) return false;
    if (documentationFilter.value === "documented" && !item.documented) return false;
    if (documentationFilter.value === "undocumented" && item.documented) return false;
    return true;
  }
  function hasActiveFilter() {
    return unitFilter.value || kindFilter.value || visibilityFilter.value || documentationFilter.value;
  }
  function addResult(item) {
    var li = document.createElement("li");
    var link = document.createElement("a");
    link.className = "search-result";
    link.href = root + item.url;
    var title = document.createElement("strong");
    title.textContent = item.qualifiedName;
    var kind = document.createElement("span");
    kind.textContent = item.kind;
    link.appendChild(title);
    link.appendChild(kind);
    if (item.summary) {
      var summary = document.createElement("small");
      summary.textContent = item.summary;
      link.appendChild(summary);
    }
    li.appendChild(link);
    list.appendChild(li);
  }
  function closeSearch() {
    panel.hidden = true;
    input.setAttribute("aria-expanded", "false");
  }
  function openSearch() {
    panel.hidden = false;
    input.setAttribute("aria-expanded", "true");
    if (!input.value.trim() && !hasActiveFilter()) status.textContent = "Type to search or choose filters.";
  }
  function resultLinks() {
    return Array.prototype.slice.call(list.querySelectorAll("a.search-result"));
  }
  function moveResultFocus(current, offset) {
    var links = resultLinks();
    if (!links.length) return;
    var index = links.indexOf(current);
    links[(index + offset + links.length) % links.length].focus();
  }
  function update() {
    var query = input.value.trim().toLowerCase();
    list.replaceChildren();
    if (!query && !hasActiveFilter()) { closeSearch(); return; }
    var matches = entries.map(function (item) {
      return { item: item, score: score(item, query) };
    }).filter(function (match) { return match.score >= 0 && matchesFilters(match.item); });
    matches.sort(function (left, right) {
      return right.score - left.score || left.item.qualifiedName.localeCompare(right.item.qualifiedName);
    });
    matches.slice(0, 24).forEach(function (match) { addResult(match.item); });
    status.textContent = matches.length ? matches.length + (matches.length === 1 ? " result" : " results") + (matches.length > 24 ? "; first 24 shown" : "") : "No symbols match the current search and filters.";
    panel.hidden = false;
    input.setAttribute("aria-expanded", "true");
  }
  input.addEventListener("input", update);
  input.addEventListener("focus", openSearch);
  input.addEventListener("keydown", function (event) {
    if (event.key === "Escape") { closeSearch(); input.blur(); }
    else if (event.key === "ArrowDown") {
      var links = resultLinks();
      if (links.length) { event.preventDefault(); links[0].focus(); }
    }
  });
  list.addEventListener("keydown", function (event) {
    var link = event.target.closest("a.search-result");
    if (!link) return;
    if (event.key === "ArrowDown") { event.preventDefault(); moveResultFocus(link, 1); }
    else if (event.key === "ArrowUp") { event.preventDefault(); moveResultFocus(link, -1); }
    else if (event.key === "Escape") { event.preventDefault(); input.focus(); closeSearch(); }
  });
  panel.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && !event.target.closest("[data-search-results]")) {
      event.preventDefault(); input.focus(); closeSearch();
    }
  });
  [unitFilter, kindFilter, visibilityFilter, documentationFilter].forEach(function (filter) {
    filter.addEventListener("change", update);
  });
  document.addEventListener("keydown", function (event) {
    var tag = document.activeElement && document.activeElement.tagName;
    if (event.key === "/" && tag !== "INPUT" && tag !== "TEXTAREA") {
      event.preventDefault(); input.focus();
    }
  });
  document.addEventListener("click", function (event) {
    if (!event.target.closest("[data-search-container]")) closeSearch();
  });
  var themeControl = document.querySelector("[data-theme-control]");
  if (themeControl) {
    var themeSelect = themeControl.querySelector("[data-theme-select]");
    var currentTheme = document.documentElement.getAttribute("data-theme") || "system";
    if (["system", "light", "dark"].indexOf(currentTheme) < 0) currentTheme = "system";
    if (themeSelect) {
      themeSelect.value = currentTheme;
      themeSelect.addEventListener("change", function () {
        var next = themeSelect.value;
        document.documentElement.setAttribute("data-theme", next);
        try {
          window.localStorage.setItem("pasweave-theme", next);
        } catch (error) {
          /* storage unavailable; keep the choice for this page */
        }
        document.dispatchEvent(new window.CustomEvent("pasweave:themechange", { detail: { theme: next } }));
      });
    }
    themeControl.hidden = false;
  }
  var symbolIndex = document.querySelector("[data-symbol-index]");
  if (symbolIndex) {
    var symbolFilters = Array.prototype.slice.call(symbolIndex.querySelectorAll("[data-symbol-filter]"));
    var symbolEntries = Array.prototype.slice.call(symbolIndex.querySelectorAll("[data-symbol-entry]"));
    var symbolSections = Array.prototype.slice.call(symbolIndex.querySelectorAll("[data-symbol-letter]"));
    var symbolStatus = symbolIndex.querySelector("[data-symbol-status]");
    function symbolGroups() {
      return symbolFilters.filter(function (filter) { return filter.checked; })
        .map(function (filter) { return filter.value; });
    }
    function updateSymbolIndex() {
      var groups = symbolGroups();
      var visible = 0;
      symbolEntries.forEach(function (entry) {
        var shown = groups.indexOf(entry.getAttribute("data-symbol-kind")) >= 0;
        entry.hidden = !shown;
        if (shown) visible += 1;
      });
      symbolSections.forEach(function (section) {
        var any = section.querySelector("[data-symbol-entry]:not([hidden])");
        section.hidden = !any;
      });
      if (symbolStatus) {
        symbolStatus.textContent = visible + (visible === 1 ? " symbol" : " symbols");
      }
    }
    symbolFilters.forEach(function (filter) {
      filter.addEventListener("change", updateSymbolIndex);
    });
    function applySymbolHash() {
      var hash = window.location.hash.replace(/^#/, "");
      var known = ["types", "routines", "members", "constants", "variables"];
      if (known.indexOf(hash) < 0) return;
      symbolFilters.forEach(function (filter) {
        filter.checked = filter.value === hash;
      });
      updateSymbolIndex();
    }
    applySymbolHash();
  }
  var unitSwitcher = document.querySelector("[data-unit-switcher]");
  if (!unitSwitcher) return;
  var unitInput = unitSwitcher.querySelector("[data-unit-switcher-filter]");
  var unitList = unitSwitcher.querySelector("[data-unit-switcher-list]");
  var unitStatus = unitSwitcher.querySelector("[data-unit-switcher-status]");
  var unitSummary = unitSwitcher.querySelector("summary");
  var unitItems = Array.prototype.slice.call(unitList.querySelectorAll("li"));
  function visibleUnitLinks() {
    return unitItems.filter(function (item) { return !item.hidden; })
      .map(function (item) { return item.querySelector("a"); });
  }
  function updateUnitSwitcher() {
    var query = unitInput.value.trim().toLowerCase();
    unitItems.forEach(function (item) {
      var link = item.querySelector("a");
      item.hidden = link.textContent.toLowerCase().indexOf(query) < 0;
    });
    var count = visibleUnitLinks().length;
    unitStatus.textContent = count ? count + (count === 1 ? " unit" : " units") : "No units match “" + unitInput.value.trim() + "”.";
  }
  function moveUnitFocus(current, offset) {
    var links = visibleUnitLinks();
    if (!links.length) return;
    var index = links.indexOf(current);
    links[(index + offset + links.length) % links.length].focus();
  }
  function closeUnitSwitcher() {
    unitSwitcher.open = false;
    unitSummary.focus();
  }
  unitInput.addEventListener("input", updateUnitSwitcher);
  unitInput.addEventListener("keydown", function (event) {
    if (event.key === "ArrowDown") {
      var links = visibleUnitLinks();
      if (links.length) { event.preventDefault(); links[0].focus(); }
    } else if (event.key === "Escape") {
      event.preventDefault(); unitInput.value = ""; updateUnitSwitcher(); closeUnitSwitcher();
    }
  });
  unitList.addEventListener("keydown", function (event) {
    var link = event.target.closest("a");
    if (!link) return;
    if (event.key === "ArrowDown") { event.preventDefault(); moveUnitFocus(link, 1); }
    else if (event.key === "ArrowUp") { event.preventDefault(); moveUnitFocus(link, -1); }
    else if (event.key === "Escape") { event.preventDefault(); closeUnitSwitcher(); }
  });
  unitSwitcher.addEventListener("toggle", function () {
    if (unitSwitcher.open) unitInput.focus();
  });
}());
