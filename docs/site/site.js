// @ts-check

const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
const menuToggle = document.querySelector(".menu-toggle");
const navigation = document.getElementById("primary-nav");

if (menuToggle instanceof HTMLButtonElement && navigation) {
  menuToggle.hidden = false;
  navigation.dataset.collapsible = "";

  /** @param {boolean} open */
  const setMenu = (open) => menuToggle.setAttribute("aria-expanded", String(open));
  menuToggle.addEventListener("click", () => setMenu(menuToggle.getAttribute("aria-expanded") !== "true"));
  for (const link of navigation.querySelectorAll('a[href^="#"]')) {
    link.addEventListener("click", () => {
      if (menuToggle.getAttribute("aria-expanded") !== "true") return;
      setMenu(false);
      const section = document.getElementById(link.getAttribute("href")?.slice(1) ?? "");
      if (section) {
        section.tabIndex = -1;
        section.focus({ preventScroll: true });
      }
    });
  }
  menuToggle.closest("header")?.addEventListener("keydown", (event) => {
    if (event.key !== "Escape" || menuToggle.getAttribute("aria-expanded") !== "true") return;
    setMenu(false);
    menuToggle.focus();
  });
}

const heroTrigger = document.querySelector(".hero-trigger");
const heroCharacters = document.querySelectorAll(".hero-character");
if (heroTrigger instanceof HTMLButtonElement) {
  heroTrigger.hidden = false;
  heroTrigger.addEventListener("click", () => {
    heroCharacters.forEach((character, index) => {
      character.getAnimations().forEach((animation) => animation.cancel());
      character.animate(
        reducedMotion.matches
          ? [{ opacity: 1 }, { opacity: 0.7 }, { opacity: 1 }]
          : [{ scale: "1" }, { scale: "1.06 .86", offset: .27 }, { scale: ".96 1.06", offset: .62 }, { scale: "1" }],
        { duration: reducedMotion.matches ? 160 : 310, delay: reducedMotion.matches ? 0 : index * 28, easing: "ease-out" }
      );
    });
  });
}

const playground = document.querySelector("[data-playground]");
if (playground instanceof HTMLElement) initialisePlayground(playground);

