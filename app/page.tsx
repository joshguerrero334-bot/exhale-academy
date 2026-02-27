import Link from "next/link";
import { createClient } from "../lib/supabase/server";
import { headingFont } from "../lib/fonts";

export default async function Home() {
  let isLoggedIn = false;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    isLoggedIn = !!user;
  } catch {
    isLoggedIn = false;
  }

  return (
    <main className="min-h-screen overflow-x-hidden bg-background text-charcoal">
      <section className="mx-auto grid w-full max-w-[1460px] lg:min-h-[calc(100vh-68px)] lg:grid-cols-[600px_1fr]">
        <div className="flex items-center justify-center bg-white px-4 py-5 sm:px-10 sm:py-8 lg:border-r lg:border-graysoft/30">
          <div className="w-full max-w-[430px] rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
            <p className="text-[11px] font-semibold uppercase tracking-[0.24em] text-primary">Exhale Academy</p>
            <h1
              className={`${headingFont} mt-2.5 text-[1.85rem] font-semibold leading-[1.15] text-charcoal sm:text-[2.15rem] lg:text-[2.3rem]`}
            >
              Log in or create your account
            </h1>
            <p className="mt-2.5 text-sm leading-relaxed text-graysoft">
              New users: Create account, subscribe, then start practicing.
            </p>
            <p className="mt-1 text-sm leading-relaxed text-graysoft">Subscribed users: Log in to access your dashboard.</p>

            <div className="mt-6 space-y-2.5">
              {isLoggedIn ? (
                <Link href="/dashboard" className="btn-primary w-full px-6 py-3 text-center text-sm">
                  Go to Dashboard
                </Link>
              ) : (
                <Link href="/signup" className="btn-primary w-full px-6 py-3 text-center text-sm">
                  Create Account
                </Link>
              )}
              <Link href="/login" className="btn-secondary w-full px-6 py-3 text-center text-sm">
                Log In
              </Link>
            </div>

            <p className="mt-5 text-xs leading-relaxed text-graysoft">
              Don&apos;t spend hundreds on test prep. Don&apos;t sit in boring lectures. Study from anywhere.
            </p>

            <div className="mt-7 flex flex-wrap items-center gap-x-4 gap-y-2 text-[12px] text-graysoft">
              <Link href="/about" className="hover:text-primary">About Us</Link>
              <Link href="/privacy" className="hover:text-primary">Privacy</Link>
              <Link href="/terms" className="hover:text-primary">Terms</Link>
            </div>
          </div>
        </div>

        <div className="flex items-center bg-gradient-to-br from-primary/28 via-primary/12 to-background px-4 py-8 sm:px-12 sm:py-10 lg:px-20">
          <div className="mx-auto w-full max-w-[760px] text-center lg:text-left">
            <h2
              className={`${headingFont} text-[2rem] font-semibold leading-[1.12] text-charcoal sm:text-[2.6rem] lg:text-[3.15rem]`}
            >
              Modern RT prep for TMC + CSE
            </h2>
            <p className="mx-auto mt-5 max-w-2xl text-[1.03rem] leading-[1.7] text-charcoal/90 sm:text-[1.15rem] lg:mx-0">
              Exhale Academy gives you realistic exam-style practice without outdated content, lecture fatigue, or
              expensive prep programs.
            </p>

            <div className="mt-8 grid gap-3.5 sm:grid-cols-2">
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Save More</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">No expensive bundles or outdated prep systems.</p>
              </div>
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Study Anywhere</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">Phone, tablet, laptop, and desktop friendly.</p>
              </div>
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">TMC + CSE</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">One subscription for both exam pathways.</p>
              </div>
              <div className="rounded-xl border border-graysoft/30 bg-white/90 p-4 text-left shadow-sm">
                <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-primary">Not Outdated</p>
                <p className="mt-1 text-sm leading-relaxed text-charcoal">Fresh, structured prep built for today&apos;s RT students.</p>
              </div>
            </div>

            <div className="mt-8 flex justify-center lg:justify-start">
              <Link href="/coming-soon" className="btn-primary w-full px-6 py-3 text-center sm:w-auto">
                See What&apos;s Coming Next
              </Link>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
