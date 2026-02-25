import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";

export default async function AccountPage() {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    redirect("/login");
  }

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-3xl rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Account</p>
        <h1 className="mt-2 text-2xl font-bold text-[color:var(--brand-navy)] sm:text-3xl">Profile</h1>

        <div className="mt-6 rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
          <p className="text-xs uppercase tracking-[0.16em] text-slate-500">Email</p>
          <p className="mt-2 text-sm font-semibold text-[color:var(--text)]">{user.email}</p>
        </div>

        <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
          <a
            href="/dashboard"
            className="inline-flex min-h-[44px] w-full items-center justify-center rounded-lg bg-[color:var(--brand-navy)] px-4 py-2 text-sm font-semibold text-white transition hover:bg-[color:var(--brand-navy-strong)] sm:w-auto"
          >
            Return to Dashboard
          </a>
          <form action="/logout" method="post" className="w-full sm:w-auto">
            <button className="inline-flex min-h-[44px] w-full items-center justify-center rounded-lg border border-[color:var(--brand-gold)] px-4 py-2 text-sm font-semibold text-[color:var(--brand-navy)] transition hover:bg-[color:var(--brand-gold)]/15 sm:w-auto">
              Logout
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}
