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
}());
