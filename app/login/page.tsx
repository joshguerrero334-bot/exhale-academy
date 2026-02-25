import Link from "next/link";
import { login } from "./actions";

const SIGNUP_HREF = "/signup";

type LoginPageProps = {
  searchParams: Promise<{
    error?: string;
    message?: string;
    next?: string;
  }>;
};

export default async function LoginPage({ searchParams }: LoginPageProps) {
  const params = await searchParams;
  const nextPath = params.next && params.next.startsWith("/") ? params.next : "/dashboard";

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-md rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Exhale Academy</p>
        <h1 className="mt-2 text-2xl font-bold text-[color:var(--brand-navy)] sm:text-3xl">Log In</h1>
        <p className="mt-2 text-sm text-slate-600">Access your professional RT exam prep dashboard.</p>

        <form action={login} className="mt-8 space-y-4" suppressHydrationWarning>
          <input type="hidden" name="next" value={nextPath} />
          <input
            suppressHydrationWarning
            className="w-full rounded-lg border border-[color:var(--cool-gray)] bg-white px-4 py-3 text-sm outline-none ring-2 ring-transparent transition focus:border-[color:var(--brand-gold)] focus:ring-[color:var(--brand-gold)]/30"
            placeholder="Email"
            autoComplete="email"
            type="email"
            name="email"
            required
          />
          <input
            suppressHydrationWarning
            className="w-full rounded-lg border border-[color:var(--cool-gray)] bg-white px-4 py-3 text-sm outline-none ring-2 ring-transparent transition focus:border-[color:var(--brand-gold)] focus:ring-[color:var(--brand-gold)]/30"
            placeholder="Password"
            type="password"
            autoComplete="current-password"
            name="password"
            required
          />

          <button className="w-full min-h-[44px] rounded-lg bg-[color:var(--brand-navy)] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[color:var(--brand-navy-strong)]">
            Log In
          </button>
        </form>

        {params.error ? (
          <p className="mt-4 rounded-lg border border-red-300 bg-red-50 p-3 text-sm text-red-700">{params.error}</p>
        ) : null}
        {params.message ? (
          <p className="mt-4 rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3 text-sm text-slate-700">{params.message}</p>
        ) : null}

        <p className="mt-6 text-sm text-slate-600">
          No account?{" "}
          <Link className="font-semibold text-[color:var(--brand-navy)] underline" href={SIGNUP_HREF}>
            Create one
          </Link>
        </p>
      </div>
    </main>
  );
}
