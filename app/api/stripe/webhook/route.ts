import { NextResponse } from "next/server";
import { verifyStripeWebhookSignature } from "../../../../lib/security/stripe-webhook";
import { createAdminClient } from "../../../../lib/supabase/admin";

type StripeEvent = {
  id: string;
  type: string;
  data?: {
    object?: Record<string, unknown>;
  };
};

export const runtime = "nodejs";

function asString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value : null;
}

function asBool(value: unknown): boolean | null {
  return typeof value === "boolean" ? value : null;
}

function asNumber(value: unknown): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function toIsoFromEpochSeconds(value: unknown): string | null {
  const seconds = asNumber(value);
  if (!seconds || seconds <= 0) return null;
  return new Date(seconds * 1000).toISOString();
}

function extractPriceId(subscriptionObject: Record<string, unknown>): string | null {
  const items = subscriptionObject.items as { data?: Array<{ price?: { id?: string } }> } | undefined;
  const first = items?.data?.[0];
  return asString(first?.price?.id ?? null);
}

function extractUserIdCandidates(object: Record<string, unknown>) {
  const metadata = (object.metadata as Record<string, unknown> | undefined) ?? {};
  const fromMetadata = asString(metadata.user_id ?? null);
  const fromClientReference = asString(object.client_reference_id ?? null);
  return [fromMetadata, fromClientReference].filter(Boolean) as string[];
}

async function resolveUserId(args: {
  admin: ReturnType<typeof createAdminClient>;
  object: Record<string, unknown>;
  customerId: string | null;
  subscriptionId: string | null;
}) {
  for (const candidate of extractUserIdCandidates(args.object)) {
    const { data, error } = await args.admin.auth.admin.getUserById(candidate);
    if (!error && data.user) return data.user.id;
  }

  if (args.subscriptionId) {
    const { data } = await args.admin
      .from("user_subscriptions")
      .select("user_id")
      .eq("stripe_subscription_id", args.subscriptionId)
      .maybeSingle();
    if (data?.user_id) return data.user_id as string;
  }

  if (args.customerId) {
    const { data } = await args.admin
      .from("user_profiles")
      .select("id")
      .eq("stripe_customer_id", args.customerId)
      .maybeSingle();
    if (data?.id) return data.id as string;

    const { data: sub } = await args.admin
      .from("user_subscriptions")
      .select("user_id")
      .eq("stripe_customer_id", args.customerId)
      .not("user_id", "is", null)
      .order("updated_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (sub?.user_id) return sub.user_id as string;
  }

  return null;
}

async function upsertSubscription(args: {
  admin: ReturnType<typeof createAdminClient>;
  eventType: string;
  object: Record<string, unknown>;
}) {
  const customerId = asString(args.object.customer ?? null);
  const subscriptionId =
    asString(args.object.id ?? null) || asString(args.object.subscription ?? null);
  const status = asString(args.object.status ?? null) ?? "unknown";
  const priceId = extractPriceId(args.object);
  const currentPeriodEnd =
    toIsoFromEpochSeconds(args.object.current_period_end) ??
    toIsoFromEpochSeconds(args.object.period_end);
  const cancelAtPeriodEnd = asBool(args.object.cancel_at_period_end) ?? false;

  if (!customerId && !subscriptionId) {
    return;
  }

  const userId = await resolveUserId({
    admin: args.admin,
    object: args.object,
    customerId,
    subscriptionId,
  });

  const payload = {
    user_id: userId,
    stripe_customer_id: customerId,
    stripe_subscription_id: subscriptionId,
    status,
    price_id: priceId,
    current_period_end: currentPeriodEnd,
    cancel_at_period_end: cancelAtPeriodEnd,
    source_event_type: args.eventType,
    latest_payload: args.object,
    updated_at: new Date().toISOString(),
  };

  const { error: subError } = await args.admin
    .from("user_subscriptions")
    .upsert(payload, { onConflict: "stripe_subscription_id" });

  if (subError) {
    throw new Error(`Subscription sync failed: ${subError.message}`);
  }

  if (userId) {
    const profilePayload = {
      id: userId,
      stripe_customer_id: customerId,
      stripe_subscription_id: subscriptionId,
      subscription_status: status,
      subscription_current_period_end: currentPeriodEnd,
      subscription_cancel_at_period_end: cancelAtPeriodEnd,
      subscription_updated_at: new Date().toISOString(),
    };

    const { error: profileError } = await args.admin
      .from("user_profiles")
      .upsert(profilePayload, { onConflict: "id" });

    if (profileError) {
      throw new Error(`Profile sync failed: ${profileError.message}`);
    }
  }
}

export async function POST(request: Request) {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET?.trim();
  if (!webhookSecret) {
    return NextResponse.json({ error: "Webhook not configured." }, { status: 500 });
  }

  const rawBody = await request.text();
  const signatureHeader = request.headers.get("stripe-signature");
  const verified = verifyStripeWebhookSignature({
    rawBody,
    stripeSignatureHeader: signatureHeader,
    webhookSecret,
    toleranceSec: 300,
  });

  if (!verified.ok) {
    return NextResponse.json({ error: verified.reason }, { status: 400 });
  }

  let event: StripeEvent;
  try {
    event = JSON.parse(rawBody) as StripeEvent;
  } catch {
    return NextResponse.json({ error: "Invalid webhook body." }, { status: 400 });
  }

  if (!event.id || !event.type) {
    return NextResponse.json({ error: "Malformed event payload." }, { status: 400 });
  }

  const admin = createAdminClient();
  const nowIso = new Date().toISOString();
  const { data: insertedEvent, error: eventInsertError } = await admin
    .from("stripe_webhook_events")
    .insert({
      stripe_event_id: event.id,
      event_type: event.type,
      received_at: nowIso,
      payload: event as unknown as Record<string, unknown>,
    })
    .select("stripe_event_id")
    .maybeSingle();

  if (eventInsertError) {
    if (eventInsertError.code === "23505") {
      return NextResponse.json({ received: true, duplicate: true });
    }
    return NextResponse.json({ error: `Webhook storage failed: ${eventInsertError.message}` }, { status: 500 });
  }

  if (!insertedEvent) {
    return NextResponse.json({ received: true, duplicate: true });
  }

  const object = (event.data?.object ?? {}) as Record<string, unknown>;

  try {
    switch (event.type) {
      case "checkout.session.completed":
      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted":
      case "invoice.payment_succeeded":
      case "invoice.payment_failed":
        await upsertSubscription({ admin, eventType: event.type, object });
        break;
      default:
        break;
    }
  } catch (syncError) {
    const message = syncError instanceof Error ? syncError.message : "Unknown sync error.";
    return NextResponse.json({ error: message }, { status: 500 });
  }

  return NextResponse.json({ received: true });
}
