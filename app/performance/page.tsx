import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";

type CategoryCountRow = { category: string; count: number };

function summarizeCategoryCounts(rows: CategoryCountRow[]) {
  const total = rows.reduce((sum, row) => sum + row.count, 0);
  const oxygenation = rows.find((row) => row.category.toLowerCase() === "oxygenation")?.count ?? 0;
  const ventilation = rows.find((row) => row.category.toLowerCase() === "ventilation")?.count ?? 0;
  return { total, oxygenation, ventilation };
}

export default async function PerformancePage() {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login");
  }

  const [{ data: answerRows }, { data: questionRows }] = await Promise.all([
    supabase.from("quiz_answers").select("is_correct"),
    supabase.from("questions").select("category"),
  ]);

  const answers = answerRows ?? [];
  const totalAnswered = answers.length;
  const correct = answers.filter((row) => Boolean(row.is_correct)).length;
  const accuracy = totalAnswered > 0 ? Math.round((correct / totalAnswered) * 100) : 0;

  const categoryCountsMap = new Map<string, number>();
  for (const row of questionRows ?? []) {
    const key = String(row.category ?? "").trim();
    if (!key) continue;
    categoryCountsMap.set(key, (categoryCountsMap.get(key) ?? 0) + 1);
  }
  const categoryCounts: CategoryCountRow[] = Array.from(categoryCountsMap.entries()).map(
    ([category, count]) => ({ category, count })
  );

  const { oxygenation, ventilation, total } = summarizeCategoryCounts(categoryCounts);

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">
            Performance
          </p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)] sm:text-4xl">
            Performance Overview
          </h1>
          <p className="mt-3 text-sm text-slate-600">
            Track exam readiness with category-level insight and answer trends.
          </p>

          <div className="mt-6 grid gap-3 sm:grid-cols-3">
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Total Answered</p>
              <p className="mt-1 text-2xl font-semibold text-[color:var(--brand-navy)]">{totalAnswered}</p>
            </div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Accuracy</p>
              <p className="mt-1 text-2xl font-semibold text-[color:var(--brand-navy)]">{accuracy}%</p>
            </div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Question Bank</p>
              <p className="mt-1 text-2xl font-semibold text-[color:var(--brand-navy)]">{total}</p>
            </div>
          </div>
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Category Breakdown</h2>
          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-sm font-semibold text-[color:var(--text)]">Oxygenation</p>
              <p className="mt-1 text-2xl font-semibold text-[color:var(--brand-navy)]">{oxygenation}</p>
            </div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
              <p className="text-sm font-semibold text-[color:var(--text)]">Ventilation</p>
              <p className="mt-1 text-2xl font-semibold text-[color:var(--brand-navy)]">{ventilation}</p>
            </div>
          </div>
        </section>

        <section className="rounded-2xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-5 text-sm text-slate-700">
          <p className="font-semibold text-[color:var(--brand-navy)]">Coming Soon: AI Performance Analytics</p>
          <p className="mt-1">
            Personalized remediation plans and trend-based readiness forecasting will be available after launch.
          </p>
        </section>
      </div>
    </main>
  );
}
