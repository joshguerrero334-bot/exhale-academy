import { NextResponse } from "next/server";
import { createAdminClient } from "../../../../lib/supabase/admin";
import { createClient } from "../../../../lib/supabase/server";
import { getBaseUrl, getStripeClient, requireServerEnv } from "../../../../lib/stripe";

async function getStoredStripeCustomerId(userId: string) {
  const admin = createAdminClient();

  const fromProfiles = await admin
    .from("profiles")
    .select("stripe_customer_id")
    .eq("user_id", userId)
    .maybeSingle();
  if (!fromProfiles.error && fromProfiles.data?.stripe_customer_id) {
    return String(fromProfiles.data.stripe_customer_id);
  }

  const fromLegacy = await admin
    .from("user_profiles")
    .select("stripe_customer_id")
    .eq("id", userId)
    .maybeSingle();
  if (!fromLegacy.error && fromLegacy.data?.stripe_customer_id) {
    return String(fromLegacy.data.stripe_customer_id);
  }

  return null;
}

export async function POST(request: Request) {
  try {
    requireServerEnv("create-portal-session", [
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

    const stripe = getStripeClient("create-portal-session");
    let customerId = await getStoredStripeCustomerId(user.id);

    if (!customerId) {
      const email = String(user.email ?? "").trim().toLowerCase();
      if (!email) {
        return NextResponse.json({ error: "No email found for account." }, { status: 400 });
      }
      const customers = await stripe.customers.list({ email, limit: 1 });
      customerId = customers.data[0]?.id ?? null;
    }

    if (!customerId) {
      return NextResponse.json(
        {
          error: "No Stripe customer record found yet. Start a subscription first.",
        },
        { status: 404 }
      );
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${getBaseUrl(request)}/account`,
    });

    if (!session.url) {
      return NextResponse.json({ error: "Could not open billing portal." }, { status: 500 });
    }

    return NextResponse.json({ url: session.url });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not create billing portal session.";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
