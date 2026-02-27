import Link from "next/link";
import { createClient } from "../lib/supabase/server";
import BrandLogo from "./BrandLogo";

const primaryBtnClass =
  "inline-flex items-center justify-center rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/40 focus:ring-offset-1 focus:ring-offset-background";
const secondaryBtnClass =
  "inline-flex items-center justify-center rounded-lg border border-primary/40 bg-background px-4 py-2 text-sm font-semibold text-primary transition hover:bg-primary/5";

export default async function AppHeader() {
  let user: { email?: string | null } | null = null;
  try {
    const supabase = await createClient();
    const {
      data: { user: authUser },
    } = await supabase.auth.getUser();
    user = authUser;
  } catch {
    // Fail open for header rendering if auth client/env is misconfigured in a deployment.
    user = null;
  }

  const homeHref = user ? "/dashboard" : "/";
  const tmcHref = user ? "/dashboard" : "/login?next=%2Fdashboard";
  const cseHref = user ? "/cse/introduction" : "/login?next=%2Fcse%2Fintroduction";
  const feedbackHref = user ? "/feedback" : "/login?next=%2Ffeedback";

  return (
    <header className="sticky top-0 z-50 border-b border-graysoft/30 bg-white">
      <div className="mx-auto flex h-[68px] w-full max-w-5xl items-center justify-between gap-3 px-4 sm:px-6 lg:px-8">
        <div className="min-w-0">
          <BrandLogo href={homeHref} />
        </div>

        <div className="hidden items-center gap-2 sm:flex">
          <Link href={cseHref} className={secondaryBtnClass}>
            CSE Practice
          </Link>
          <Link href={tmcHref} className={secondaryBtnClass}>
            TMC Practice
          </Link>
          <Link href={feedbackHref} className={secondaryBtnClass}>
            How can we get better?
          </Link>
          {user ? (
            <>
              <span className="inline-flex max-w-[180px] items-center truncate rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
                {user.email}
              </span>
              <form action="/logout" method="post">
                <button type="submit" className={primaryBtnClass}>
                  Logout
                </button>
              </form>
            </>
          ) : (
            <>
              <Link href="/login" className={secondaryBtnClass}>
                Log In
              </Link>
              <Link href="/signup" className={primaryBtnClass}>
                Sign Up
              </Link>
            </>
          )}
        </div>

        <details className="relative sm:hidden">
          <summary className="list-none rounded-lg border border-primary/40 bg-background px-3 py-2 text-sm font-semibold text-primary">
            Menu
          </summary>
          <div className="absolute right-0 mt-2 w-56 rounded-xl border border-graysoft/30 bg-white p-2 shadow-lg">
            <Link href={cseHref} className="block rounded-md px-3 py-2 text-sm text-charcoal hover:bg-primary/5">
              CSE Practice
            </Link>
            <Link href={tmcHref} className="block rounded-md px-3 py-2 text-sm text-charcoal hover:bg-primary/5">
              TMC Practice
            </Link>
            <Link href={feedbackHref} className="block rounded-md px-3 py-2 text-sm text-charcoal hover:bg-primary/5">
              How can we get better?
            </Link>
            {user ? (
              <>
                <p className="mx-3 mt-1 truncate rounded-full bg-primary/10 px-3 py-1 text-xs font-medium text-primary">
                  {user.email}
                </p>
                <form action="/logout" method="post" className="p-2">
                  <button type="submit" className={`${primaryBtnClass} w-full`}>
                    Logout
                  </button>
                </form>
              </>
            ) : (
              <div className="space-y-2 p-2">
                <Link href="/login" className={`${secondaryBtnClass} w-full`}>
                  Log In
                </Link>
                <Link href="/signup" className={`${primaryBtnClass} w-full`}>
                  Sign Up
                </Link>
              </div>
            )}
          </div>
        </details>
      </div>
    </header>
  );
}
