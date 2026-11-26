"use client";

import { useEffect, useRef, useState } from "react";

// Animates the number inside a string when it scrolls into view:
// "5,700" counts 0 → 5,700, "4.8 min" counts 0.0 → 4.8, "+35%" counts +0% → +35%.
export default function CountUp({ value, duration = 1400 }: { value: string; duration?: number }) {
  const match = value.match(/[\d,]*\.?\d+/);
  const ref = useRef<HTMLSpanElement>(null);
  const [display, setDisplay] = useState(value);

  useEffect(() => {
    if (!match || window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const raw = match[0];
    const target = parseFloat(raw.replace(/,/g, ""));
    const decimals = raw.includes(".") ? raw.split(".")[1].length : 0;
    const useCommas = raw.includes(",");
    const [prefix, suffix] = [value.slice(0, match.index), value.slice((match.index ?? 0) + raw.length)];
    const format = (n: number) => {
      const s = n.toFixed(decimals);
      return prefix + (useCommas ? Number(s).toLocaleString("en-US") : s) + suffix;
    };

    const el = ref.current;
    if (!el) return;
    let frame = 0;
    const observer = new IntersectionObserver(([entry]) => {
      if (!entry.isIntersecting) return;
      observer.disconnect();
      const start = performance.now();
      const tick = (now: number) => {
        // clamp to 0..1 (the first frame's timestamp can be slightly before `start`, giving "-0")
        const t = Math.max(0, Math.min((now - start) / duration, 1));
        const eased = 1 - Math.pow(1 - t, 3); // fast start, slow finish
        setDisplay(format(target * eased));
        if (t < 1) frame = requestAnimationFrame(tick);
      };
      setDisplay(format(0));
      frame = requestAnimationFrame(tick);
    });
    observer.observe(el);
    return () => {
      observer.disconnect();
      cancelAnimationFrame(frame);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [value, duration]);

  return (
    <span ref={ref} className="tabular-nums">
      {display}
    </span>
  );
}
