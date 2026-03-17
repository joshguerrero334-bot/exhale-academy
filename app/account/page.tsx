import Link from "next/link";
import { redirect } from "next/navigation";
import ManageBillingButton from "../../components/billing/ManageBillingButton";
import { isAdminUser } from "../../lib/auth/admin";
import { STRONG_PASSWORD_HINT } from "../../lib/auth/password-policy";
import { resolveIsSubscribed } from "../../lib/auth/subscription-access";
import { createClient } from "../../lib/supabase/server";
import { headingFont } from "../../lib/fonts";
import { updatePassword, updateProfile, updateProfilePhoto } from "./actions";

type AccountPageProps = {
  searchParams: Promise<{ success?: string; message?: string; error?: string }>;
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

  const query = await searchParams;
  const billingSuccess = String(query.success ?? "") === "1";
  const infoMessage = String(query.message ?? "").trim();
  const errorMessage = String(query.error ?? "").trim();

  const [{ data: profile }, { data: legacyProfile }] = await Promise.all([
    supabase
      .from("profiles")
      .select("first_name, last_name, avatar_url, stripe_customer_id, stripe_subscription_id")
      .eq("user_id", user.id)
      .maybeSingle(),
    supabase
      .from("user_profiles")
      .select("subscription_status, stripe_customer_id, stripe_subscription_id")
      .eq("id", user.id)
      .maybeSingle(),
  ]);

  const firstName = String(profile?.first_name ?? "");
  const lastName = String(profile?.last_name ?? "");
  const avatarUrl = String(profile?.avatar_url ?? user.user_metadata?.avatar_url ?? "").trim();
  const stripeCustomerId = String(
    profile?.stripe_customer_id ?? legacyProfile?.stripe_customer_id ?? ""
  ).trim();
  const stripeSubscriptionId = String(
    profile?.stripe_subscription_id ?? legacyProfile?.stripe_subscription_id ?? ""
  ).trim();
  const legacyStatus = String(legacyProfile?.subscription_status ?? "").trim();
  const createdLabel = user.created_at ? new Date(user.created_at).toLocaleString() : "Unavailable";
  const isActive = await resolveIsSubscribed(supabase, user.id);
  const isAdmin = isAdminUser({ id: user.id, email: user.email ?? null });
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
          {infoMessage ? (
            <div className="mt-4 rounded-xl border border-green-300 bg-green-50 p-3 text-sm text-green-700">{infoMessage}</div>
          ) : null}
          {errorMessage ? (
            <div className="mt-4 rounded-xl border border-red-300 bg-red-50 p-3 text-sm text-red-700">{errorMessage}</div>
          ) : null}

          <div className="mt-6 rounded-xl border border-graysoft/30 bg-background p-4">
            <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Account Information</p>
            <div className="mt-3 flex items-center gap-3">
              <div className="h-14 w-14 overflow-hidden rounded-full border border-graysoft/30 bg-white">
                {avatarUrl ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={avatarUrl} alt="Profile" className="h-full w-full object-cover" />
                ) : (
                  <div className="flex h-full w-full items-center justify-center text-xs font-semibold text-graysoft">No Photo</div>
                )}
              </div>
              <form action={updateProfilePhoto} className="flex flex-wrap items-center gap-2" encType="multipart/form-data">
                <input
                  className="max-w-[220px] rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-xs text-charcoal"
                  type="file"
                  name="avatar"
                  accept="image/png,image/jpeg,image/webp"
                  required
                />
                <button className="btn-secondary">Upload Photo</button>
              </form>
            </div>
            <p className="mt-2 text-sm text-charcoal">
              Email: <span className="font-semibold">{user.email}</span>
            </p>
            <p className="mt-1 text-sm text-charcoal">
              User ID: <span className="font-mono text-xs">{user.id}</span>
            </p>
            <p className="mt-1 text-sm text-charcoal">
              Created: <span className="font-semibold">{createdLabel}</span>
            </p>
          </div>

          <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4">
            <div className="flex flex-wrap items-center gap-2">
              <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Subscription</p>
              <span className={badgeClass}>{isActive ? "Active" : "Inactive"}</span>
            </div>
            <p className="mt-2 text-sm text-charcoal">
              Plan: <span className="font-semibold">Exhale Academy – All Access (TMC + CSE)</span>
            </p>
            <p className="mt-1 text-sm text-graysoft">
              Stripe status syncs from webhook events{legacyStatus ? ` (${legacyStatus})` : ""}.
            </p>
            <p className="mt-2 text-xs text-graysoft">Stripe customer: {stripeCustomerId || "Not linked yet"}</p>
            <p className="mt-1 text-xs text-graysoft">Stripe subscription: {stripeSubscriptionId || "Not linked yet"}</p>
            <div className="mt-3">
              <ManageBillingButton />
            </div>
          </div>

          <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4">
            <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Edit Profile</p>
            <form action={updateProfile} className="mt-3 grid gap-3 sm:grid-cols-2">
              <input
                className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal"
                type="text"
                name="first_name"
                defaultValue={firstName}
                placeholder="First name"
                required
              />
              <input
                className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal"
                type="text"
                name="last_name"
                defaultValue={lastName}
                placeholder="Last name"
                required
              />
              <div className="sm:col-span-2">
                <button className="btn-primary w-full sm:w-auto">Save Profile</button>
              </div>
            </form>
          </div>

          <div className="mt-4 rounded-xl border border-graysoft/30 bg-background p-4">
            <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Security</p>
            <form action={updatePassword} className="mt-3 grid gap-3 sm:grid-cols-2">
              <input
                className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal"
                type="password"
                name="new_password"
                minLength={8}
                pattern="^(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,}$"
                placeholder="New password"
                required
              />
              <input
                className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal"
                type="password"
                name="confirm_password"
                minLength={8}
                placeholder="Confirm password"
                required
              />
              <p className="text-xs text-graysoft sm:col-span-2">{STRONG_PASSWORD_HINT}</p>
              <div className="sm:col-span-2">
                <button className="btn-secondary w-full sm:w-auto">Update Password</button>
              </div>
            </form>
          </div>

          {isAdmin ? (
            <div className="mt-4 rounded-xl border border-primary/30 bg-primary/10 p-4">
              <div className="flex flex-wrap items-center gap-2">
                <p className="text-xs uppercase tracking-[0.16em] text-graysoft">Blog Management</p>
                <span className="rounded-full border border-primary/40 bg-white px-3 py-1 text-xs font-semibold text-primary">Admin</span>
              </div>
              <p className="mt-2 text-sm text-charcoal">
                You have admin access. Manage posts, create new articles, moderate comments, and organize categories and tags here.
              </p>
              <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
                <Link href="/admin/blog" className="btn-primary w-full sm:w-auto">
                  Manage Blog
                </Link>
                <Link href="/admin/blog/new" className="btn-secondary w-full sm:w-auto">
                  New Post
                </Link>
                <Link href="/admin/blog/comments" className="btn-secondary w-full sm:w-auto">
                  Comments
                </Link>
                <Link href="/admin/blog/categories" className="btn-secondary w-full sm:w-auto">
                  Categories
                </Link>
                <Link href="/admin/blog/tags" className="btn-secondary w-full sm:w-auto">
                  Tags
                </Link>
              </div>
            </div>
          ) : null}

          <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
            <a href="/dashboard" className="btn-primary w-full sm:w-auto">
              Return to Dashboard
            </a>
            {!isActive ? (
              <a href="/billing" className="btn-primary w-full sm:w-auto">
                Subscribe Now
              </a>
            ) : null}
            <form action="/logout" method="post" className="w-full sm:w-auto">
              <button className="btn-secondary w-full sm:w-auto">Logout</button>
            </form>
          </div>
        </div>
      </div>
    </main>
  );
}
