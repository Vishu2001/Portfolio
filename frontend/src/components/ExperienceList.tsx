"use client";

import { useState } from "react";
import { experience } from "@/data/profile";
import Reveal from "./Reveal";
import Section from "./Section";
import Tag from "./Tag";

// Tabs: pick a company on the left (or top, on phones), see the details on the right.
export default function ExperienceList() {
  const [selected, setSelected] = useState(0);
  const job = experience[selected];

  return (
    <Section id="experience" number="03" eyebrow="Experience" title="Where I've shipped code.">
      <Reveal className="grid grid-cols-1 gap-6 md:grid-cols-[240px_1fr] md:gap-10">
        <div role="tablist" aria-label="Companies" className="flex gap-2 overflow-x-auto md:flex-col md:overflow-visible">
          {experience.map((j, i) => (
            <button
              key={j.company}
              role="tab"
              aria-selected={i === selected}
              onClick={() => setSelected(i)}
              className={`shrink-0 rounded-2xl border px-4 py-3 text-left transition-all md:px-5 md:py-4 ${
                i === selected
                  ? "border-accent/50 bg-accent/10"
                  : "border-border bg-surface hover:border-overlay/20"
              }`}
            >
              <span className={`block font-semibold ${i === selected ? "text-accent" : ""}`}>{j.company}</span>
              <span className="block font-mono text-xs text-muted">{j.period}</span>
            </button>
          ))}
        </div>

        {/* key={selected} re-mounts this block on every switch, replaying the fade-in */}
        <div key={selected} role="tabpanel" className="animate-[fadeIn_0.4s_ease] rounded-3xl border border-border bg-surface p-6 sm:p-9">
          <p className="font-mono text-xs text-muted">{job.period}</p>
          <h3 className="mt-2 text-2xl font-bold tracking-tight sm:text-3xl">
            {job.role} <span className="text-gradient">@ {job.company}</span>
          </h3>
          <p className="mt-4 leading-7 text-muted">{job.summary}</p>
          <ul className="mt-6 space-y-3">
            {job.highlights.map((h) => (
              <li key={h} className="flex gap-3 leading-6">
                <span className="mt-2 h-1.5 w-1.5 shrink-0 rounded-full bg-accent" />
                {h}
              </li>
            ))}
          </ul>
          <div className="mt-7 flex flex-wrap gap-2">
            {job.tech.map((t) => (
              <Tag key={t}>{t}</Tag>
            ))}
          </div>
        </div>
      </Reveal>
    </Section>
  );
}
