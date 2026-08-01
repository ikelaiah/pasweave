(function () {
  "use strict";
  var MIN_SCALE = 0.5;
  var MAX_SCALE = 3;
  var SCALE_STEP = 0.25;
  var PAN_STEP = 96;
  var diagrams = Array.prototype.slice.call(document.querySelectorAll("[data-mermaid]"));
  if (!diagrams.length) return;
  var reducedMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  function interactionElements(diagram) {
    var section = diagram.closest("[data-diagram-section]");
    return {
      section: section,
      toolbar: section && section.querySelector("[data-diagram-toolbar]"),
      help: section && section.querySelector("[data-diagram-help]")
    };
  }
  function hideDiagram(diagram) {
    var container = diagram.closest("[data-diagram-container]");
    var elements = interactionElements(diagram);
    if (container) {
      container.hidden = true;
      container.removeAttribute("data-diagram-rendering");
      container.setAttribute("aria-hidden", "true");
    }
    if (elements.toolbar) elements.toolbar.hidden = true;
    if (elements.help) elements.help.hidden = true;
  }
  function setDisabled(control, disabled) {
    if (control) control.disabled = disabled;
  }
  function setupInteraction(diagram, container, section) {
    var svg = diagram.querySelector("svg");
    var toolbar = section && section.querySelector("[data-diagram-toolbar]");
    var help = section && section.querySelector("[data-diagram-help]");
    if (!svg || !container || !toolbar) return;
    var zoomOut = toolbar.querySelector("[data-diagram-zoom-out]");
    var zoomIn = toolbar.querySelector("[data-diagram-zoom-in]");
    var scaleOutput = toolbar.querySelector("[data-diagram-scale]");
    var panLeft = toolbar.querySelector("[data-diagram-pan-left]");
    var panUp = toolbar.querySelector("[data-diagram-pan-up]");
    var panDown = toolbar.querySelector("[data-diagram-pan-down]");
    var panRight = toolbar.querySelector("[data-diagram-pan-right]");
    var reset = toolbar.querySelector("[data-diagram-reset]");
    var panControls = [panLeft, panUp, panDown, panRight];
    var scale = 1;
    var drag = null;
    var suppressClick = false;
    function updateControls() {
      var maxLeft = Math.max(0, container.scrollWidth - container.clientWidth);
      var maxTop = Math.max(0, container.scrollHeight - container.clientHeight);
      var left = Math.max(0, Math.min(maxLeft, container.scrollLeft));
      var top = Math.max(0, Math.min(maxTop, container.scrollTop));
      if (scaleOutput) scaleOutput.textContent = Math.round(scale * 100) + "%";
      container.setAttribute("data-diagram-scale", String(Math.round(scale * 100)));
      container.setAttribute("data-diagram-pan-x", String(Math.round(left)));
      container.setAttribute("data-diagram-pan-y", String(Math.round(top)));
      setDisabled(zoomOut, scale <= MIN_SCALE);
      setDisabled(zoomIn, scale >= MAX_SCALE);
      setDisabled(panLeft, left <= 1);
      setDisabled(panUp, top <= 1);
      setDisabled(panRight, left >= maxLeft - 1);
      setDisabled(panDown, top >= maxTop - 1);
      setDisabled(reset, scale === 1 && left <= 1 && top <= 1);
    }
    function applyScale(nextScale) {
      nextScale = Math.max(MIN_SCALE, Math.min(MAX_SCALE, Math.round(nextScale * 100) / 100));
      if (nextScale === scale) return;
      var oldWidth = Math.max(1, container.scrollWidth);
      var oldHeight = Math.max(1, container.scrollHeight);
      var centerX = (container.scrollLeft + container.clientWidth / 2) / oldWidth;
      var centerY = (container.scrollTop + container.clientHeight / 2) / oldHeight;
      scale = nextScale;
      svg.style.maxWidth = "none";
      svg.style.width = Math.round(scale * 100) + "%";
      container.scrollLeft = Math.max(0, centerX * container.scrollWidth - container.clientWidth / 2);
      container.scrollTop = Math.max(0, centerY * container.scrollHeight - container.clientHeight / 2);
      updateControls();
    }
    function pan(left, top) {
      container.scrollBy({
        left: left, top: top,
        behavior: reducedMotion ? "auto" : "smooth"
      });
    }
    function resetView() {
      scale = 1;
      svg.style.maxWidth = "none";
      svg.style.width = "100%";
      container.scrollLeft = 0;
      container.scrollTop = 0;
      updateControls();
    }
    if (zoomOut) zoomOut.addEventListener("click", function () { applyScale(scale - SCALE_STEP); });
    if (zoomIn) zoomIn.addEventListener("click", function () { applyScale(scale + SCALE_STEP); });
    if (panLeft) panLeft.addEventListener("click", function () { pan(-PAN_STEP, 0); });
    if (panUp) panUp.addEventListener("click", function () { pan(0, -PAN_STEP); });
    if (panDown) panDown.addEventListener("click", function () { pan(0, PAN_STEP); });
    if (panRight) panRight.addEventListener("click", function () { pan(PAN_STEP, 0); });
    if (reset) reset.addEventListener("click", resetView);
    container.addEventListener("keydown", function (event) {
      if (event.target !== container) return;
      if (event.altKey || event.ctrlKey || event.metaKey) return;
      var handled = true;
      if (event.key === "ArrowLeft") pan(-PAN_STEP, 0);
      else if (event.key === "ArrowRight") pan(PAN_STEP, 0);
      else if (event.key === "ArrowUp") pan(0, -PAN_STEP);
      else if (event.key === "ArrowDown") pan(0, PAN_STEP);
      else if (event.key === "+" || event.key === "=") applyScale(scale + SCALE_STEP);
      else if (event.key === "-" || event.key === "_") applyScale(scale - SCALE_STEP);
      else if (event.key === "0") resetView();
      else handled = false;
      if (handled) event.preventDefault();
    });
    container.addEventListener("scroll", updateControls, { passive: true });
    container.addEventListener("pointerdown", function (event) {
      if (event.button !== 0 || event.pointerType === "touch" || event.target.closest("a, button")) return;
      drag = { id: event.pointerId, x: event.clientX, y: event.clientY, left: container.scrollLeft, top: container.scrollTop };
      suppressClick = false;
      container.setPointerCapture(event.pointerId);
      container.setAttribute("data-diagram-dragging", "");
      event.preventDefault();
    });
    container.addEventListener("pointermove", function (event) {
      if (!drag || drag.id !== event.pointerId) return;
      var deltaX = event.clientX - drag.x;
      var deltaY = event.clientY - drag.y;
      if (Math.abs(deltaX) > 3 || Math.abs(deltaY) > 3) suppressClick = true;
      container.scrollLeft = drag.left - deltaX;
      container.scrollTop = drag.top - deltaY;
      event.preventDefault();
    });
    function endDrag(event) {
      if (!drag || drag.id !== event.pointerId) return;
      drag = null;
      container.removeAttribute("data-diagram-dragging");
      if (container.hasPointerCapture(event.pointerId)) container.releasePointerCapture(event.pointerId);
      window.setTimeout(function () { suppressClick = false; }, 0);
    }
    container.addEventListener("pointerup", endDrag);
    container.addEventListener("pointercancel", endDrag);
    container.addEventListener("click", function (event) {
      if (!suppressClick) return;
      event.preventDefault();
      event.stopPropagation();
    }, true);
    svg.style.maxWidth = "none";
    svg.style.width = "100%";
    container.setAttribute("data-diagram-interactive", "");
    container.setAttribute("aria-keyshortcuts", "ArrowLeft ArrowRight ArrowUp ArrowDown + - 0");
    panControls.forEach(function (control) {
      if (control) control.removeAttribute("aria-hidden");
    });
    toolbar.hidden = false;
    if (help) help.hidden = false;
    if (window.ResizeObserver) new window.ResizeObserver(updateControls).observe(container);
    updateControls();
  }
  function unavailable(error) {
    document.documentElement.classList.add("diagram-unavailable");
    diagrams.forEach(hideDiagram);
    console.warn("PasWeave could not render the architecture diagrams.", error || "local Mermaid runtime unavailable");
  }
  if (!window.mermaid || typeof window.mermaid.run !== "function") {
    unavailable();
    return;
  }
  var dark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
  try {
    window.mermaid.initialize({
      startOnLoad: false,
      securityLevel: "loose",
      deterministicIds: true,
      deterministicIDSeed: "pasweave-architecture-diagrams",
      theme: dark ? "dark" : "neutral",
      flowchart: { htmlLabels: false, useMaxWidth: true }
    });
    diagrams.forEach(function (diagram) {
      var container = diagram.closest("[data-diagram-container]");
      if (container) {
        container.hidden = false;
        container.setAttribute("data-diagram-rendering", "");
      }
    });
    Promise.resolve(window.mermaid.run({
      nodes: diagrams, suppressErrors: true
    })).then(function () {
      diagrams.forEach(function (diagram) {
        var section = diagram.closest("[data-diagram-section]");
        var container = diagram.closest("[data-diagram-container]");
        var fallback = section && section.querySelector("[data-diagram-fallback]");
        if (!diagram.querySelector("svg")) {
          hideDiagram(diagram);
          return;
        }
        diagram.setAttribute("data-diagram-rendered", "true");
        if (container) {
          container.removeAttribute("data-diagram-rendering");
          container.removeAttribute("aria-hidden");
        }
        setupInteraction(diagram, container, section);
        if (fallback) fallback.removeAttribute("open");
      });
    }).catch(unavailable);
  } catch (error) {
    unavailable(error);
  }
}());
