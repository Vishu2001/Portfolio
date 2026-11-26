"use client";

import { useState } from "react";

// Where the Spring Boot API lives. Locally: http://localhost:8080.
// In production, set NEXT_PUBLIC_API_URL (e.g. https://api.vishal.dev) at build time.
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

type FieldErrors = Partial<Record<"name" | "email" | "message", string>>;
type Status = "idle" | "sending" | "sent" | "error";

export default function ContactForm() {
  const [status, setStatus] = useState<Status>("idle");
  const [errors, setErrors] = useState<FieldErrors>({});
  const [errorText, setErrorText] = useState("");

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = e.currentTarget;
    const data = Object.fromEntries(new FormData(form)); // { name, email, message, website }

    setStatus("sending");
    setErrors({});
    setErrorText("");

    try {
      const res = await fetch(`${API_URL}/api/contact`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (res.status === 202) {
        setStatus("sent");
        form.reset();
        return;
      }
      // 400 → the API's ProblemDetail JSON, with an "errors" map per field
      const problem = await res.json().catch(() => null);
      setErrors(problem?.errors ?? {});
      setErrorText(problem?.detail ?? "Something went wrong. Please try again.");
      setStatus("error");
    } catch {
      setErrorText("Couldn't reach the server. Please try again in a moment, or email me directly.");
      setStatus("error");
    }
  }

  if (status === "sent") {
    return (
      <div role="status" className="mx-auto mt-10 max-w-md rounded-2xl border border-accent/40 bg-accent/10 px-6 py-8">
        <p className="text-lg font-semibold text-accent">Message sent ✓</p>
        <p className="mt-2 text-sm text-muted">Thanks for reaching out. I&apos;ll get back to you soon.</p>
        <button
          type="button"
          onClick={() => setStatus("idle")}
          className="mt-5 text-sm font-medium underline-offset-4 hover:underline"
        >
          Send another
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} noValidate className="mx-auto mt-10 grid max-w-xl gap-4 text-left">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="Name" name="name" autoComplete="name" error={errors.name} />
        <Field label="Email" name="email" type="email" autoComplete="email" error={errors.email} />
      </div>
      <Field label="Message" name="message" textarea error={errors.message} />

      {/* Honeypot: hidden from people (and screen readers), but bots fill it in */}
      <div aria-hidden className="absolute -left-[9999px] h-0 w-0 overflow-hidden">
        <label>
          Website
          <input type="text" name="website" tabIndex={-1} autoComplete="off" />
        </label>
      </div>

      {status === "error" && errorText && (
        <p role="alert" className="text-sm text-red-500 dark:text-red-400">
          {errorText}
        </p>
      )}

      <button
        type="submit"
        disabled={status === "sending"}
        className="mt-2 rounded-full bg-foreground px-8 py-4 font-semibold text-background transition-all hover:-translate-y-0.5 disabled:translate-y-0 disabled:opacity-60"
      >
        {status === "sending" ? "Sending…" : "Send message →"}
      </button>
    </form>
  );
}

function Field({
  label,
  name,
  type = "text",
  autoComplete,
  textarea,
  error,
}: {
  label: string;
  name: string;
  type?: string;
  autoComplete?: string;
  textarea?: boolean;
  error?: string;
}) {
  const base =
    "w-full rounded-xl border bg-surface-2 px-4 py-3 text-sm outline-none transition-colors placeholder:text-muted/70 focus:border-accent";
  const border = error ? "border-red-500/70" : "border-border";
  const id = `contact-${name}`;
  return (
    <div>
      <label htmlFor={id} className="mb-1.5 block text-xs font-medium text-muted">
        {label}
      </label>
      {textarea ? (
        <textarea id={id} name={name} rows={5} className={`${base} ${border} resize-y`} aria-invalid={!!error} />
      ) : (
        <input id={id} name={name} type={type} autoComplete={autoComplete} className={`${base} ${border}`} aria-invalid={!!error} />
      )}
      {error && <p className="mt-1.5 text-xs text-red-500 dark:text-red-400">{error}</p>}
    </div>
  );
}