/** @param {HTMLElement} root */
function initialisePlayground(root) {
  const controls = root.querySelector(".controls");
  const target = root.querySelector(".play-target");
  const reset = root.querySelector(".reset-button");
  const hint = root.querySelector("#play-hint");
  const poster = root.querySelector(".stage-character");
  const livePointer = root.querySelector(".live-pointer");
  const liveArt = root.querySelector(".live-pointer img");
  const impact = root.querySelector(".impact");
  const palette = root.querySelector('[name="palette"]');
  const response = root.querySelector('[name="response"]');
  const sound = root.querySelector('[name="sound"]');

  if (!(controls instanceof HTMLElement) || !(target instanceof HTMLButtonElement) || !(reset instanceof HTMLButtonElement) ||
      !(hint instanceof HTMLElement) || !(poster instanceof HTMLImageElement) ||
      !(livePointer instanceof HTMLElement) || !(liveArt instanceof HTMLImageElement) ||
      !(impact instanceof HTMLElement) || !(palette instanceof HTMLSelectElement) ||
      !(response instanceof HTMLSelectElement) || !(sound instanceof HTMLInputElement)) return;

  const finePointer = matchMedia("(any-pointer: fine)");
  const energyLevels = [0.15, 0.34, 0.56, 0.76, 1];
  const clickSound = new Audio();
  clickSound.preload = "none";
  clickSound.volume = 0.35;

  let character = "finger";
  let normal = false;
  let pointerReady = false;
  let pointerType = "";
  /** @type {Animation | undefined} */
  let pointerAnimation;
  /** @type {number[]} */
  let clicks = [];

  /** @param {string} suffix */
  const artwork = (suffix) =>
    new URL(`assets/characters/${character}-${palette.value}${suffix}`, import.meta.url).href;

  const stopPointerAnimation = () => {
    target.classList.remove("is-animating");
    pointerAnimation?.cancel();
    pointerAnimation = undefined;
  };

  const updateCursor = () => {
    const cursor = artwork("-cursor.png");
    pointerReady = false;
    target.style.removeProperty("--demo-cursor");
    liveArt.src = cursor;

    // Keep the browser cursor available throughout asset loading or if a file fails.
    liveArt.decode().then(() => {
      if (liveArt.src !== cursor || normal) return;
      // A 52 px export halves the app’s (32, 15) hotspot to (16, 8), rounded to pixels.
      const cssCursor = `url("${cursor}") 16 8, auto`;
      if (!CSS.supports("cursor", cssCursor)) return;
      target.style.setProperty("--demo-cursor", cssCursor);
      pointerReady = true;
    }).catch(() => {});
  };

  const updatePreview = () => {
    stopPointerAnimation();
    poster.getAnimations().forEach((animation) => animation.cancel());
    impact.getAnimations().forEach((animation) => animation.cancel());
    root.toggleAttribute("data-normal", normal);
    reset.setAttribute("aria-pressed", String(normal));
    target.setAttribute("aria-disabled", String(normal));
    if (normal) {
      pointerReady = false;
      target.style.removeProperty("--demo-cursor");
    } else {
      poster.src = artwork(".webp");
      updateCursor();
    }
  };

  /** @param {HTMLElement} element @param {number} x @param {number} y */
  const place = (element, x, y) => {
    element.style.transform = `translate(${x}px, ${y}px)`;
  };

  const playSample = () => {
    if (!clickSound.src) clickSound.src = new URL("assets/tap.wav", import.meta.url).href;
    clickSound.currentTime = 0;
    clickSound.play().catch(() => {
      sound.checked = false;
    });
  };

  controls.addEventListener("change", (event) => {
    const input = event.target;
    if (input === sound) {
      if (sound.checked) playSample();
      else clickSound.pause();
    } else if (input === palette || (input instanceof HTMLInputElement && input.name === "character")) {
      if (input instanceof HTMLInputElement) character = input.value;
      normal = false;
      clicks = [];
      updatePreview();
    }
  });

  reset.addEventListener("click", () => {
    normal = !normal;
    clicks = [];
    updatePreview();
  });
  target.addEventListener("pointerdown", (event) => {
    pointerType = event.pointerType;
    if (pointerType !== "mouse" && pointerType !== "pen") stopPointerAnimation();
  });
  target.addEventListener("pointermove", (event) => {
    if (!pointerAnimation) return;
    const bounds = target.getBoundingClientRect();
    place(livePointer, event.clientX - bounds.left, event.clientY - bounds.top);
  }, { passive: true });
  target.addEventListener("pointerleave", stopPointerAnimation);
  target.addEventListener("pointercancel", stopPointerAnimation);
  window.addEventListener("blur", stopPointerAnimation);
  window.addEventListener("scroll", stopPointerAnimation, { capture: true, passive: true });
  reducedMotion.addEventListener("change", () => {
    stopPointerAnimation();
    poster.getAnimations().forEach((animation) => animation.cancel());
    impact.getAnimations().forEach((animation) => animation.cancel());
  });

  target.addEventListener("click", (event) => {
    if (normal) return;
    const now = performance.now();
    clicks = clicks.filter((time) => now - time <= 650).slice(-5);
    clicks.push(now);
    const energy = energyLevels[Number(response.value)] * (1 + (clicks.length - 1) * .105);
    const reduced = reducedMotion.matches;
    const bounds = target.getBoundingClientRect();
    const x = event.detail ? event.clientX - bounds.left : bounds.width / 2;
    const y = event.detail ? event.clientY - bounds.top : bounds.height / 2;
    const showLive = !reduced && event.detail > 0 && finePointer.matches && pointerReady &&
      (pointerType === "mouse" || pointerType === "pen");
    const reactingArt = showLive ? liveArt : poster;
    const squash = character === "catPaw" ? .25 : character === "comicArrow" ? .12 : .2;

    stopPointerAnimation();
    poster.getAnimations().forEach((animation) => animation.cancel());
    impact.getAnimations().forEach((animation) => animation.cancel());
    place(impact, x, y);
    impact.classList.toggle("paw", !reduced && character === "catPaw");
    impact.animate(
      reduced
        ? [{ opacity: 0 }, { opacity: .85 }, { opacity: 0 }]
        : [{ opacity: 0, scale: ".55" }, { opacity: .9, scale: ".8", offset: .23 }, { opacity: 0, scale: String(1 + energy * .7) }],
      { duration: reduced ? 160 : 320, easing: "ease-out" }
    );

    if (!reduced) {
      const reaction = reactingArt.animate([
        { scale: "1", rotate: "0rad" },
        { scale: `${1 + energy * .17} ${1 - energy * squash}`, rotate: `${energy * .055}rad`, offset: .2 },
        { scale: `${1 - energy * .05} ${1 + energy * .13}`, rotate: `${-energy * .03}rad`, offset: .55 },
        { scale: "1", rotate: "0rad" }
      ], { duration: 245, easing: "ease-out" });

      if (showLive) {
        place(livePointer, x, y);
        pointerAnimation = reaction;
        target.classList.add("is-animating");
        reaction.onfinish = () => {
          if (pointerAnimation === reaction) stopPointerAnimation();
        };
      }
    }
    if (sound.checked) playSample();
  });

  const selected = controls.querySelector('input[name="character"]:checked');
  if (selected instanceof HTMLInputElement) character = selected.value;
  sound.checked = false;
  controls.hidden = target.hidden = hint.hidden = false;
  root.dataset.ready = "";
  updatePreview();
}
