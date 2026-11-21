// @ts-check
const storageKey = "pokelet-cursor-v1";
const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
const finePointer = matchMedia("(any-pointer: fine)");
const forcedColours = matchMedia("(forced-colors: active)");
const nativeControls = "input:not([type=checkbox],[type=radio]), textarea, select, [contenteditable]:not([contenteditable=false])";
const responses = [0.15, 0.34, 0.56, 0.76, 1];

/** @param {Element} element */
function cancelArt(element) {
  element.getAnimations().forEach((animation) => animation.cancel());
}

/** @param {HTMLElement} element @param {number} x @param {number} y */
function place(element, x, y) {
  element.style.transform = `translate(${x}px, ${y}px)`;
}

/** The original canvas is 104 pt with hotspot (32, 15). The 52 px sprite uses (16, 8).
 * @param {string} character @param {string} palette @param {string} suffix */
function artwork(character, palette, suffix) {
  return new URL(`assets/characters/${character}-${palette}${suffix}`, import.meta.url).href;
}

export function initialiseCursor() {
  const root = document.documentElement;
  const picker = document.querySelector(".cursor-picker");
  const opener = document.querySelector(".hero-picker");
  const reset = document.querySelector(".reset-button");
  const palette = document.getElementById("palette");
  const response = document.getElementById("response");
  const sound = document.querySelector('input[name="sound"]');
  const livePointer = document.querySelector(".live-pointer");
  const liveArt = livePointer?.querySelector("img");
  const impact = document.querySelector(".impact");
  const effect = impact?.querySelector("svg");
  if (!(picker instanceof HTMLDetailsElement) || !(opener instanceof HTMLButtonElement) ||
      !(reset instanceof HTMLButtonElement) || !(palette instanceof HTMLSelectElement) ||
      !(response instanceof HTMLSelectElement) || !(sound instanceof HTMLInputElement) ||
      !(livePointer instanceof HTMLElement) || !liveArt || !(impact instanceof HTMLElement) || !effect) return;

  const summary = picker.querySelector("summary");
  const badge = summary?.querySelector("img");
  if (!summary || !badge) return;
  const choices = [...picker.querySelectorAll('input[name="character"]')].filter(
    (input) => input instanceof HTMLInputElement
  );
  const pieces = [...document.querySelectorAll("button.hero-piece")].filter(
    (button) => button instanceof HTMLButtonElement
  );
  const clickSound = new Audio();
  clickSound.preload = "none";
  clickSound.volume = 0.35;

  let character = "finger";
  let normal = false;
  let spriteReady = false;
  let pointerType = "";
  let assetGeneration = 0;
  /** @type {Animation | undefined} */
  let reaction;
  /** @type {number[]} */
  let clicks = [];

  try {
    const saved = JSON.parse(localStorage.getItem(storageKey) ?? "null");
    if (saved) {
      if (choices.some((choice) => choice.value === saved.character)) character = saved.character;
      if ([...palette.options].some((option) => option.value === saved.palette)) palette.value = saved.palette;
      if ([...response.options].some((option) => option.value === saved.response)) response.value = saved.response;
      normal = saved.normal === true;
    }
  } catch {
    // Keep the default selection if local storage is unavailable.
  }

  const remember = () => {
    try {
      localStorage.setItem(storageKey, JSON.stringify({ character, palette: palette.value, response: response.value, normal }));
    } catch {
      // The current selection still works without storage.
    }
  };

  const stopReaction = () => {
    if (!reaction) return;
    root.removeAttribute("data-cursor-reaction");
    reaction.cancel();
    reaction = undefined;
  };

  const useNativeCursor = () => {
    root.removeAttribute("data-pokelet");
    root.style.removeProperty("--site-cursor");
  };

  const updateCursor = () => {
    stopReaction();
    cancelArt(effect);
    const generation = ++assetGeneration;
    spriteReady = false;
    reset.setAttribute("aria-pressed", String(normal));
    picker.toggleAttribute("data-native", normal);
    choices.forEach((choice) => { choice.checked = !normal && choice.value === character; });
    pieces.forEach((piece) => {
      const selected = !normal && piece.dataset.character === character;
      piece.setAttribute("aria-pressed", String(selected));
      const image = piece.querySelector("img");
      const appearance = selected ? palette.value : "original";
      if (!image || !piece.dataset.character) return;
      const preview = artwork(piece.dataset.character, appearance, ".webp");
      if (image.src !== preview) image.src = preview;
    });

    const url = artwork(character, palette.value, "-cursor.png");
    badge.src = url;
    const cursor = `url("${url}") 16 8, auto`;
    if (normal || !finePointer.matches || forcedColours.matches || !CSS.supports("cursor", cursor)) {
      useNativeCursor();
      return;
    }

    // Preload separately so a rapid change cannot swap the visible sprite under an old reaction.
    const image = new Image();
    image.addEventListener("load", () => {
      if (generation !== assetGeneration) return;
      liveArt.src = artwork(character, palette.value, ".webp");
      root.style.setProperty("--site-cursor", cursor);
      root.dataset.pokelet = "";
      spriteReady = true;
    }, { once: true });
    image.addEventListener("error", () => {
      if (generation === assetGeneration) useNativeCursor();
    }, { once: true });
    image.src = url;
  };

  const playSample = () => {
    if (!clickSound.src) clickSound.src = new URL("assets/tap.wav", import.meta.url).href;
    clickSound.currentTime = 0;
    clickSound.play().catch(() => { sound.checked = false; });
  };

  /** @param {string} next */
  const changeCharacter = (next) => {
    if (next === character && !normal) return;
    character = next;
    normal = false;
    clicks = [];
    updateCursor();
    remember();
  };

  picker.addEventListener("change", (event) => {
    const input = event.target;
    if (input === sound) {
      if (sound.checked) playSample();
      else clickSound.pause();
    } else if (input === palette) {
      // Previewing a colour explicitly re-enables the custom cursor.
      normal = false;
      updateCursor();
      remember();
    } else if (input === response) {
      remember();
    } else if (input instanceof HTMLInputElement && choices.includes(input)) {
      changeCharacter(input.value);
    }
  });

  reset.addEventListener("click", () => {
    normal = !normal;
    clicks = [];
    updateCursor();
    remember();
  });

  opener.addEventListener("click", () => {
    picker.open = !picker.open;
    if (picker.open) summary.focus({ preventScroll: true });
  });
  picker.addEventListener("toggle", () => {
    opener.setAttribute("aria-expanded", String(picker.open));
    if (picker.open) document.querySelector(".menu-toggle")?.setAttribute("aria-expanded", "false");
  });
  document.addEventListener("click", (event) => {
    if (picker.open && event.target instanceof Node && !picker.contains(event.target) && !opener.contains(event.target)) {
      if (picker.contains(document.activeElement)) summary.focus({ preventScroll: true });
      picker.open = false;
    }
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && picker.open) {
      picker.open = false;
      summary.focus();
    }
  });

  document.addEventListener("pointerdown", (event) => {
    stopReaction();
    pointerType = event.pointerType;
  }, { passive: true });
  document.addEventListener("pointermove", (event) => {
    if (!reaction) return;
    if (event.buttons || (event.target instanceof Element && event.target.closest(nativeControls))) stopReaction();
    else place(livePointer, event.clientX, event.clientY);
  }, { passive: true });
  root.addEventListener("pointerleave", stopReaction);
  window.addEventListener("blur", stopReaction);
  window.addEventListener("scroll", stopReaction, { capture: true, passive: true });
  document.addEventListener("dragstart", stopReaction);
  document.addEventListener("pointercancel", stopReaction);
  document.addEventListener("visibilitychange", stopReaction);
  reducedMotion.addEventListener("change", () => {
    stopReaction();
    cancelArt(effect);
    pieces.forEach((piece) => {
      const image = piece.querySelector("img");
      if (image) cancelArt(image);
    });
  });
  finePointer.addEventListener("change", updateCursor);
  forcedColours.addEventListener("change", updateCursor);

  /** @param {MouseEvent} event */
  const poke = (event) => {
    if (normal || forcedColours.matches || !(event.target instanceof Element) || typeof impact.animate !== "function") return;
    const control = event.target.closest("a, button, summary, label");
    const piece = event.target.closest(".hero-piece");
    const secondary = event.type === "contextmenu";
    const fromPointer = Boolean(event.detail) || (secondary && event.button === 2);
    if (!fromPointer && !control) return;

    const reduced = reducedMotion.matches;
    const now = performance.now();
    clicks = clicks.filter((time) => now - time <= 650).slice(-5);
    clicks.push(now);
    const energy = responses[Number(response.value)] * (1 + (clicks.length - 1) * .105);
    const native = Boolean(event.target.closest(nativeControls) || window.getSelection()?.type === "Range");
    const mouseLike = pointerType === "mouse" || pointerType === "pen";
    const showLive = !secondary && fromPointer && mouseLike && !reduced && !native && spriteReady &&
      liveArt.complete && liveArt.naturalWidth > 0;
    const bounds = fromPointer ? undefined : control?.getBoundingClientRect();

    stopReaction();
    cancelArt(effect);
    place(impact, bounds ? bounds.left + bounds.width / 2 : event.clientX,
      bounds ? bounds.top + bounds.height / 2 : event.clientY);
    impact.dataset.shape = reduced || secondary ? "ring" : character === "catPaw" ? "paw" : "rays";
    effect.animate(reduced
      ? [{ opacity: 0 }, { opacity: .85 }, { opacity: 0 }]
      : [{ opacity: 0, scale: ".55" }, { opacity: 1, scale: ".85", offset: .23 }, { opacity: 0, scale: String(1 + energy * .65) }],
      { duration: reduced ? 150 : 290, easing: "ease-out" });

    const art = showLive ? liveArt : piece?.querySelector("img");
    if (!reduced && art) {
      const squash = character === "catPaw" ? .25 : character === "comicArrow" ? .12 : .20;
      cancelArt(art);
      const animation = art.animate([
        { scale: "1", rotate: "0rad" },
        { scale: `${1 + energy * .17} ${1 - energy * squash}`, rotate: `${energy * .055}rad`, offset: .2 },
        { scale: `${1 - energy * .05} ${1 + energy * .13}`, rotate: `${-energy * .03}rad`, offset: .55 },
        { scale: "1", rotate: "0rad" },
      ], { duration: 240, easing: "ease-out" });
      if (showLive) {
        place(livePointer, event.clientX, event.clientY);
        reaction = animation;
        root.dataset.cursorReaction = "";
        animation.onfinish = () => { if (reaction === animation) stopReaction(); };
      }
    }
    // Toggling the checkbox previews its sample in the change handler.
    if (sound.checked && !event.target.closest(".sound-toggle")) playSample();
  };

  pieces.forEach((piece) => {
    piece.disabled = false;
    piece.addEventListener("click", () => {
      if (piece.dataset.character) changeCharacter(piece.dataset.character);
    });
  });
  document.addEventListener("click", poke, { passive: true });
  document.addEventListener("contextmenu", poke, { passive: true });
  sound.checked = false;
  picker.hidden = opener.hidden = false;
  updateCursor();
}
