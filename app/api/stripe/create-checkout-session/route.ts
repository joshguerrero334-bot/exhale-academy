import { NextResponse } from "next/server";
import { createClient } from "../../../../lib/supabase/server";
import { getBaseUrl, getStripeClient, requireServerEnv } from "../../../../lib/stripe";

export async function POST(request: Request) {
  try {
    const env = requireServerEnv("create-checkout-session", [
      "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY",
      "NEXT_PUBLIC_STRIPE_MONTHLY_PRICE_ID",
      "STRIPE_SECRET_KEY",
      "STRIPE_MONTHLY_PRICE_ID",
    ]);

    const supabase = await createClient();
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser();

    if (userError || !user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const stripe = getStripeClient("create-checkout-session");
    const baseUrl = getBaseUrl(request);

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [
        {
          price: env.STRIPE_MONTHLY_PRICE_ID,
          quantity: 1,
        },
      ],
      success_url: `${baseUrl}/dashboard?billing=success`,
      cancel_url: `${baseUrl}/billing?canceled=1`,
      customer_email: user.email ?? undefined,
      client_reference_id: user.id,
      subscription_data: {
        metadata: {
          user_id: user.id,
        },
      },
      metadata: {
        user_id: user.id,
      },
    });

    if (!session.url) {
      console.error("[stripe][create-checkout-session] Checkout session missing redirect URL.");
      return NextResponse.json({ error: "Could not start checkout." }, { status: 500 });
    }

    return NextResponse.json({ url: session.url });
  } catch (error) {
    console.error("[stripe][create-checkout-session] Failed to create checkout session.", error);
    return NextResponse.json({ error: "Stripe checkout is temporarily unavailable." }, { status: 500 });
  }
}
