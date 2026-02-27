import { NextResponse } from "next/server";
import { createAdminClient } from "../../../../lib/supabase/admin";
import { getStripeClient, requireServerEnv } from "../../../../lib/stripe";

function asActive(status: string | null | undefined) {
  const value = String(status ?? "").toLowerCase();
  return value === "active" || value === "trialing";
}

async function setSubscribed(userId: string, isSubscribed: boolean) {
  const admin = createAdminClient();
  const { error } = await admin
    .from("profiles")
    .upsert(
      {
        user_id: userId,
        is_subscribed: isSubscribed,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );

  if (error) {
    throw new Error(`Supabase profile update failed: ${error.message}`);
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
        const userId =
          String(session.client_reference_id ?? "") ||
          String(session.metadata?.user_id ?? "") ||
          "";
        const subscriptionId =
          typeof session.subscription === "string" ? session.subscription : null;

        if (!userId || !subscriptionId) break;
        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        await setSubscribed(userId, asActive(subscription.status));
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object;
        const userId = String(subscription.metadata?.user_id ?? "");
        if (!userId) break;
        await setSubscribed(userId, asActive(subscription.status));
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

