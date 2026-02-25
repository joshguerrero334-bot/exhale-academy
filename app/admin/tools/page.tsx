import { redirect } from "next/navigation";
import { createClient } from "../../../lib/supabase/server";
import { getActiveCategoriesWithCounts, getQuestionSlugCounts } from "../../../lib/supabase/taxonomy";
import { isAdminUser } from "../../../lib/auth/admin";

const QUESTION_IMPORT_HEADERS = [
  "category",
  "category_slug",
  "sub_concept",
  "difficulty",
  "cognitive_level",
  "exam_priority",
  "stem",
  "option_a",
  "option_b",
  "option_c",
  "option_d",
  "correct_answer",
  "rationale_correct",
  "rationale_why_others_wrong",
  "keywords_to_notice",
  "common_trap",
  "exam_logic",
  "qa_summary",
];

const CATEGORIES_CSV_TEMPLATE = `slug,name,sort_order,is_active
oxygenation,Oxygenation,1,true
ventilation,Ventilation,2,true
airway-management,Airway Management,3,true
abg-acid-base,ABG & Acid-Base,4,true
mechanical-ventilation,Mechanical Ventilation,5,true
pharmacology,Pharmacology,6,true
patient-assessment,Patient Assessment,7,true
pulmonary-function-testing,Pulmonary Function Testing,8,true
neonatal-peds,Neonatal & Pediatrics,9,true
infection-control-safety,Infection Control & Safety,10,true`;

export default async function AdminToolsPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    redirect("/login");
  }

  if (!isAdminUser({ id: user.id, email: user.email ?? null })) {
    redirect("/dashboard?error=Admin%20access%20only");
  }

  const [categoriesResult, countsResult] = await Promise.all([
    getActiveCategoriesWithCounts(supabase),
    getQuestionSlugCounts(supabase),
  ]);

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-4xl space-y-6">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">
            Admin Tools
          </p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">Content Import Toolkit</h1>
          <p className="mt-3 text-sm text-slate-600">
            Use these tools to keep category taxonomy and question imports consistent.
          </p>
          <a
            href="/categories.csv"
            download
            className="mt-6 inline-flex rounded-lg bg-[color:var(--brand-navy)] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[color:var(--brand-navy-strong)]"
          >
            Download categories.csv template
          </a>
          <h2 className="mt-6 text-lg font-semibold text-[color:var(--brand-navy)]">Copyable categories.csv</h2>
          <pre className="mt-3 overflow-x-auto rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4 text-xs text-slate-700">
            {CATEGORIES_CSV_TEMPLATE}
          </pre>
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Current Import Status</h2>
          {categoriesResult.error || countsResult.error ? (
            <p className="mt-3 text-sm text-red-700">
              Could not load counts. categories: {categoriesResult.error ?? "none"} | questions: {countsResult.error ?? "none"}
            </p>
          ) : (
            <>
              <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
                <div className="rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3">
                  <p className="text-xs uppercase tracking-[0.12em] text-slate-500">Total Questions</p>
                  <p className="mt-1 text-lg font-semibold text-[color:var(--brand-navy)]">{countsResult.total}</p>
                </div>
                <div className="rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3">
                  <p className="text-xs uppercase tracking-[0.12em] text-slate-500">Unassigned</p>
                  <p className="mt-1 text-lg font-semibold text-[color:var(--brand-navy)]">{countsResult.unassigned}</p>
                </div>
                <div className="rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3">
                  <p className="text-xs uppercase tracking-[0.12em] text-slate-500">Active Categories</p>
                  <p className="mt-1 text-lg font-semibold text-[color:var(--brand-navy)]">{categoriesResult.rows.length}</p>
                </div>
              </div>

              <div className="mt-4 rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
                <p className="text-sm font-semibold text-[color:var(--brand-navy)]">Counts by category_slug</p>
                <div className="mt-2 grid gap-2 sm:grid-cols-2">
                  {categoriesResult.rows.map((row) => (
                    <div key={row.slug} className="flex items-center justify-between rounded-md border border-[color:var(--cool-gray)] bg-white px-3 py-2 text-sm">
                      <span className="font-mono text-slate-700">{row.slug}</span>
                      <span className="font-semibold text-[color:var(--brand-navy)]">{row.question_count}</span>
                    </div>
                  ))}
                </div>
              </div>
            </>
          )}
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Question CSV Required Headers</h2>
          <p className="mt-2 text-sm text-slate-600">
            Keep this exact column order for reliable import and category matching.
          </p>
          <pre className="mt-4 overflow-x-auto rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4 text-xs text-slate-700">
            {QUESTION_IMPORT_HEADERS.join(",")}
          </pre>
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-[color:var(--brand-navy)]">Batch Import Checklist</h2>
          <ul className="mt-3 list-disc space-y-2 pl-5 text-sm text-slate-700">
            <li>Ensure `category_slug` values exactly match rows in `categories.slug`.</li>
            <li>Export/update CSV with `scripts/backfill-category-slug.mjs` before import.</li>
            <li>Import in Supabase Table Editor, then validate counts on `/dashboard`.</li>
          </ul>
        </section>

        <div>
          <a
            href="/dashboard"
            className="inline-flex rounded-lg border border-[color:var(--brand-gold)] px-4 py-2 text-sm font-semibold text-[color:var(--brand-navy)] transition hover:bg-[color:var(--brand-gold)]/15"
          >
            Back to Dashboard
          </a>
        </div>
      </div>
    </main>
  );
}
