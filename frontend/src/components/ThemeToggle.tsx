"use client";

import { useLayoutEffect } from "react";

const KEY = "theme";

// Sun/moon switch. The theme lives on <html data-theme="...">, and the icons swap with
// pure CSS (`dark:` classes), so this component needs no React state at all.
export default function ThemeToggle() {
  // In development, React's Strict Mode remount resets <html> attributes; re-apply the
  // saved theme before paint. (A no-op in production, where the <head> script already did it.)
  useLayoutEffect(() => {
    try {
      const saved = localStorage.getItem(KEY);
      if (saved === "light" || saved === "dark") document.documentElement.setAttribute("data-theme", saved);
    } catch {}
  }, []);

  function toggle() {
    const next = document.documentElement.getAttribute("data-theme") === "light" ? "dark" : "light";
    document.documentElement.setAttribute("data-theme", next);
    try {
      localStorage.setItem(KEY, next);
    } catch {}
  }

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label="Switch between light and dark theme"
      title="Switch theme"
      className="grid h-9 w-9 place-items-center rounded-full text-muted transition-colors hover:bg-overlay/10 hover:text-foreground"
    >
      {/* Sun: shown in dark mode (click → light) */}
      <svg viewBox="0 0 24 24" className="hidden h-[18px] w-[18px] dark:block" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden>
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
      </svg>
      {/* Moon: shown in light mode (click → dark) */}
      <svg viewBox="0 0 24 24" className="block h-[18px] w-[18px] dark:hidden" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden>
        <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
      </svg>
    </button>
  );
}
