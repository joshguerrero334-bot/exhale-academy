import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "../../../../lib/supabase/server";

type DebugRow = {
  case_id: string;
  case_slug: string | null;
  case_title: string;
  step_id: string;
  step_order: number;
  step_type: string;
  max_select: number | null;
  default_rule_count: number;
  outcome_if_student_hits: number;
};

export default async function CseDebugPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) redirect("/login");

  const { data: rows, error: debugError } = await supabase.rpc("cse_debug_rows");
  const debugRows = (rows ?? []) as DebugRow[];

  const cases = new Map<string, { slug: string | null; title: string; stepCount: number; issues: string[] }>();
  for (const row of debugRows) {
    const current = cases.get(row.case_id) ?? {
      slug: row.case_slug,
      title: row.case_title,
      stepCount: 0,
      issues: [],
    };
    current.stepCount += 1;
    if (row.step_type === "IG" && (row.max_select ?? 0) < 1) current.issues.push(`Step ${row.step_order}: missing max_select`);
    if (row.default_rule_count !== 1) current.issues.push(`Step ${row.step_order}: DEFAULT rules=${row.default_rule_count}`);
    if (row.outcome_if_student_hits > 0) current.issues.push(`Step ${row.step_order}: outcome contains forbidden phrase`);
    cases.set(row.case_id, current);
  }

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-5xl space-y-5">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Admin</p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">CSE Debug</h1>
          <p className="mt-2 text-sm text-slate-600">Validates branching-case integrity checks.</p>
          {debugError ? (
            <p className="mt-3 rounded-lg border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              Debug RPC missing. Create function `public.cse_debug_rows()` in Supabase.
            </p>
          ) : null}
        </section>

        {[...cases.entries()].map(([caseId, c]) => (
          <section key={caseId} className="rounded-xl border border-[color:var(--border)] bg-[color:var(--surface)] p-4 shadow-sm">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-sm font-semibold text-[color:var(--brand-navy)]">{c.title}</p>
                <p className="text-xs text-slate-500">slug: {c.slug ?? "n/a"} · steps: {c.stepCount}</p>
              </div>
              <Link href={`/cse/case/${encodeURIComponent(c.slug ?? caseId)}?preview=1`} className="rounded-lg border border-[color:var(--brand-gold)] px-3 py-2 text-xs font-semibold text-[color:var(--brand-navy)]">
                Run Case
              </Link>
            </div>
            {c.issues.length > 0 ? (
              <ul className="mt-3 list-disc space-y-1 pl-5 text-xs text-red-700">
                {c.issues.map((issue, idx) => (
                  <li key={`${caseId}-${idx}`}>{issue}</li>
                ))}
              </ul>
            ) : (
              <p className="mt-3 text-xs text-emerald-700">All checks passed.</p>
            )}
          </section>
        ))}
      </div>
    </main>
  );
}
