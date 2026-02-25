import Link from "next/link";
import { redirect } from "next/navigation";
import PracticeSwitchBar from "../../../components/PracticeSwitchBar";
import { createClient } from "../../../lib/supabase/server";
import { fetchActiveCseCases } from "../../../lib/supabase/cse";
import { headingFont } from "../../../lib/fonts";

type CseAttemptRow = {
  id: string;
  case_id: string;
  mode: "tutor" | "exam";
  current_step_id: string | null;
  completed_at: string | null;
};

type PageProps = {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
};

function asSingleValue(value: string | string[] | undefined): string | null {
  if (Array.isArray(value)) return value[0] ?? null;
  return value ?? null;
}

const NBRC_CATEGORY_ORDER = ["A", "B", "C", "D", "E", "F", "G"] as const;
const NBRC_CATEGORY_LABELS: Record<string, string> = {
  A: "A. Adult Chronic Airways Disease",
  B: "B. Adult Trauma",
  C: "C. Adult Cardiovascular",
  D: "D. Adult Neurological or Neuromuscular",
  E: "E. Adult Medical or Surgical",
  F: "F. Pediatric",
  G: "G. Neonatal",
};

export default async function CseCasesPage({ searchParams }: PageProps) {
  const supabase = await createClient();
  const resolved = (await searchParams) ?? {};
  const selectedCategoryCode = (asSingleValue(resolved.category)?.trim().toUpperCase() ?? "").slice(0, 1);
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fcse%2Fcases");
  }

  const [casesResult, attemptResult] = await Promise.all([
    fetchActiveCseCases(supabase),
    supabase
      .from("cse_attempts")
      .select("id, case_id, mode, current_step_id, completed_at")
      .eq("user_id", user.id)
      .eq("status", "in_progress")
      .order("created_at", { ascending: false }),
  ]);

  const validAttempts = (attemptResult.data ?? []) as CseAttemptRow[];

  const activeAttemptByCase = new Map<string, CseAttemptRow>();
  for (const raw of validAttempts) {
    if (!activeAttemptByCase.has(raw.case_id)) {
      activeAttemptByCase.set(raw.case_id, raw);
    }
  }

  const sortedCases = [...casesResult.rows].sort((a, b) => (a.title ?? "").localeCompare(b.title ?? ""));

  const grouped = new Map<string, typeof sortedCases>();
  for (const cseCase of sortedCases) {
    const code = (cseCase.nbrc_category_code ?? "").trim().toUpperCase();
    if (!code) continue;
    if (selectedCategoryCode && code !== selectedCategoryCode) continue;
    const key = code;
    const existing = grouped.get(key) ?? [];
    existing.push(cseCase);
    grouped.set(key, existing);
  }

  const categoryMeta = NBRC_CATEGORY_ORDER.map((code) => {
    const count = sortedCases.filter((row) => (row.nbrc_category_code ?? "").toUpperCase() === code).length;
    return {
      key: code,
      code,
      label: NBRC_CATEGORY_LABELS[code],
      count,
    };
  }).filter((meta) => meta.count > 0);

  const categories = categoryMeta.map((meta) => ({
    ...meta,
    href: `/cse/cases?category=${encodeURIComponent(meta.code)}`,
    selected: meta.code === selectedCategoryCode,
  }));

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <PracticeSwitchBar active="cse" cseHref="/cse" tmcHref="/tmc" />
      <div className="mx-auto w-full max-w-5xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">CSE Cases</p>
          <h1 className={`${headingFont} mt-2 text-3xl font-semibold text-charcoal sm:text-4xl`}>Case Library</h1>
          <p className="mt-3 text-sm text-graysoft">Choose a scenario to start Tutor or Exam mode.</p>
          <div className="mt-4 flex flex-wrap gap-2">
            <Link
              href="/cse/master"
              className="rounded-full border border-primary bg-primary px-3 py-2 text-xs font-semibold text-white"
            >
              Start Master CSE
            </Link>
            {categories.map((category) => (
              <Link
                key={category.key}
                href={category.href}
                className={`rounded-full border px-3 py-2 text-xs font-semibold ${
                  category.selected
                    ? "border-primary bg-primary text-white"
                    : "border-graysoft/30 text-charcoal"
                }`}
              >
                {category.label} · {category.count}
              </Link>
            ))}
          </div>
          {casesResult.error ? (
            <p className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              Could not load cases: {casesResult.error}
            </p>
          ) : null}
        </section>

        {Array.from(grouped.entries()).map(([key, cases]) => {
          const categoryLabel = NBRC_CATEGORY_LABELS[key] ?? key;
          return (
            <section key={key} className="space-y-3">
              <h2 className={`${headingFont} text-lg font-semibold text-charcoal`}>
                {categoryLabel}
              </h2>
              <div className="grid gap-4 md:grid-cols-2">
                {cases.map((cseCase) => {
                  const inProgress = activeAttemptByCase.get(cseCase.id);
                  const caseRef = cseCase.slug && cseCase.slug.trim().length > 0 ? cseCase.slug : cseCase.id;

                  return (
                    <article key={cseCase.id} className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:border-primary hover:shadow-md">
                      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-primary">
                        {cseCase.source ?? "case"}
                      </p>
                      <h3 className="mt-2 text-xl font-semibold text-charcoal">{cseCase.title}</h3>
                      <p className="mt-2 text-sm text-graysoft">{cseCase.stem ?? "Clinical simulation scenario."}</p>

                      <div className="mt-5 flex flex-wrap gap-3">
                        <Link
                          href={`/cse/case/${encodeURIComponent(caseRef)}`}
                          className="btn-primary"
                        >
                          Open Case
                        </Link>
                        {inProgress ? (
                          <Link
                            href={`/cse/attempt/${encodeURIComponent(inProgress.id)}`}
                            className="btn-secondary"
                          >
                            Resume {inProgress.mode === "tutor" ? "Tutor" : "Exam"}
                          </Link>
                        ) : null}
                      </div>
                    </article>
                  );
                })}
              </div>
            </section>
          );
        })}
        {grouped.size === 0 ? (
          <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 text-sm text-slate-600 shadow-sm">
            No cases found for this category filter yet.
          </section>
        ) : null}
      </div>
    </main>
  );
}
