import Link from "next/link";
import { redirect } from "next/navigation";
import StripeElementsCheckout from "../../components/billing/StripeElementsCheckout";
import { headingFont } from "../../lib/fonts";
import { createClient } from "../../lib/supabase/server";

type BillingPageProps = {
  searchParams: Promise<{ error?: string; success?: string }>;
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
        {query.success ? (
          <section className="rounded-xl border border-green-300 bg-green-50 p-4 text-sm text-green-700">{query.success}</section>
        ) : null}

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <h2 className={`${headingFont} text-xl font-semibold text-charcoal sm:text-2xl`}>
            What you get with your subscription
          </h2>
          <ul className="mt-3 space-y-1 text-sm text-graysoft">
            <li>• Full TMC category drills + 160-question mixed exams</li>
            <li>• Full CSE branching scenarios with Tutor and Exam modes</li>
            <li>• Master CSE exams that mimic test day flow</li>
            <li>• Ongoing updates, study guides, and cheat sheets</li>
            <li>• Mobile-friendly access on phones, tablets, and desktop</li>
          </ul>

          <div className="mt-6 rounded-xl border border-graysoft/30 bg-background p-4">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">Secure Checkout</p>
            <p className="mt-1 text-sm text-graysoft">
              Enter your account details and payment information below.
            </p>
          </div>

          <div className="mt-4">
            <StripeElementsCheckout defaultEmail={user.email ?? ""} />
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
