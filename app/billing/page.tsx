import Link from "next/link";
import { redirect } from "next/navigation";
import SubscribeButton from "../../components/billing/SubscribeButton";
import { headingFont } from "../../lib/fonts";
import { resolveIsSubscribed } from "../../lib/auth/subscription-access";
import { createClient } from "../../lib/supabase/server";

type BillingPageProps = {
  searchParams: Promise<{ error?: string; success?: string; canceled?: string }>;
};

export default async function BillingPage({ searchParams }: BillingPageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Fbilling");
  }

  const isSubscribed = await resolveIsSubscribed(supabase, user.id);
  if (isSubscribed) {
    redirect("/dashboard");
  }

  const query = await searchParams;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-3xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Billing</p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Subscribe to Exhale Academy
          </h1>
          <p className="mt-3 text-sm text-graysoft">
            Complete your subscription onboarding below. Once payment is successful, you can access the full exam
            dashboard and all practice content.
          </p>
          <p className="mt-2 text-xs text-graysoft">
            Signed in as <span className="font-semibold text-charcoal">{user.email}</span>
          </p>
        </section>

        {query.error ? (
          <section className="rounded-xl border border-red-300 bg-red-50 p-4 text-sm text-red-700">{query.error}</section>
        ) : null}
        {String(query.success ?? "") === "1" ? (
          <section className="rounded-xl border border-green-300 bg-green-50 p-4 text-sm text-green-700">
            Payment submitted. Your access will unlock after Stripe webhook confirmation.
          </section>
        ) : null}
        {String(query.canceled ?? "") === "1" ? (
          <section className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-700">
            Checkout canceled. You can subscribe anytime below.
          </section>
        ) : null}

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-xl font-semibold text-charcoal sm:text-2xl`}>
            Upgrade to unlock full access
          </h2>
          <ul className="mt-3 space-y-1 text-sm text-graysoft">
            <li>• Exhale Academy – All Access (TMC + CSE)</li>
            <li>• Full TMC category drills + 160-question mixed exams</li>
            <li>• Full CSE branching scenarios with Tutor and Exam modes</li>
            <li>• Master CSE exams that mimic test day flow</li>
            <li>• Ongoing updates, study guides, and cheat sheets</li>
          </ul>

          <div className="mt-6 rounded-xl border border-graysoft/30 bg-background p-4">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Monthly Subscription</p>
            <p className="mt-1 text-sm text-graysoft">
              Start secure Stripe Checkout to activate your subscription.
            </p>
          </div>

          <div className="mt-4">
            <SubscribeButton label="Subscribe" />
          </div>
          <div className="mt-5">
            <Link href="/dashboard" className="btn-secondary">
              Back to Dashboard
            </Link>
          </div>
        </section>
      </div>
    </main>
  );
}
