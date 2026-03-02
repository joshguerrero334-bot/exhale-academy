import { NextResponse } from "next/server";
import type Stripe from "stripe";
import { createAdminClient } from "../../../../lib/supabase/admin";
import { getStripeClient, requireServerEnv } from "../../../../lib/stripe";

function asActive(status: string | null | undefined) {
  const value = String(status ?? "").toLowerCase();
  return value === "active" || value === "trialing";
}

async function findUserIdByCustomerId(customerId: string) {
  const admin = createAdminClient();
  const fromUserSubscriptions = await admin
    .from("user_subscriptions")
    .select("user_id")
    .eq("stripe_customer_id", customerId)
    .not("user_id", "is", null)
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!fromUserSubscriptions.error && fromUserSubscriptions.data?.user_id) {
    return String(fromUserSubscriptions.data.user_id);
  }

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

async function findUserIdBySubscriptionId(subscriptionId: string) {
  const admin = createAdminClient();
  const result = await admin
    .from("user_subscriptions")
    .select("user_id")
    .eq("stripe_subscription_id", subscriptionId)
    .not("user_id", "is", null)
    .maybeSingle();

  if (!result.error && result.data?.user_id) {
    return String(result.data.user_id);
  }
  return null;
}

function periodEndToIso(periodEnd: number | null | undefined) {
  if (!periodEnd || Number.isNaN(periodEnd)) return null;
  return new Date(periodEnd * 1000).toISOString();
}

function extractPriceId(subscription: Stripe.Subscription) {
  const firstItem = subscription.items?.data?.[0];
  return firstItem?.price?.id ?? null;
}

