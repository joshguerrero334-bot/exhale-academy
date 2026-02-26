import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { headingFont } from "../../lib/fonts";

type AccountPageProps = {
  searchParams: Promise<{ billing?: string }>;
};

export default async function AccountPage({ searchParams }: AccountPageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("user_profiles")
    .select(
      "subscription_status, subscription_current_period_end, subscription_cancel_at_period_end, stripe_subscription_id"
    )
    .eq("id", user.id)
    .maybeSingle();

  const query = await searchParams;
  const billingSuccess = String(query.billing ?? "").toLowerCase() === "success";
  const status = String(profile?.subscription_status ?? "inactive").toLowerCase();
  const isActive = status === "active" || status === "trialing";
  const periodEndRaw = profile?.subscription_current_period_end;
  const periodEnd = periodEndRaw
    ? new Date(String(periodEndRaw)).toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      })
    : null;
  const badgeClass = isActive
    ? "rounded-full border border-green-300 bg-green-50 px-3 py-1 text-xs font-semibold text-green-700"
    : "rounded-full border border-graysoft/40 bg-background px-3 py-1 text-xs font-semibold text-graysoft";

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-3xl space-y-5 px-4 py-8 sm:px-6 lg:px-8">
        <div className="rounded-2xl border border-graysoft/30 bg-white p-5 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Account</p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>Profile</h1>

          {billingSuccess ? (
            <div className="mt-4 rounded-xl border border-green-300 bg-green-50 p-3 text-sm text-green-700">
              Payment submitted. Subscription status updates within seconds after webhook confirmation.
            </div>
          ) : null}

          <div className="mt-6 rounded-xl border border-graysoft/30 bg-background p-4">
            <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Email</p>
            <p className="mt-2 text-sm font-semibold text-charcoal">{user.email}</p>
          </div>

          <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4">
            <div className="flex flex-wrap items-center gap-2">
              <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Billing status</p>
              <span className={badgeClass}>{isActive ? "Active" : "Inactive"}</span>
            </div>
            <p className="mt-2 text-sm text-charcoal">
              Plan: <span className="font-semibold">Exhale Monthly</span>
            </p>
            <p className="mt-1 text-sm text-graysoft">
              Subscription state: <span className="font-medium text-charcoal">{status}</span>
            </p>
            {profile?.stripe_subscription_id ? (
              <p className="mt-1 text-xs text-graysoft">
                Subscription ID: <span className="font-mono">{profile.stripe_subscription_id}</span>
              </p>
            ) : null}
            {periodEnd ? (
              <p className="mt-1 text-sm text-graysoft">
                Current period ends: <span className="font-medium text-charcoal">{periodEnd}</span>
              </p>
            ) : null}
            {profile?.subscription_cancel_at_period_end ? (
              <p className="mt-1 text-sm text-amber-700">
                This subscription is set to cancel at period end.
              </p>
            ) : null}
          </div>

          <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
            <a href="/dashboard" className="btn-primary w-full sm:w-auto">
              Return to Dashboard
            </a>
            {isActive ? (
              <a href="/billing" className="btn-secondary w-full sm:w-auto">
                Manage Billing
              </a>
            ) : (
              <a href="/billing" className="btn-primary w-full sm:w-auto">
                Subscribe Now
              </a>
            )}
            <form action="/logout" method="post" className="w-full sm:w-auto">
              <button className="btn-secondary w-full sm:w-auto">Logout</button>
            </form>
          </div>
        </div>
      </div>
    </main>
  );
}
