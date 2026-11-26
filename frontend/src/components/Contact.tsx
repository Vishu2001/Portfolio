import { profile } from "@/data/profile";
import Reveal from "./Reveal";
import ContactForm from "./ContactForm";

// The form POSTs to the Spring Boot API (backend/ → POST /api/contact).
export default function Contact() {
  return (
    <section id="contact" className="relative mx-auto max-w-6xl px-4 pt-20 sm:px-6 sm:pt-28">
      <Reveal>
        {/* Gradient border: a 1px gradient "frame" around a dark card */}
        <div className="rounded-[2rem] bg-gradient-to-br from-overlay/25 via-overlay/5 to-overlay/20 p-px">
          <div className="relative overflow-hidden rounded-[calc(2rem-1px)] bg-surface px-6 py-16 text-center sm:px-12 sm:py-24">
            <div aria-hidden className="bg-grid absolute inset-0 opacity-30 [mask-image:radial-gradient(ellipse_at_center,black,transparent_70%)]" />
            <div className="relative">
              <p className="font-mono text-xs tracking-widest text-accent uppercase">06 · Contact</p>
              <h2 className="mt-5 text-4xl font-bold tracking-tight sm:text-6xl">
                Got a backend that&apos;s <br className="hidden sm:block" />
                <span className="text-gradient">too slow?</span>
              </h2>
              <p className="mx-auto mt-6 max-w-xl text-lg leading-8 text-muted">
                I&apos;m open to backend engineering roles, especially in fintech. Or just say hi and talk
                Spring Boot, databases or DSA.
              </p>
              <ContactForm />
              <p className="mt-8 text-sm text-muted">
                Prefer email?{" "}
                <a href={`mailto:${profile.email}`} className="font-medium text-foreground underline-offset-4 hover:underline">
                  {profile.email}
                </a>{" "}
                ·{" "}
                <a
                  href={profile.links.linkedin}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="font-medium text-foreground underline-offset-4 hover:underline"
                >
                  LinkedIn ↗
                </a>
              </p>
            </div>
          </div>
        </div>
      </Reveal>
    </section>
  );
}
