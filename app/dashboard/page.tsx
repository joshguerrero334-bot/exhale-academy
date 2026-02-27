import Link from "next/link";
import { redirect } from "next/navigation";
import SubscribeButton from "../../components/billing/SubscribeButton";
import { createClient } from "../../lib/supabase/server";
import { headingFont } from "../../lib/fonts";

type HubPageProps = {
  searchParams: Promise<{ error?: string }>;
};

export default async function DashboardHubPage({ searchParams }: HubPageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fdashboard");
  }

  const query = await searchParams;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-5xl space-y-8 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Exhale Academy</p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            TMC Practice Dashboard
          </h1>
          <p className="mt-2 max-w-xl text-sm text-graysoft">
            Choose a category for targeted practice or start the full-length 160-question TMC exam.
          </p>
          <p className="mt-2 text-xs text-graysoft">
            Signed in as <span className="font-medium text-charcoal">{user.email}</span>
          </p>
          <div className="mt-4">
            <SubscribeButton label="Subscribe" />
          </div>
          {query.error ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">
              {query.error}
            </div>
          ) : null}
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-primary/60 hover:shadow-md sm:p-8">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Clinical Simulation (CSE)</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>CSE Practice</h2>
            <p className="mt-2 text-sm text-graysoft">
              Work through branching clinical scenarios with tutor or exam mode.
            </p>
            <Link
              href="/cse/introduction"
              className="btn-primary mt-5"
            >
              Start CSE Practice
            </Link>
          </article>

          <article className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-primary/60 hover:shadow-md sm:p-8">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">TMC Exam</p>
            <h2 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal`}>TMC Practice</h2>
            <p className="mt-2 text-sm text-graysoft">
              500+ optimized questions and a 160-question master exam.
            </p>
            <Link
              href="/tmc"
              className="btn-secondary mt-5"
            >
              Go to TMC Dashboard
            </Link>
          </article>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Help us improve</p>
          <h2 className={`${headingFont} mt-2 text-xl font-semibold text-charcoal sm:text-2xl`}>
            Exhale is new and evolving fast
          </h2>
          <p className="mt-2 max-w-2xl text-sm text-graysoft">
            Tell us what looks great and where we should improve. Your honesty directly shapes the platform for you
            and other RTs.
          </p>
          <Link href="/feedback" className="btn-primary mt-4">
            How can we get better?
          </Link>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Coming Soon</p>
          <h2 className={`${headingFont} mt-2 text-xl font-semibold text-charcoal sm:text-2xl`}>
            New board-prep tools are on the way
          </h2>
          <p className="mt-2 max-w-2xl text-sm text-graysoft">
            Study guides, cheat sheets, and additional features built to help you pass your boards on test day.
          </p>
          <Link href="/coming-soon" className="btn-secondary mt-4">
            View Coming Soon
          </Link>
        </section>

        <section className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Subscription</p>
          <h2 className={`${headingFont} mt-2 text-xl font-semibold text-charcoal sm:text-2xl`}>
            Activate paid access
          </h2>
          <p className="mt-2 max-w-2xl text-sm text-graysoft">
            Upgrade instantly with Stripe Checkout.
          </p>
          <div className="mt-4">
            <SubscribeButton label="Subscribe" />
          </div>
        </section>
      </div>
    </main>
  );
}
