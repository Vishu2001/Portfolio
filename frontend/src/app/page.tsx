import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import About from "@/components/About";
import Impact from "@/components/Impact";
import ExperienceList from "@/components/ExperienceList";
import Projects from "@/components/Projects";
import Roadmap from "@/components/Roadmap";
import Contact from "@/components/Contact";
import { profile } from "@/data/profile";

// The home page ("/") just puts the sections together, in order.
export default function Home() {
  return (
    <div className="page-bg relative overflow-x-clip bg-background">

      <Navbar />
      <main>
        <Hero />
        <About />
        <Impact />
        <ExperienceList />
        <Projects />
        <Roadmap />
        <Contact />
      </main>

      <footer className="mx-auto max-w-6xl px-4 pt-20 pb-8 sm:px-6">
        {/* Giant name that fills the width */}
        <p
          aria-hidden
          className="text-gradient text-center text-[17vw] leading-none font-black tracking-tighter opacity-90 select-none lg:text-[11.5rem]"
        >
          VISHAL
        </p>
        <div className="mt-8 flex flex-col items-center justify-between gap-3 border-t border-border pt-6 font-mono text-xs text-muted sm:flex-row">
          <span>© 2026 {profile.name}</span>
          <span>Built with Next.js · Spring Boot · lots of coffee</span>
        </div>
      </footer>
    </div>
  );
}
