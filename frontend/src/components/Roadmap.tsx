import { roadmap, achievements, type RoadmapStatus } from "@/data/profile";
import Reveal from "./Reveal";
import Section from "./Section";

const badge: Record<RoadmapStatus, { label: string; className: string }> = {
  done: { label: "Done", className: "border-accent/50 bg-accent/10 text-accent" },
  now: { label: "In progress", className: "border-amber-500/50 bg-amber-400/10 text-amber-700 dark:text-amber-300" },
  next: { label: "Up next", className: "border-border text-muted" },
};

export default function Roadmap() {
  const done = roadmap.filter((r) => r.status === "done").length;
  const percent = Math.round((done / roadmap.length) * 100);

  return (
    <Section id="journey" number="05" eyebrow="Learning in public" title="From localhost to the cloud.">
      <Reveal>
        <p className="max-w-2xl text-lg leading-8 text-muted">
          I&apos;m building this site step by step to learn DevOps the hands-on way. This board updates
          as each piece goes live.
        </p>
        <div className="mt-8 flex items-center gap-4">
          <div className="h-2 flex-1 overflow-hidden rounded-full bg-surface">
            <div className="h-full rounded-full bg-accent" style={{ width: `${percent}%` }} />
          </div>
          <span className="font-mono text-sm text-accent">{percent}%</span>
        </div>
      </Reveal>

      <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {roadmap.map((item, i) => (
          <Reveal key={item.step} delay={i * 60}>
            <div
              className={`h-full rounded-2xl border bg-surface p-5 ${
                item.status === "now" ? "border-amber-400/40" : "border-border"
              }`}
            >
              <div className="flex items-center justify-between">
                <span className="font-mono text-xs text-muted">{String(i + 1).padStart(2, "0")}</span>
                <span className={`rounded-full border px-2 py-0.5 text-[11px] ${badge[item.status].className}`}>
                  {badge[item.status].label}
                </span>
              </div>
              <p className="mt-4 font-semibold">{item.step}</p>
              <p className="mt-1 text-sm text-muted">{item.detail}</p>
            </div>
          </Reveal>
        ))}
      </div>

      <Reveal className="mt-20">
        <p className="font-mono text-xs tracking-widest text-muted uppercase">Beyond work</p>
        <ul className="mt-6 flex flex-wrap gap-3">
          {achievements.map((a) => (
            <li key={a.title} className="rounded-2xl border border-border px-5 py-4 transition-colors hover:border-accent/50">
              <p className="font-semibold">{a.title}</p>
              <p className="text-sm text-muted">{a.detail}</p>
            </li>
          ))}
        </ul>
      </Reveal>
    </Section>
  );
}
