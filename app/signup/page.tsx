import Link from "next/link";
import { signup } from "./actions";

const LOGIN_HREF = "/login";

type SignUpPageProps = {
  searchParams: Promise<{
    error?: string;
    message?: string;
  }>;
};

export default async function SignUpPage({ searchParams }: SignUpPageProps) {
  const params = await searchParams;

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-md rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-sm sm:p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Exhale Academy</p>
        <h1 className="mt-2 text-2xl font-bold text-[color:var(--brand-navy)] sm:text-3xl">Create Account</h1>
        <p className="mt-2 text-sm text-slate-600">Begin structured RT exam preparation.</p>

        <form action={signup} className="mt-8 space-y-4" suppressHydrationWarning>
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
            autoComplete="new-password"
            minLength={6}
            name="password"
            required
          />

          <button className="w-full min-h-[44px] rounded-lg bg-[color:var(--brand-navy)] px-4 py-3 text-sm font-semibold text-white transition hover:bg-[color:var(--brand-navy-strong)]">
            Create Account
          </button>
        </form>

        {params.error ? (
          <p className="mt-4 rounded-lg border border-red-300 bg-red-50 p-3 text-sm text-red-700">{params.error}</p>
        ) : null}
        {params.message ? (
          <p className="mt-4 rounded-lg border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-3 text-sm text-slate-700">{params.message}</p>
        ) : null}

        <p className="mt-6 text-sm text-slate-600">
          Already have an account?{" "}
          <Link className="font-semibold text-[color:var(--brand-navy)] underline" href={LOGIN_HREF}>
            Log in
          </Link>
        </p>
      </div>
    </main>
  );
}
