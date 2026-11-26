"use client";

import { useEffect, useState } from "react";

// Live clock in Vishal's time zone. It renders "--:--" on the server and fills in
// once the page is running in the browser, so server and browser HTML always match.
export default function LocalTime({ timeZone = "Asia/Kolkata" }: { timeZone?: string }) {
  const [time, setTime] = useState<string | null>(null);

  useEffect(() => {
    const fmt = new Intl.DateTimeFormat("en-IN", { timeZone, hour: "2-digit", minute: "2-digit", hour12: true });
    const update = () => setTime(fmt.format(new Date()));
    update();
    const id = setInterval(update, 30_000);
    return () => clearInterval(id);
  }, [timeZone]);

  return <span className="tabular-nums">{time ?? "--:--"}</span>;
}
