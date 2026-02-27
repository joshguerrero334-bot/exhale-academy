import { NextResponse } from "next/server";
import { createAdminClient } from "../../../../lib/supabase/admin";
import { getStripeClient, requireServerEnv } from "../../../../lib/stripe";

function asActive(status: string | null | undefined) {
  const value = String(status ?? "").toLowerCase();
  return value === "active" || value === "trialing";
}

async function findUserIdByCustomerId(customerId: string) {
  const admin = createAdminClient();
  const fromProfiles = await admin
    .from("profiles")
    .select("user_id")
    .eq("stripe_customer_id", customerId)
    .maybeSingle();

  if (!fromProfiles.error && fromProfiles.data?.user_id) {
    return String(fromProfiles.data.user_id);
  }

  const fromLegacy = await admin
    .from("user_profiles")
    .select("id")
    .eq("stripe_customer_id", customerId)
    .maybeSingle();

  if (!fromLegacy.error && fromLegacy.data?.id) {
    return String(fromLegacy.data.id);
  }

  return null;
}

async function setSubscribed(args: {
  userId: string;
  isSubscribed: boolean;
  stripeCustomerId?: string | null;
  stripeSubscriptionId?: string | null;
}) {
  const admin = createAdminClient();
  const nowIso = new Date().toISOString();
  const { error: profilesError } = await admin
    .from("profiles")
    .upsert(
      {
        user_id: args.userId,
        is_subscribed: args.isSubscribed,
        stripe_customer_id: args.stripeCustomerId ?? null,
        stripe_subscription_id: args.stripeSubscriptionId ?? null,
        updated_at: nowIso,
      },
      { onConflict: "user_id" }
    );

  if (profilesError) {
    console.error("[stripe][webhook] profiles sync failed:", profilesError.message);
  }

  const legacyStatus = args.isSubscribed ? "active" : "canceled";
  const { error: legacyError } = await admin
    .from("user_profiles")
    .upsert(
      {
        id: args.userId,
        stripe_customer_id: args.stripeCustomerId ?? null,
        stripe_subscription_id: args.stripeSubscriptionId ?? null,
        subscription_status: legacyStatus,
        subscription_updated_at: nowIso,
        updated_at: nowIso,
      },
      { onConflict: "id" }
    );

  if (legacyError) {
    console.error("[stripe][webhook] user_profiles sync failed:", legacyError.message);
  }

  if (profilesError && legacyError) {
    throw new Error(
      `Both subscription writes failed. profiles=${profilesError.message}; user_profiles=${legacyError.message}`
    );
  }
}

export async function POST(request: Request) {
  let rawBody = "";
  try {
    const env = requireServerEnv("stripe-webhook", [
      "STRIPE_SECRET_KEY",
      "STRIPE_WEBHOOK_SECRET",
      "NEXT_PUBLIC_SUPABASE_URL",
      "SUPABASE_SERVICE_ROLE_KEY",
    ]);

    rawBody = await request.text();
    const signature = request.headers.get("stripe-signature");
    if (!signature) {
      return NextResponse.json({ error: "Missing stripe-signature header." }, { status: 400 });
    }

    const stripe = getStripeClient("stripe-webhook");
    const event = stripe.webhooks.constructEvent(rawBody, signature, env.STRIPE_WEBHOOK_SECRET);

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        let userId =
          String(session.client_reference_id ?? "") ||
          String(session.metadata?.user_id ?? "") ||
          "";
        const customerId = typeof session.customer === "string" ? session.customer : null;
        const subscriptionId =
          typeof session.subscription === "string" ? session.subscription : null;

        if (!userId && customerId) {
          const mappedUserId = await findUserIdByCustomerId(customerId);
          if (mappedUserId) userId = mappedUserId;
        }

        if (!userId || !subscriptionId) break;
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        await setSubscribed({
          userId,
          isSubscribed: asActive(subscription.status),
          stripeCustomerId: typeof subscription.customer === "string" ? subscription.customer : customerId,
          stripeSubscriptionId: subscription.id,
        });
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object;
        let userId = String(subscription.metadata?.user_id ?? "");
        const customerId = typeof subscription.customer === "string" ? subscription.customer : null;
        if (!userId && customerId) {
          const mappedUserId = await findUserIdByCustomerId(customerId);
          if (mappedUserId) userId = mappedUserId;
        }
        if (!userId) break;
        await setSubscribed({
          userId,
          isSubscribed: asActive(subscription.status),
          stripeCustomerId: customerId,
          stripeSubscriptionId: subscription.id,
        });
        break;
      }
      default:
        break;
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Webhook processing failed.";
    console.error("[stripe][webhook] Webhook error:", message, {
      hasBody: rawBody.length > 0,
    });
    return NextResponse.json({ error: message }, { status: 400 });
  }
}
