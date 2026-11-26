"use client";

import { useEffect, useState } from "react";
import ThemeToggle from "./ThemeToggle";

const links = [
  { id: "about", label: "About" },
  { id: "experience", label: "Work" },
  { id: "projects", label: "Projects" },
  { id: "journey", label: "Journey" },
];

// A floating "glass" pill. It always has its own dark background, so the links
// stay readable over any section, and it highlights the section you're reading.
export default function Navbar() {
  const [active, setActive] = useState("");

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        for (const e of entries) if (e.isIntersecting) setActive(e.target.id);
      },
      { rootMargin: "-45% 0px -50% 0px" }, // "active" = the section crossing the middle of the screen
    );
    for (const { id } of [...links, { id: "top" }, { id: "impact" }, { id: "contact" }]) {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    }
    return () => observer.disconnect();
  }, []);

  return (
    <header className="fixed inset-x-0 top-4 z-40 flex justify-center px-3">
      <nav className="flex items-center gap-1 rounded-full border border-overlay/10 bg-surface/70 p-1.5 shadow-2xl shadow-black/10 backdrop-blur-xl dark:shadow-black/50">
        <a
          href="#top"
          aria-label="Back to top"
          className="grid h-9 w-9 place-items-center rounded-full bg-foreground font-mono text-xs font-bold text-background"
        >
          VS
        </a>
        <ul className="flex items-center">
          {links.map((link) => (
            <li key={link.id} className={link.id === "journey" ? "hidden sm:block" : ""}>
              <a
                href={`#${link.id}`}
                className={`block rounded-full px-2.5 py-2 text-sm transition-colors sm:px-4 ${
                  active === link.id ? "bg-overlay/10 text-foreground" : "text-muted hover:text-foreground"
                }`}
              >
                {link.label}
              </a>
            </li>
          ))}
        </ul>
        <ThemeToggle />
        <a
          href="#contact"
          className="shrink-0 rounded-full bg-accent px-3.5 py-2 text-sm font-semibold whitespace-nowrap text-background transition-transform hover:scale-105 sm:px-4"
        >
          <span className="hidden sm:inline">Let&apos;s talk</span>
          <span className="sm:hidden">Hi 👋</span>
        </a>
      </nav>
    </header>
  );
}
