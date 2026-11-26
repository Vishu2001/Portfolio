import Image from "next/image";
import { profile, techStack } from "@/data/profile";
import TypingRoles from "./TypingRoles";
import LocalTime from "./LocalTime";
import CountUp from "./CountUp";
import SpotlightCard from "./SpotlightCard";

// The photo is a transparent cut-out (studio background removed), so it sits straight on
// the dark page. Only the bottom edge (where the desk was cut off) needs a fade.
const PHOTO_FADE = "linear-gradient(to bottom, black 80%, transparent 100%)";
// A thin neutral rim light, so the black suit's outline stays crisp on the black page.
// (Kept tight on purpose: a wide glow would get clipped by the fade mask at the image's edges.)
const RIM_LIGHT = "drop-shadow(0 0 1.5px rgb(255 255 255 / 0.3))";

export default function Hero() {
  return (
    <>
      {/* ================= Photo hero =================
          Rule: the photo sits to the right, the text sits on the empty left half,
          so no headline ever covers the face. */}
      <section id="top" className="relative overflow-hidden">

        <div className="relative z-10 mx-auto max-w-6xl px-4 pt-32 pb-6 sm:px-6 lg:flex lg:min-h-[min(100svh,920px)] lg:items-start lg:pt-[18vh] lg:pb-0">
          <div className="lg:max-w-[520px]">
            <p className="inline-flex items-center gap-2 rounded-full border border-border bg-surface/70 px-3 py-1 text-xs font-medium text-muted backdrop-blur">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-accent opacity-75" />
                <span className="relative inline-flex h-2 w-2 rounded-full bg-accent" />
              </span>
              {profile.available}
            </p>

            <h1 className="mt-6 text-5xl leading-[1.02] font-bold tracking-tight sm:text-7xl">
              Vishal
              <br />
              <span className="text-gradient">Kumar Singh</span>
            </h1>
            <p className="mt-5 h-8 text-xl font-semibold sm:text-2xl">
              <TypingRoles roles={profile.roles} className="text-foreground" />
            </p>
            <p className="mt-4 max-w-md leading-7 text-muted">{profile.intro}</p>

            <div className="mt-8 flex flex-wrap items-center gap-3">
              <a
                href="#projects"
                className="rounded-full bg-foreground px-6 py-3 text-sm font-semibold text-background transition-transform hover:-translate-y-0.5"
              >
                See my work
              </a>
              <a
                href="#contact"
                className="rounded-full border border-border bg-surface/50 px-6 py-3 text-sm font-semibold backdrop-blur transition-colors hover:border-accent hover:text-accent"
              >
                Get in touch
              </a>
              <div className="flex gap-2">
                <IconLink href={profile.links.github} label="GitHub">
                  <path
                    fill="currentColor"
                    d="M12 2a10 10 0 0 0-3.16 19.49c.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.45-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.9 1.52 2.34 1.08 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.65 0 0 .84-.27 2.75 1.02a9.58 9.58 0 0 1 5 0c1.91-1.29 2.75-1.02 2.75-1.02.55 1.38.2 2.4.1 2.65.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85v2.74c0 .27.18.58.69.48A10 10 0 0 0 12 2Z"
                  />
                </IconLink>
                <IconLink href={profile.links.linkedin} label="LinkedIn">
                  <path
                    fill="currentColor"
                    d="M6.94 8.5H3.56V20h3.38V8.5ZM5.25 3A1.97 1.97 0 1 0 5.25 7a1.97 1.97 0 0 0 0-3.94ZM20.44 13.4c0-3.1-1.66-4.54-3.87-4.54a3.34 3.34 0 0 0-3.03 1.67V8.5h-3.37V20h3.37v-6.06c0-1.6.3-3.15 2.29-3.15 1.96 0 1.99 1.83 1.99 3.25V20h3.38v-6.6Z"
                  />
                </IconLink>
              </div>
            </div>
          </div>
        </div>

        {/* Desktop: wide cut-out anchored bottom-right */}
        <Image
          src="/images/vishal-cutout.png"
          alt="Vishal Kumar Singh in a black suit, working on a laptop"
          width={1672}
          height={732}
          priority
          sizes="(min-width: 1024px) 92vw, 100vw"
          className="pointer-events-none absolute right-0 bottom-0 hidden h-auto w-[92%] max-w-[1600px] select-none lg:block"
          style={{ maskImage: PHOTO_FADE, WebkitMaskImage: PHOTO_FADE, filter: RIM_LIGHT }}
        />

        {/* Phones/tablets: photo below the text, cropped around the face */}
        <div className="relative h-[340px] sm:h-[460px] lg:hidden">
          <Image
            src="/images/vishal-cutout.png"
            alt=""
            fill
            sizes="100vw"
            className="object-cover object-[80%_center]"
            style={{ maskImage: PHOTO_FADE, WebkitMaskImage: PHOTO_FADE, filter: RIM_LIGHT }}
          />
        </div>
      </section>

      {/* ================= Quick-facts bento strip ================= */}
      <section aria-label="Quick facts" className="relative mx-auto max-w-6xl px-4 pt-10 sm:px-6">
        <div className="grid grid-cols-2 gap-3 sm:gap-4 lg:grid-cols-4">
          <SpotlightCard className="flex flex-col justify-between gap-6 rounded-3xl p-5 sm:p-6">
            <span className="inline-flex w-fit items-center gap-2 rounded-full bg-accent/10 px-3 py-1 text-xs font-medium text-accent">
              <span className="h-2 w-2 rounded-full bg-accent" />
              Local time
            </span>
            <div>
              <p className="text-2xl font-bold sm:text-3xl">
                <LocalTime />
              </p>
              <p className="mt-1 text-xs text-muted">in {profile.location} (IST)</p>
            </div>
          </SpotlightCard>

          <SpotlightCard className="flex flex-col justify-between gap-6 rounded-3xl p-5 sm:p-6">
            <p className="font-mono text-xs text-muted">report export</p>
            <div>
              <p className="text-gradient text-4xl font-bold tracking-tight sm:text-5xl">
                <CountUp value="90%" />
              </p>
              <p className="mt-1 text-xs text-muted">faster · 31 min → 4.8 min</p>
            </div>
          </SpotlightCard>

          <div className="col-span-2 overflow-hidden rounded-3xl border border-border bg-surface/80 py-6 backdrop-blur">
            <p className="px-6 font-mono text-xs text-muted">stack I work with</p>
            <div
              className="mt-4 overflow-hidden"
              style={{
                maskImage: "linear-gradient(to right, transparent, black 8%, black 92%, transparent)",
                WebkitMaskImage: "linear-gradient(to right, transparent, black 8%, black 92%, transparent)",
              }}
            >
              <ul className="animate-marquee flex w-max gap-3">
                {[...techStack, ...techStack].map((t, i) => (
                  <li
                    key={i}
                    aria-hidden={i >= techStack.length}
                    className="rounded-full border border-border bg-surface-2 px-4 py-2 font-mono text-xs whitespace-nowrap text-muted"
                  >
                    {t}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

function IconLink({ href, label, children }: { href: string; label: string; children: React.ReactNode }) {
  return (
    <a
      href={href}
      aria-label={label}
      target="_blank"
      rel="noopener noreferrer"
      className="grid h-11 w-11 place-items-center rounded-full border border-border bg-surface/50 text-muted backdrop-blur transition-all hover:-translate-y-0.5 hover:border-accent hover:text-accent"
    >
      <svg viewBox="0 0 24 24" className="h-5 w-5" aria-hidden>
        {children}
      </svg>
    </a>
  );
}
