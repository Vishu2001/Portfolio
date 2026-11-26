// All portfolio content lives here, separate from the UI components.
// To update the site (new job, new project), edit this file only.

export const profile = {
  firstName: "Vishal",
  name: "Vishal Kumar Singh",
  roles: ["Backend Engineer", "Spring Boot Developer", "Fintech Systems Builder", "DevOps Learner"],
  intro:
    "I make backends faster and safer: the kind of systems that move money and can't afford to be slow or wrong.",
  location: "Noida, India",
  available: "Open to backend roles",
  email: "vishalsingh.cse.18@gmail.com",
  links: {
    github: "https://github.com/vishu-0123",
    linkedin: "https://linkedin.com/in/vishal-kumar-singh",
  },
};

export const about = {
  paragraphs: [
    "I'm a backend engineer from Noida with 1.5+ years of building Java and Spring Boot systems. Most of my work sits close to money: virtual account balances, bank integrations and transaction reports for enterprise clients.",
    "What I enjoy most is the detective work: finding why a report takes 31 minutes, why balances drift under load, or why one API fires 5,700 queries. Then fixing it properly.",
    "Right now I'm learning in public: taking this portfolio from a laptop to the cloud with Docker, Redis, Kafka, CI/CD, AWS and Kubernetes.",
  ],
  facts: [
    { label: "Based in", value: "Noida, India" },
    { label: "Education", value: "B.Tech CSE, IIIT Agartala · 8.61" },
    { label: "Focus", value: "Performance, concurrency, fintech" },
    { label: "Off-screen", value: "Competitive programming, mentoring" },
  ],
};

export const techStack = [
  "Java 17", "Spring Boot 3", "Spring Security", "Spring Cloud", "Hibernate", "MySQL",
  "PostgreSQL", "MongoDB", "Microservices", "REST", "JUnit", "Mockito", "Maven",
  "Git", "Linux", "AWS", "Docker", "Redis", "Kafka", "Next.js", "TypeScript",
];

export const impact = [
  { before: "5,700", after: "10", unit: "queries / report", note: "Killed Hibernate N+1 with bulk FK preloading" },
  { before: "31 min", after: "4.8 min", unit: "report export", note: "Chunking, OOM fix, cached lazy associations" },
  { before: "", after: "+35%", unit: "throughput", note: "MySQL advisory locks across 3 instances" },
  { before: "", after: "95%", unit: "test coverage", note: "JUnit + Mockito on core services" },
];

export type Job = {
  company: string;
  role: string;
  period: string;
  summary: string;
  highlights: string[];
  tech: string[];
};

export const experience: Job[] = [
  {
    company: "OmniCard",
    role: "Software Developer",
    period: "Jan 2026 — Now",
    summary:
      "Fintech platform serving enterprise clients. I work on reporting performance, concurrency in virtual account balance updates and bank integrations.",
    highlights: [
      "Moved 3 MIS reporting APIs from a Java 8 monolith to a Spring Boot 3 microservice, 3.2–5.8× faster (47s → 14.5s)",
      "Prevented lost balance updates across 3 app instances with pessimistic locking",
      "Built the Charis Bank integration used by PUMA, Bluestone and CityKart",
    ],
    tech: ["Java 17", "Spring Boot 3", "Hibernate", "MySQL"],
  },
  {
    company: "Vijay Software Solution",
    role: "Software Developer",
    period: "Jul — Oct 2025",
    summary:
      "Built an HRMS backend from scratch: onboarding, attendance and leave management.",
    highlights: [
      "25+ REST APIs with role-based access for Admin, HR and Employee",
      "State-machine leave approvals that cut manual HR coordination by 40%",
      "Attendance reports under 500ms with indexed joins and pagination",
    ],
    tech: ["Spring Boot", "Spring Security", "JPA", "MySQL"],
  },
  {
    company: "EPAM Systems",
    role: "Software Developer Intern",
    period: "Jan — Jun 2025",
    summary: "Quiz platform APIs: categories, quizzes and questions.",
    highlights: [
      "35% faster API responses through optimized JPA queries",
      "Soft delete, pagination, validation, and 95% test coverage",
    ],
    tech: ["Spring Boot", "Spring Data JPA", "JUnit"],
  },
];

export type Project = {
  name: string;
  tagline: string;
  status: string;
  problem: string;
  approach: string;
  flow: string[];
  tech: string[];
  link?: string;
};

export const projects: Project[] = [
  {
    name: "This Portfolio, Production-Grade",
    tagline: "A personal site built like a real product",
    status: "Building now",
    problem:
      "Most portfolios are static pages. I wanted one that exercises the same stack a fintech backend team runs in production.",
    approach:
      "Next.js frontend and a Spring Boot API, with Redis rate limiting on the contact form, Kafka for async email, Docker images built by GitHub Actions and deployed to AWS ECS.",
    flow: ["Next.js", "Spring Boot", "Redis · Kafka", "Docker", "AWS ECS"],
    tech: ["Next.js", "TypeScript", "Spring Boot", "Redis", "Kafka", "Docker", "AWS"],
  },
  {
    name: "Enterprise Resource Microservices",
    tagline: "Service discovery done right",
    status: "2025",
    problem:
      "A monolithic resource-management design couldn't scale its modules independently.",
    approach:
      "Split it into Spring Boot services that find each other through Eureka and talk through Feign clients, cutting inter-service latency by 20%. Designed to move to DynamoDB.",
    flow: ["API Gateway", "Eureka", "Services", "Feign", "DynamoDB*"],
    tech: ["Spring Boot", "Spring Cloud", "Eureka", "Feign"],
  },
];

export type RoadmapStatus = "done" | "now" | "next";

export const roadmap: { step: string; detail: string; status: RoadmapStatus }[] = [
  { step: "Next.js frontend", detail: "React, TypeScript, Tailwind", status: "done" },
  { step: "Spring Boot API", detail: "Contact endpoint, validation", status: "now" },
  { step: "Docker", detail: "Images + docker-compose", status: "next" },
  { step: "Redis", detail: "Rate limiting, caching", status: "next" },
  { step: "Kafka", detail: "Async email consumer", status: "next" },
  { step: "CI/CD", detail: "GitHub Actions → ECR", status: "next" },
  { step: "AWS ECS", detail: "Fargate deployment", status: "next" },
  { step: "Kubernetes", detail: "Manifests on minikube", status: "next" },
];

export const achievements = [
  { title: "LeetCode Knight", detail: "Max 1978 · top 3.11% · 300+ problems" },
  { title: "Codeforces & CodeChef", detail: "Pupil (1257) · 3★ (1609)" },
  { title: "Xiaomi Ode2Code 3.0", detail: "Top 1.6% nationally" },
  { title: "Google Kick Start", detail: "Rank 1842 of 10,000+ (Round H 2022)" },
  { title: "GDSC Web Dev Lead", detail: "Mentored 100+ juniors at IIIT Agartala" },
];
