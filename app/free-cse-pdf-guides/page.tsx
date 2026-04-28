import type { Metadata } from "next";
import Link from "next/link";
import { headingFont } from "../../lib/fonts";

type PdfGuide = {
  title: string;
  description: string;
  category: string;
  href: string;
  featured?: boolean;
};

const pdfGuides: PdfGuide[] = [
  {
    title: "CSE Cheat Sheet Bundle 1-20",
    description: "Download the full first bundle of Exhale Academy CSE PDF guides in one file.",
    category: "Bundle Download",
    href: "/pdf-guides/cse/exhale_academy_cse_cheat_sheet_bundle_01_20.pdf",
    featured: true,
  },
  {
    title: "CSE Cheat Sheet Bundle 21-35",
    description: "Download the second bundle of Exhale Academy CSE PDF guides in one file.",
    category: "Bundle Download",
    href: "/pdf-guides/cse/exhale_academy_cse_cheat_sheet_bundle_21_35.pdf",
    featured: true,
  },
  {
    title: "CSE Structure",
    description: "Understand how the clinical simulation exam is organized before you start practicing.",
    category: "CSE Strategy",
    href: "/pdf-guides/cse/01_cse_structure.pdf",
  },
  {
    title: "Information Gathering",
    description: "Review what to collect, what to avoid, and how to think through CSE data gathering.",
    category: "CSE Strategy",
    href: "/pdf-guides/cse/02_information_gathering.pdf",
  },
  {
    title: "Decision Making",
    description: "Practice the mindset behind choosing safe, timely, board-style clinical decisions.",
    category: "CSE Strategy",
    href: "/pdf-guides/cse/03_decision_making.pdf",
  },
  {
    title: "Emergency Algorithm",
    description: "A fast review of urgent CSE patterns, escalation timing, and safety-first priorities.",
    category: "CSE Strategy",
    href: "/pdf-guides/cse/04_emergency_algorithm.pdf",
  },
  {
    title: "Scoring Rules",
    description: "Review how CSE scoring logic rewards appropriate choices and penalizes unsafe decisions.",
    category: "CSE Strategy",
    href: "/pdf-guides/cse/05_scoring_rules.pdf",
  },
  {
    title: "COPD Conservative Management",
    description: "Recognize stable COPD clues and conservative management decisions.",
    category: "Disease Recognition",
    href: "/pdf-guides/cse/06_copd_conservative.pdf",
  },
  {
    title: "Emphysema vs Chronic Bronchitis",
    description: "Separate the two classic COPD patterns quickly for exam-style questions.",
    category: "Disease Recognition",
    href: "/pdf-guides/cse/07_emphysema_vs_bronchitis.pdf",
  },
  {
    title: "Asthma",
    description: "Review reversible bronchoconstriction, triggers, diagnostics, and intervention clues.",
    category: "Disease Recognition",
    href: "/pdf-guides/cse/08_asthma.pdf",
  },
  {
    title: "COPD Critical Care",
    description: "Review severe COPD, ventilatory failure, BiPAP decisions, and escalation clues.",
    category: "Disease Recognition",
    href: "/pdf-guides/cse/09_copd_critical.pdf",
  },
  {
    title: "BiPAP vs Intubation",
    description: "Learn when noninvasive support fits and when the safer answer is intubation.",
    category: "Ventilation Decisions",
    href: "/pdf-guides/cse/10_bipap_vs_intubation.pdf",
  },
  {
    title: "Pneumothorax vs Hemothorax",
    description: "Compare two high-yield chest trauma patterns and the urgent findings that separate them.",
    category: "Emergency Patterns",
    href: "/pdf-guides/cse/11_pneumo_hemo.pdf",
  },
  {
    title: "Burns and Smoke Inhalation",
    description: "Review airway risk, carbon monoxide clues, and early respiratory priorities after burns.",
    category: "Emergency Patterns",
    href: "/pdf-guides/cse/12_burns_smoke.pdf",
  },
  {
    title: "ARDS",
    description: "Review refractory hypoxemia, poor compliance, PEEP, prone positioning, and lung-protective ventilation.",
    category: "Emergency Patterns",
    href: "/pdf-guides/cse/13_ards.pdf",
  },
  {
    title: "Myasthenia Gravis vs Guillain-Barre",
    description: "Compare neuromuscular respiratory failure patterns and ventilatory monitoring clues.",
    category: "Neuro and Systemic Conditions",
    href: "/pdf-guides/cse/14_mg_vs_gbs.pdf",
  },
  {
    title: "CHF and Pulmonary Edema",
    description: "Review cardiogenic pulmonary edema clues, oxygenation support, CPAP/BiPAP, and fluid-related findings.",
    category: "Emergency Patterns",
    href: "/pdf-guides/cse/15_chf_pulmonary_edema.pdf",
  },
  {
    title: "Croup vs Epiglottitis",
    description: "Separate pediatric upper-airway patterns and know when airway manipulation becomes dangerous.",
    category: "Pediatrics and Neonatal",
    href: "/pdf-guides/cse/16_croup_epiglottitis.pdf",
  },
  {
    title: "Neonatal Delivery",
    description: "Review delivery-room priorities, neonatal assessment, oxygen, ventilation, and escalation steps.",
    category: "Pediatrics and Neonatal",
    href: "/pdf-guides/cse/17_neonatal_delivery.pdf",
  },
  {
    title: "ABG Patterns",
    description: "Use pH, PaCO2, HCO3, and oxygenation clues to identify acid-base patterns fast.",
    category: "Diagnostics",
    href: "/pdf-guides/cse/18_abg_patterns.pdf",
  },
  {
    title: "What Test Should I Pick?",
    description: "Review high-yield diagnostic choices and when each test makes sense in a CSE case.",
    category: "Diagnostics",
    href: "/pdf-guides/cse/19_what_test.pdf",
  },
  {
    title: "Normal Values",
    description: "Keep common RT numbers close: ABGs, vitals, oxygenation, labs, hemodynamics, and vent basics.",
    category: "Diagnostics",
    href: "/pdf-guides/cse/20_normal_values.pdf",
  },
];

