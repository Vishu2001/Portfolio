import { projects } from "@/data/profile";
import Reveal from "./Reveal";
import Section from "./Section";
import Tag from "./Tag";
import SpotlightCard from "./SpotlightCard";

export default function Projects() {
  return (
    <Section id="projects" number="04" eyebrow="Projects" title="Things I've built.">
      <div className="grid gap-8">
        {projects.map((project, i) => (
          <Reveal key={project.name} delay={i * 100}>
            <SpotlightCard className="group overflow-hidden rounded-3xl">
              {/* Visual header: an architecture "flow" instead of a screenshot */}
              <div
                className="relative flex min-h-48 items-center justify-center overflow-hidden border-b border-border p-8"
                style={{
                  background:
                    i % 2 === 0
                      ? "radial-gradient(ellipse at top left, color-mix(in srgb, var(--overlay) 6%, transparent), transparent 60%)"
                      : "radial-gradient(ellipse at top right, color-mix(in srgb, var(--overlay) 6%, transparent), transparent 60%)",
                }}
              >
                <div className="bg-grid absolute inset-0 opacity-60" aria-hidden />
                <ol className="relative flex flex-wrap items-center justify-center gap-2 font-mono text-xs sm:text-sm">
                  {project.flow.map((node, n) => (
                    <li key={node} className="flex items-center gap-2">
                      <span className="rounded-lg border border-border bg-background/80 px-3 py-2 backdrop-blur transition-transform group-hover:-translate-y-0.5">
                        {node}
                      </span>
                      {n < project.flow.length - 1 && <span className="text-accent">→</span>}
                    </li>
                  ))}
                </ol>
              </div>

              <div className="grid grid-cols-1 gap-8 p-6 sm:p-10 lg:grid-cols-[1fr_1.4fr]">
                <div>
                  <span className="rounded-full border border-accent/40 px-3 py-1 font-mono text-xs text-accent">
                    {project.status}
                  </span>
                  <h3 className="mt-4 text-2xl font-bold tracking-tight sm:text-3xl">{project.name}</h3>
                  <p className="mt-2 text-muted">{project.tagline}</p>
                </div>
                <div className="space-y-5 text-sm leading-7">
                  <div>
                    <p className="font-mono text-xs tracking-widest text-muted uppercase">The problem</p>
                    <p className="mt-1">{project.problem}</p>
                  </div>
                  <div>
                    <p className="font-mono text-xs tracking-widest text-muted uppercase">What I did</p>
                    <p className="mt-1">{project.approach}</p>
                  </div>
                  <div className="flex flex-wrap gap-2 pt-1">
                    {project.tech.map((t) => (
                      <Tag key={t}>{t}</Tag>
                    ))}
                  </div>
                </div>
              </div>
            </SpotlightCard>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
