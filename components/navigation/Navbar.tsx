import Link from "next/link";
import Image from "next/image";
import { createClient } from "../../lib/supabase/server";

export default async function Navbar() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const tmcHref = user ? "/tmc" : "/login?next=%2Ftmc";
  const cseHref = user ? "/cse/introduction" : "/login?next=%2Fcse%2Fintroduction";

  return (
    <header className="sticky top-0 z-50 border-b border-[color:var(--border)] bg-[color:var(--surface)]/95 backdrop-blur">
      <div className="mx-auto w-full max-w-6xl px-4 py-3 sm:px-6">
        <div className="flex items-center justify-between gap-4">
          <Link href={user ? "/dashboard" : "/"} className="inline-flex items-center">
            <Image
              src="/logo.png"
              alt="Exhale Academy"
              width={220}
              height={44}
              className="h-8 w-auto object-contain sm:h-9"
              priority
            />
          </Link>

          <nav className="hidden items-center gap-5 text-sm font-medium text-[color:var(--brand-navy)] sm:flex">
            <Link href={tmcHref} className="transition hover:text-[color:var(--brand-gold)]">
              TMC
            </Link>
            <Link href={cseHref} className="transition hover:text-[color:var(--brand-gold)]">
              CSE
            </Link>
            {user ? (
              <>
                <Link href="/account" className="transition hover:text-[color:var(--brand-gold)]">
                  Account
                </Link>
                <form action="/logout" method="post">
                  <button className="rounded-lg border border-[color:var(--brand-gold)] px-3 py-1.5 text-xs font-semibold text-[color:var(--brand-navy)] transition hover:bg-[color:var(--brand-gold)]/10 sm:text-sm">
                    Log out
                  </button>
                </form>
              </>
            ) : (
              <>
                <Link href="/login" className="transition hover:text-[color:var(--brand-gold)]">
                  Log In
                </Link>
                <Link
                  href="/signup"
                  className="rounded-lg border border-[color:var(--brand-gold)] px-3 py-1.5 text-xs font-semibold text-[color:var(--brand-navy)] transition hover:bg-[color:var(--brand-gold)]/10 sm:text-sm"
                >
                  Sign Up
                </Link>
              </>
            )}
          </nav>

          <details className="relative sm:hidden">
            <summary className="list-none rounded-lg border border-[color:var(--cool-gray)] px-3 py-2 text-sm font-semibold text-[color:var(--brand-navy)]">
              Menu
            </summary>
            <div className="absolute right-0 mt-2 w-52 rounded-xl border border-[color:var(--border)] bg-white p-2 shadow-lg">
              <Link href={tmcHref} className="block rounded-md px-3 py-2 text-sm text-[color:var(--brand-navy)] hover:bg-[color:var(--surface-soft)]">
                TMC
              </Link>
              <Link href={cseHref} className="block rounded-md px-3 py-2 text-sm text-[color:var(--brand-navy)] hover:bg-[color:var(--surface-soft)]">
                CSE
              </Link>
              {user ? (
                <>
                  <Link href="/account" className="block rounded-md px-3 py-2 text-sm text-[color:var(--brand-navy)] hover:bg-[color:var(--surface-soft)]">
                    Account
                  </Link>
                  <form action="/logout" method="post" className="px-1 pt-1">
                    <button className="w-full rounded-md border border-[color:var(--brand-gold)] px-3 py-2 text-left text-sm font-semibold text-[color:var(--brand-navy)]">
                      Log out
                    </button>
                  </form>
                </>
              ) : (
                <>
                  <Link href="/login" className="block rounded-md px-3 py-2 text-sm text-[color:var(--brand-navy)] hover:bg-[color:var(--surface-soft)]">
                    Log In
                  </Link>
                  <Link href="/signup" className="block rounded-md px-3 py-2 text-sm text-[color:var(--brand-navy)] hover:bg-[color:var(--surface-soft)]">
                    Sign Up
                  </Link>
                </>
              )}
            </div>
          </details>
        </div>
      </div>
    </header>
  );
}
