import { NextResponse } from "next/server";
import { createAdminClient } from "../../../../lib/supabase/admin";
import { createClient } from "../../../../lib/supabase/server";
import { getStripeClient, requireServerEnv } from "../../../../lib/stripe";

function isActiveStatus(status: string | null | undefined) {
  const normalized = String(status ?? "").toLowerCase();
  return normalized === "active" || normalized === "trialing";
}

export async function POST() {
  try {
    requireServerEnv("sync-subscription-status", [
      "STRIPE_SECRET_KEY",
      "NEXT_PUBLIC_SUPABASE_URL",
      "SUPABASE_SERVICE_ROLE_KEY",
    ]);

    const supabase = await createClient();
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const stripe = getStripeClient("sync-subscription-status");
    const admin = createAdminClient();

    const email = String(user.email ?? "").trim().toLowerCase();
    if (!email) {
      return NextResponse.json({ error: "Missing user email." }, { status: 400 });
    }

    const customers = await stripe.customers.list({
      email,
      limit: 10,
    });

    let isSubscribed = false;
    let stripeCustomerId: string | null = null;
    let stripeSubscriptionId: string | null = null;

    for (const customer of customers.data) {
      if (!customer.id) continue;
      stripeCustomerId = customer.id;
      const subscriptions = await stripe.subscriptions.list({
        customer: customer.id,
        status: "all",
        limit: 20,
      });

      const active = subscriptions.data.find((sub) => isActiveStatus(sub.status));
      if (active) {
        isSubscribed = true;
        stripeSubscriptionId = active.id;
        break;
      }
    }

    const { error: profilesError } = await admin
      .from("profiles")
      .upsert(
        {
          user_id: user.id,
          is_subscribed: isSubscribed,
          stripe_customer_id: stripeCustomerId,
          stripe_subscription_id: stripeSubscriptionId,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" }
      );

    const { error: legacyError } = await admin
      .from("user_profiles")
      .upsert(
        {
          id: user.id,
          stripe_customer_id: stripeCustomerId,
          stripe_subscription_id: stripeSubscriptionId,
          subscription_status: isSubscribed ? "active" : "inactive",
          subscription_updated_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        { onConflict: "id" }
      );

    if (profilesError && legacyError) {
      return NextResponse.json(
        {
          error: `Sync failed for both profile tables. profiles=${profilesError.message}; user_profiles=${legacyError.message}`,
        },
        { status: 500 }
      );
    }

    return NextResponse.json({
      ok: true,
      isSubscribed,
      stripeCustomerId,
      stripeSubscriptionId,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Subscription sync failed.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

