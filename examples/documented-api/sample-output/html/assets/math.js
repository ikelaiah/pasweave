(function () {
  "use strict";
  function sourceText(element, displayMode) {
    var source = element.textContent.trim();
    var delimiter = displayMode ? "$$" : "$";
    if (source.indexOf(delimiter) === 0 && source.slice(-delimiter.length) === delimiter) {
      source = source.slice(delimiter.length, -delimiter.length);
    }
    return source.trim();
  }
  function renderElement(element) {
    var displayMode = element.hasAttribute("data-math-display");
    var original = element.textContent;
    var source = sourceText(element, displayMode);
    try {
      window.katex.render(source, element, {
        displayMode: displayMode,
        throwOnError: true,
        strict: "warn",
        trust: false
      });
      element.setAttribute("data-math-rendered", "true");
    } catch (error) {
      var message = error && error.message ? error.message : "unknown KaTeX error";
      element.textContent = original;
      element.classList.add("math-error");
      element.setAttribute("data-math-error", "true");
      element.setAttribute("title", "KaTeX: " + message);
      console.warn("PasWeave could not render mathematics:", source, error);
    }
  }
  if (!window.katex || typeof window.katex.render !== "function") {
    document.documentElement.classList.add("math-unavailable");
    console.warn("PasWeave could not load the local KaTeX runtime.");
    return;
  }
  document.querySelectorAll("[data-math-inline], [data-math-display]").forEach(renderElement);
}());
