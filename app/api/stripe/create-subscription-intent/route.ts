import { NextResponse } from "next/server";
import { createClient } from "../../../../lib/supabase/server";

type StripeFormValue = string | number | boolean | null | undefined;

type SubscriptionOnboardingPayload = {
  email?: string;
  phone_number?: string;
  date_of_birth?: string;
  graduation_date?: string;
  exam_date?: string;
  prior_attempt_count?: number | string;
  marketing_opt_in?: boolean;
};

function appendIfPresent(params: URLSearchParams, key: string, value: StripeFormValue) {
  if (value === null || value === undefined) return;
  const asString = String(value).trim();
  if (!asString) return;
  params.append(key, asString);
}

function normalizeDate(value: string | undefined) {
  const raw = String(value ?? "").trim();
  if (!raw) return null;
  const asDate = new Date(raw);
  if (Number.isNaN(asDate.getTime())) return null;
  return asDate.toISOString().slice(0, 10);
}

function normalizeCount(value: number | string | undefined) {
  const parsed = Number.parseInt(String(value ?? "").trim(), 10);
  if (Number.isNaN(parsed) || parsed < 0) return null;
  return parsed;
}

async function stripeFormRequest(path: string, body: URLSearchParams) {
  const stripeSecretKey = process.env.STRIPE_SECRET_KEY?.trim();
  if (!stripeSecretKey) {
    throw new Error("Missing STRIPE_SECRET_KEY");
  }

  const response = await fetch(`https://api.stripe.com${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${stripeSecretKey}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
    cache: "no-store",
  });

  const payload = (await response.json()) as Record<string, unknown>;
  if (!response.ok) {
    const message =
      typeof payload.error === "object" && payload.error && "message" in payload.error
        ? String((payload.error as { message?: string }).message ?? "Stripe request failed")
        : "Stripe request failed";
    throw new Error(message);
  }
  return payload;
}

export async function POST(request: Request) {
  try {
    const publishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY?.trim();
    const monthlyPriceId = process.env.STRIPE_PRICE_MONTHLY_ID?.trim();
    if (!publishableKey || !monthlyPriceId) {
      return NextResponse.json(
        { error: "Stripe is not configured. Missing publishable key or monthly price id." },
        { status: 500 }
      );
    }

    const payload = (await request.json().catch(() => ({}))) as SubscriptionOnboardingPayload;
    const onboardingEmail = String(payload.email ?? "").trim().toLowerCase();
    const phoneNumber = String(payload.phone_number ?? "").trim();
    const dateOfBirth = normalizeDate(payload.date_of_birth);
    const graduationDate = normalizeDate(payload.graduation_date);
    const examDate = normalizeDate(payload.exam_date);
    const priorAttemptCount = normalizeCount(payload.prior_attempt_count);
    const marketingOptIn = payload.marketing_opt_in === true;

    const supabase = await createClient();
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    if (!onboardingEmail) {
      return NextResponse.json({ error: "Email is required." }, { status: 400 });
    }

    let stripeCustomerId: string | null = null;
    const profileResult = await supabase
      .from("user_profiles")
      .select("stripe_customer_id, subscription_status")
      .eq("id", user.id)
      .maybeSingle();

    if (!profileResult.error && profileResult.data) {
      stripeCustomerId = (profileResult.data.stripe_customer_id as string | null) ?? null;
      const status = String(profileResult.data.subscription_status ?? "").toLowerCase();
      if (status === "active" || status === "trialing") {
        return NextResponse.json({ error: "You already have an active subscription." }, { status: 409 });
      }
    }

    if (!stripeCustomerId) {
      const customerBody = new URLSearchParams();
      appendIfPresent(customerBody, "email", onboardingEmail || (user.email ?? null));
      appendIfPresent(customerBody, "metadata[user_id]", user.id);
      appendIfPresent(customerBody, "metadata[date_of_birth]", dateOfBirth);
      appendIfPresent(customerBody, "metadata[exam_date]", examDate);
      appendIfPresent(customerBody, "metadata[graduation_date]", graduationDate);
      appendIfPresent(customerBody, "metadata[prior_attempt_count]", priorAttemptCount);
      const customer = await stripeFormRequest("/v1/customers", customerBody);
      stripeCustomerId = String(customer.id ?? "");
      if (!stripeCustomerId) {
        throw new Error("Could not create Stripe customer.");
      }
    }

    const upsertProfile = await supabase.from("user_profiles").upsert(
      {
        id: user.id,
        contact_email: onboardingEmail,
        phone_number: phoneNumber || null,
        date_of_birth: dateOfBirth,
        graduation_date: graduationDate,
        exam_date: examDate,
        prior_attempt_count: priorAttemptCount,
        stripe_customer_id: stripeCustomerId,
        subscription_updated_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      },
      { onConflict: "id" }
    );

    if (upsertProfile.error) {
      return NextResponse.json({ error: `Profile save failed: ${upsertProfile.error.message}` }, { status: 500 });
    }

    const upsertMarketing = await supabase.from("marketing_contacts").upsert(
      {
        user_id: user.id,
        email: onboardingEmail,
        phone_number: phoneNumber || null,
        date_of_birth: dateOfBirth,
        graduation_date: graduationDate,
        exam_date: examDate,
        prior_attempt_count: priorAttemptCount,
        marketing_opt_in: marketingOptIn,
        source: "subscription_checkout",
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );

    if (upsertMarketing.error) {
      return NextResponse.json({ error: `Marketing save failed: ${upsertMarketing.error.message}` }, { status: 500 });
    }

    const subscriptionBody = new URLSearchParams();
    appendIfPresent(subscriptionBody, "customer", stripeCustomerId);
    appendIfPresent(subscriptionBody, "items[0][price]", monthlyPriceId);
    appendIfPresent(subscriptionBody, "payment_behavior", "default_incomplete");
    appendIfPresent(subscriptionBody, "payment_settings[save_default_payment_method]", "on_subscription");
    appendIfPresent(subscriptionBody, "metadata[user_id]", user.id);
    appendIfPresent(subscriptionBody, "metadata[contact_email]", onboardingEmail);
    appendIfPresent(subscriptionBody, "metadata[date_of_birth]", dateOfBirth);
    appendIfPresent(subscriptionBody, "metadata[exam_date]", examDate);
    appendIfPresent(subscriptionBody, "metadata[graduation_date]", graduationDate);
    appendIfPresent(subscriptionBody, "metadata[prior_attempt_count]", priorAttemptCount);
    appendIfPresent(subscriptionBody, "metadata[marketing_opt_in]", marketingOptIn);
    appendIfPresent(subscriptionBody, "expand[]", "latest_invoice.payment_intent");
    appendIfPresent(subscriptionBody, "expand[]", "pending_setup_intent");

    const subscription = await stripeFormRequest("/v1/subscriptions", subscriptionBody);
    const latestInvoice = (subscription.latest_invoice ?? {}) as Record<string, unknown>;
    const paymentIntent = (latestInvoice.payment_intent ?? {}) as Record<string, unknown>;
    const setupIntent = (subscription.pending_setup_intent ?? {}) as Record<string, unknown>;

    let clientSecret = String(paymentIntent.client_secret ?? "");
    if (!clientSecret) {
      clientSecret = String(setupIntent.client_secret ?? "");
    }

    if (!clientSecret) {
      const latestInvoiceMaybeConfirmationSecret =
        latestInvoice && typeof latestInvoice.confirmation_secret === "string"
          ? String(latestInvoice.confirmation_secret)
          : "";
      if (latestInvoiceMaybeConfirmationSecret) {
        clientSecret = latestInvoiceMaybeConfirmationSecret;
      }
    }

    if (!clientSecret) {
      throw new Error(
        "Could not initialize payment intent for subscription. Confirm Stripe price/key mode alignment and subscription payment settings."
      );
    }

    return NextResponse.json({
      publishableKey,
      clientSecret,
      subscriptionId: String(subscription.id ?? ""),
      customerId: stripeCustomerId,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not create subscription intent.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
