"use client";
// "use client" = this component runs in the browser, because it changes over time (state + timers).
// Components without it render once on the server and ship as plain HTML.

import { useEffect, useState } from "react";

export default function TypingRoles({ roles, className = "text-accent" }: { roles: string[]; className?: string }) {
  const [index, setIndex] = useState(0); // which role
  const [text, setText] = useState(roles[0]); // what's typed so far
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const full = roles[index];
    let delay = deleting ? 40 : 90;
    if (!deleting && text === full) delay = 1800; // pause on the full word

    const timer = setTimeout(() => {
      if (!deleting && text === full) {
        setDeleting(true);
      } else if (deleting && text === "") {
        setDeleting(false);
        setIndex((index + 1) % roles.length);
      } else {
        setText(deleting ? full.slice(0, text.length - 1) : full.slice(0, text.length + 1));
      }
    }, delay);
    return () => clearTimeout(timer); // cleanup, like closing a resource in Java
  }, [text, deleting, index, roles]);

  return (
    <span className={className}>
      {text}
      <span className="animate-blink ml-0.5 inline-block w-[2px] bg-current align-middle">&nbsp;</span>
    </span>
  );
}
