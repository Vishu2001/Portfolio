import Reveal from "./Reveal";

// Shared wrapper: same spacing, a numbered eyebrow ("01 / About") and a big heading.
type SectionProps = {
  id: string;
  number: string;
  eyebrow: string;
  title: string;
  children: React.ReactNode;
};

export default function Section({ id, number, eyebrow, title, children }: SectionProps) {
  return (
    <section id={id} className="relative mx-auto max-w-6xl px-4 py-20 sm:px-6 sm:py-28">
      <Reveal className="flex items-end justify-between gap-6 border-b border-border pb-6">
        <div>
          <p className="flex items-center gap-2 font-mono text-xs tracking-widest text-muted uppercase">
            <span className="text-accent">{number}</span>
            <span className="h-px w-6 bg-border" />
            {eyebrow}
          </p>
          <h2 className="mt-4 max-w-3xl text-3xl font-bold tracking-tight sm:text-5xl">{title}</h2>
        </div>
      </Reveal>
      <div className="mt-10 sm:mt-14">{children}</div>
    </section>
  );
}
