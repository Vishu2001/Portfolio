import { impact } from "@/data/profile";
import CountUp from "./CountUp";
import Reveal from "./Reveal";
import Section from "./Section";
import SpotlightCard from "./SpotlightCard";

export default function Impact() {
  return (
    <Section id="impact" number="02" eyebrow="Impact" title="Numbers I'm proud of.">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {impact.map((item, i) => (
          <Reveal key={item.unit} delay={i * 100}>
            <SpotlightCard className="h-full rounded-3xl p-8 sm:p-10">
              <div className="flex flex-wrap items-baseline gap-3">
                {item.before && (
                  <>
                    <span className="text-2xl font-semibold text-muted line-through decoration-1">{item.before}</span>
                    <span className="text-muted">→</span>
                  </>
                )}
                <span className="text-gradient text-5xl font-bold tracking-tight sm:text-6xl">
                  <CountUp value={item.after} />
                </span>
              </div>
              <p className="mt-4 text-lg font-medium">{item.unit}</p>
              <p className="mt-1 text-sm text-muted">{item.note}</p>
            </SpotlightCard>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