const categories = Array.from(new Set(pdfGuides.map((guide) => guide.category)));
const featuredGuides = pdfGuides.filter((guide) => guide.featured);
const individualGuides = pdfGuides.filter((guide) => !guide.featured);

export const metadata: Metadata = {
  title: "Free CSE PDF Guides for Respiratory Therapy Students | Exhale Academy",
  description:
    "Download free CSE PDF cheat sheets for respiratory therapy students, then unlock Exhale Academy for realistic CSE clinical simulations, TMC practice questions, and flashcards.",
  keywords: [
    "free CSE PDF guides",
    "CSE prep",
    "CSE exam prep",
    "CSE clinical simulations",
    "respiratory therapy test prep",
    "respiratory therapy exam prep",
    "TMC prep",
    "TMC practice questions",
    "respiratory therapy study guides",
  ],
  alternates: {
    canonical: "/free-cse-pdf-guides",
  },
};

export default function FreeCsePdfGuidesPage() {
  return (
    <main className="min-h-screen overflow-x-hidden bg-background text-charcoal">
      <section className="border-b border-primary/20 bg-[radial-gradient(circle_at_top_left,_rgba(103,208,204,0.28),_transparent_38%),linear-gradient(135deg,#ffffff_0%,#f6fbfb_58%,#eef8f7_100%)]">
        <div className="mx-auto grid w-full max-w-[1460px] gap-8 px-4 py-10 sm:px-10 lg:grid-cols-[1.05fr,0.95fr] lg:px-20 lg:py-16">
          <div className="flex flex-col justify-center">
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-primary">Free CSE PDF Guides</p>
            <h1
              className={`${headingFont} mt-3 text-4xl font-semibold leading-[1.05] text-charcoal sm:text-5xl lg:text-6xl`}
            >
              Free CSE cheat sheet PDFs for respiratory therapy students
            </h1>
            <p className="mt-5 max-w-2xl text-base leading-relaxed text-charcoal/85 sm:text-lg">
              Download high-yield CSE PDF guides for respiratory therapy exam prep, including information gathering,
              decision making, emergency patterns, disease recognition, pediatrics, ABGs, and normal values.
            </p>
            <p className="mt-3 max-w-2xl text-sm leading-relaxed text-graysoft sm:text-base">
              These PDFs help you recognize the patterns. Exhale Academy helps you practice the decisions with realistic
              CSE clinical simulations, TMC practice questions, flashcards, and full board-prep tools.
            </p>
            <div className="mt-7 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
              <a href="#pdf-guides" className="btn-primary px-6 py-3 text-center">
                Get the Free PDFs
              </a>
              <Link href="/preview/cse-scenarios" className="btn-secondary px-6 py-3 text-center">
                Try 2 Free CSE Cases
              </Link>
              <Link href="/signup" className="btn-secondary px-6 py-3 text-center">
                Create Account
              </Link>
            </div>
          </div>

          <div className="rounded-[28px] border border-graysoft/30 bg-white/90 p-5 shadow-sm sm:p-7">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Free Download Funnel</p>
            <div className="mt-4 grid gap-3">
              <article className="rounded-2xl border border-graysoft/25 bg-background p-4">
                <p className="text-3xl font-semibold text-charcoal">{individualGuides.length}</p>
                <p className="mt-1 text-sm font-semibold text-charcoal">Individual CSE PDF guides</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  Students can open or download focused guides by topic.
                </p>
              </article>
              <article className="rounded-2xl border border-primary/25 bg-primary/10 p-4">
                <p className="text-sm font-semibold text-charcoal">PDFs teach recognition</p>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">
                  The full Exhale platform trains application with branching CSE cases, TMC practice, and flashcards.
                </p>
              </article>
              <article className="rounded-2xl border border-amber-200 bg-amber-50 p-4">
                <p className="text-sm font-semibold text-amber-900">Good free value, clear next step</p>
                <p className="mt-2 text-sm leading-relaxed text-amber-900/80">
                  Review the guide, try the free cases, then subscribe when you are ready to practice like exam day.
                </p>
              </article>
            </div>
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 py-8 sm:px-10 lg:px-20">
        <div className="grid gap-4 md:grid-cols-3">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Step 1</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>Download the guides</h2>
            <p className="mt-2 text-sm leading-relaxed text-graysoft">
              Start with the bundles, then review individual topics before practice sessions.
            </p>
          </article>
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Step 2</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>Try real cases</h2>
            <p className="mt-2 text-sm leading-relaxed text-graysoft">
              Use the free CSE preview cases to see how Exhale turns study notes into clinical decisions.
            </p>
          </article>
          <article className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Step 3</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>Unlock full prep</h2>
            <p className="mt-2 text-sm leading-relaxed text-graysoft">
              Subscribe for the full TMC question bank, Master CSE cases, flashcards, and board-prep tools.
            </p>
          </article>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-8 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">What Is Inside</p>
          <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Organized CSE PDF review topics
          </h2>
          <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            {categories.map((category) => {
              const count = pdfGuides.filter((guide) => guide.category === category).length;

              return (
                <article key={category} className="rounded-xl border border-primary/20 bg-background p-4">
                  <p className="text-sm font-semibold text-charcoal">{category}</p>
                  <p className="mt-1 text-xs font-semibold uppercase tracking-[0.14em] text-primary">
                    {count} {count === 1 ? "PDF" : "PDFs"}
                  </p>
                </article>
              );
            })}
          </div>
        </div>
      </section>

      <section id="pdf-guides" className="mx-auto w-full max-w-[1460px] px-4 pb-8 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-primary/25 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Bundle Downloads</p>
          <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Start with the full PDF bundles
          </h2>
          <div className="mt-5 grid gap-4 md:grid-cols-2">
            {featuredGuides.map((guide) => (
              <article key={guide.href} className="rounded-2xl border border-primary/25 bg-primary/10 p-5">
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-primary">{guide.category}</p>
                <h3 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>{guide.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">{guide.description}</p>
                <div className="mt-5 flex flex-col gap-2 sm:flex-row">
                  <a href={guide.href} target="_blank" rel="noreferrer" className="btn-primary px-4 py-2 text-center">
                    View PDF
                  </a>
                  <a href={guide.href} download className="btn-secondary px-4 py-2 text-center">
                    Download PDF
                  </a>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-8 sm:px-10 lg:px-20">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Individual Guides</p>
          <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Pick one topic and review fast
          </h2>
          <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {individualGuides.map((guide) => (
              <article
                key={guide.href}
                className="rounded-2xl border border-graysoft/30 bg-background p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-primary/60 hover:shadow-md"
              >
                <p className="text-xs font-semibold uppercase tracking-[0.16em] text-primary">{guide.category}</p>
                <h3 className={`${headingFont} mt-2 text-xl font-semibold text-charcoal`}>{guide.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-graysoft">{guide.description}</p>
                <div className="mt-5 flex flex-col gap-2 sm:flex-row">
                  <a href={guide.href} target="_blank" rel="noreferrer" className="btn-primary px-4 py-2 text-center">
                    View PDF
                  </a>
                  <a href={guide.href} download className="btn-secondary px-4 py-2 text-center">
                    Download
                  </a>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto w-full max-w-[1460px] px-4 pb-10 sm:px-10 lg:px-20">
        <div className="overflow-hidden rounded-[28px] border border-primary/25 bg-[linear-gradient(135deg,#ffffff_0%,#f6fbfb_50%,#e8f7f6_100%)] p-6 shadow-sm sm:p-8">
          <div className="grid gap-6 lg:grid-cols-[1fr,0.9fr] lg:items-center">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">
                Ready For The Full Engine?
              </p>
              <h2 className={`${headingFont} mt-2 text-3xl font-semibold leading-tight text-charcoal sm:text-4xl`}>
                The PDFs teach the clues. The full site trains the decisions.
              </h2>
              <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
                Exhale Academy gives respiratory therapy students TMC prep, TMC practice questions, CSE exam prep,
                realistic CSE clinical simulations, and high-yield flashcards built for board review.
              </p>
            </div>
            <div className="flex flex-col gap-3">
              <Link href="/signup" className="btn-primary px-6 py-3 text-center">
                Create Account and Subscribe
              </Link>
              <Link href="/preview/cse-scenarios" className="btn-secondary px-6 py-3 text-center">
                Try 2 Free CSE Cases
              </Link>
              <Link href="/preview/tmc-practice-questions" className="btn-secondary px-6 py-3 text-center">
                Try 10 Free TMC Questions
              </Link>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
