// @ts-check

import { initialiseCursor } from "./cursor.js";
import { initialiseDownloads } from "./releases.js";
const menuToggle = document.querySelector(".menu-toggle");
const navigation = document.getElementById("primary-nav");

if (menuToggle instanceof HTMLButtonElement && navigation) {
  menuToggle.hidden = false;

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

initialiseCursor();
initialiseDownloads();
