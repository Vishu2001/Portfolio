import { about } from "@/data/profile";
import Reveal from "./Reveal";
import Section from "./Section";

export default function About() {
  return (
    <Section id="about" number="01" eyebrow="About" title="I like slow systems. Mostly because I get to make them fast.">
      <div className="grid grid-cols-1 gap-12 lg:grid-cols-[1.2fr_1fr]">
        <Reveal className="space-y-5 text-lg leading-8 text-muted">
          {about.paragraphs.map((p) => (
            <p key={p}>{p}</p>
          ))}
        </Reveal>

        {/* A playful "code card", since a backend dev's About should look a bit like code */}
        <Reveal delay={150}>
          {/* Stays dark on purpose, like a real code editor */}
          <div className="overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950 text-zinc-100 shadow-2xl shadow-zinc-900/25">
            <div className="flex items-center gap-2 border-b border-zinc-800 px-4 py-3">
              <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
              <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
              <span className="h-3 w-3 rounded-full bg-[#28c840]" />
              <span className="ml-3 font-mono text-xs text-zinc-400">Vishal.java</span>
            </div>
            <pre className="overflow-x-auto p-5 font-mono text-[13px] leading-7">
              <code>
                <span className="text-violet-300">public record</span> <span className="text-emerald-300">Vishal</span>(
                {"\n"}
                {about.facts.map((f, i) => (
                  <span key={f.label}>
                    {"    "}
                    <span className="text-zinc-500">String</span> {camel(f.label)}
                    <span className="text-zinc-500"> = </span>
                    <span className="text-[#fbbf24]">&quot;{f.value}&quot;</span>
                    {i < about.facts.length - 1 ? "," : ""}
                    {"\n"}
                  </span>
                ))}
                ) {"{}"}
              </code>
            </pre>
          </div>
        </Reveal>
      </div>
    </Section>
  );
}

// "Based in" -> "basedIn"
function camel(label: string) {
  return label
    .toLowerCase()
    .replace(/[^a-z ]/g, "")
    .replace(/ (\w)/g, (_, c: string) => c.toUpperCase());
}