async function upsertUserSubscription(args: {
  userId: string | null;
  stripeCustomerId: string | null;
  stripeSubscriptionId: string;
  status: string;
  currentPeriodEnd: string | null;
  cancelAtPeriodEnd: boolean;
  sourceEventType: string;
  latestPayload: Record<string, unknown>;
  priceId: string | null;
}) {
  const admin = createAdminClient();
  const nowIso = new Date().toISOString();
  const { error } = await admin.from("user_subscriptions").upsert(
    {
      user_id: args.userId,
      stripe_customer_id: args.stripeCustomerId,
      stripe_subscription_id: args.stripeSubscriptionId,
      status: args.status,
      price_id: args.priceId,
      current_period_end: args.currentPeriodEnd,
      cancel_at_period_end: args.cancelAtPeriodEnd,
      source_event_type: args.sourceEventType,
      latest_payload: args.latestPayload,
      updated_at: nowIso,
    },
    { onConflict: "stripe_subscription_id" }
  );

  if (error) {
    throw new Error(`user_subscriptions upsert failed: ${error.message}`);
  }
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
    const env = requireServerEnv("stripe-webhook-live", [
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
    let attemptedSubscriptionWrite = false;

    console.info("[stripe][webhook] Event received", {
      eventId: event.id,
      type: event.type,
      livemode: event.livemode,
    });

    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
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

        if (!userId && subscriptionId) {
          const mappedUserId = await findUserIdBySubscriptionId(subscriptionId);
          if (mappedUserId) userId = mappedUserId;
        }
        if (!subscriptionId) {
          throw new Error("checkout.session.completed missing subscription id");
        }

        const subscription = await stripe.subscriptions.retrieve(subscriptionId);
        const resolvedCustomerId =
          typeof subscription.customer === "string" ? subscription.customer : customerId;
        const resolvedUserId = userId || (resolvedCustomerId ? await findUserIdByCustomerId(resolvedCustomerId) : null);

        await upsertUserSubscription({
          userId: resolvedUserId || null,
          stripeCustomerId: resolvedCustomerId ?? null,
          stripeSubscriptionId: subscription.id,
          status: "active",
          currentPeriodEnd: periodEndToIso(subscription.current_period_end),
          cancelAtPeriodEnd: Boolean(subscription.cancel_at_period_end),
          sourceEventType: event.type,
          latestPayload: {
            id: subscription.id,
            status: subscription.status,
            current_period_end: subscription.current_period_end ?? null,
            cancel_at_period_end: subscription.cancel_at_period_end ?? false,
            customer: resolvedCustomerId,
            price_id: extractPriceId(subscription),
          },
          priceId: extractPriceId(subscription),
        });
        attemptedSubscriptionWrite = true;

        if (resolvedUserId) {
          await setSubscribed({
            userId: resolvedUserId,
            isSubscribed: true,
            stripeCustomerId: resolvedCustomerId,
            stripeSubscriptionId: subscription.id,
          });
        } else {
          console.warn("[stripe][webhook] checkout.session.completed could not resolve user_id", {
            eventId: event.id,
            subscriptionId: subscription.id,
          });
        }

        console.info("[stripe][webhook] checkout.session.completed synced", {
          eventId: event.id,
          subscriptionId: subscription.id,
          hasUserId: Boolean(resolvedUserId),
        });

        break;
      }
      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const customerId = typeof subscription.customer === "string" ? subscription.customer : null;
        const userIdFromMetadata = String(subscription.metadata?.user_id ?? "").trim();
        const userIdFromSubId = await findUserIdBySubscriptionId(subscription.id);
        const userIdFromCustomer = customerId ? await findUserIdByCustomerId(customerId) : null;
        const resolvedUserId = userIdFromMetadata || userIdFromSubId || userIdFromCustomer;

        await upsertUserSubscription({
          userId: resolvedUserId || null,
          stripeCustomerId: customerId,
          stripeSubscriptionId: subscription.id,
          status: "canceled",
          currentPeriodEnd: periodEndToIso(subscription.current_period_end),
          cancelAtPeriodEnd: Boolean(subscription.cancel_at_period_end),
          sourceEventType: event.type,
          latestPayload: {
            id: subscription.id,
            status: subscription.status,
            current_period_end: subscription.current_period_end ?? null,
            cancel_at_period_end: subscription.cancel_at_period_end ?? false,
            customer: customerId,
            price_id: extractPriceId(subscription),
          },
          priceId: extractPriceId(subscription),
        });
        attemptedSubscriptionWrite = true;

        if (resolvedUserId) {
          await setSubscribed({
            userId: resolvedUserId,
            isSubscribed: false,
            stripeCustomerId: customerId,
            stripeSubscriptionId: subscription.id,
          });
        } else {
          console.warn("[stripe][webhook] customer.subscription.deleted could not resolve user_id", {
            eventId: event.id,
            subscriptionId: subscription.id,
          });
        }

        console.info("[stripe][webhook] customer.subscription.deleted synced", {
          eventId: event.id,
          subscriptionId: subscription.id,
          hasUserId: Boolean(resolvedUserId),
        });

        break;
      }
      case "customer.subscription.created":
      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const customerId = typeof subscription.customer === "string" ? subscription.customer : null;
        let userId = String(subscription.metadata?.user_id ?? "");
        if (!userId) {
          const mappedUserId = await findUserIdBySubscriptionId(subscription.id);
          if (mappedUserId) userId = mappedUserId;
        }
        if (!userId && customerId) {
          const mappedUserId = await findUserIdByCustomerId(customerId);
          if (mappedUserId) userId = mappedUserId;
        }

        await upsertUserSubscription({
          userId: userId || null,
          stripeCustomerId: customerId,
          stripeSubscriptionId: subscription.id,
          status: String(subscription.status ?? "unknown"),
          currentPeriodEnd: periodEndToIso(subscription.current_period_end),
          cancelAtPeriodEnd: Boolean(subscription.cancel_at_period_end),
          sourceEventType: event.type,
          latestPayload: {
            id: subscription.id,
            status: subscription.status,
            current_period_end: subscription.current_period_end ?? null,
            cancel_at_period_end: subscription.cancel_at_period_end ?? false,
            customer: customerId,
            price_id: extractPriceId(subscription),
          },
          priceId: extractPriceId(subscription),
        });
        attemptedSubscriptionWrite = true;

        if (userId) {
          await setSubscribed({
            userId,
            isSubscribed: asActive(subscription.status),
            stripeCustomerId: customerId,
            stripeSubscriptionId: subscription.id,
          });
        } else {
          console.warn("[stripe][webhook] customer.subscription.updated could not resolve user_id", {
            eventId: event.id,
            subscriptionId: subscription.id,
          });
        }

        console.info("[stripe][webhook] customer.subscription.created_or_updated synced", {
          eventId: event.id,
          type: event.type,
          subscriptionId: subscription.id,
          hasUserId: Boolean(userId),
          status: subscription.status,
        });

        break;
      }
      default:
        console.info("[stripe][webhook] Ignored event type", { eventId: event.id, type: event.type });
        break;
    }

    if (
      (event.type === "checkout.session.completed" ||
        event.type === "customer.subscription.created" ||
        event.type === "customer.subscription.updated" ||
        event.type === "customer.subscription.deleted") &&
      !attemptedSubscriptionWrite
    ) {
      throw new Error(`No subscription persistence attempted for ${event.type}`);
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
