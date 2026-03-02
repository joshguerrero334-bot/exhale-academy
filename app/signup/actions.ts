"use server";

import { redirect } from "next/navigation";
import { createClient } from "../../lib/supabase/server";
import { assertRateLimit } from "../../lib/security/rate-limit";
import { isStrongPassword } from "../../lib/auth/password-policy";
import { getBaseUrl, getStripeClient, requireServerEnv } from "../../lib/stripe";

export async function signup(formData: FormData) {
  const firstName = String(formData.get("first_name") ?? "").trim();
  const lastName = String(formData.get("last_name") ?? "").trim();
  const email = String(formData.get("email") ?? "").trim();
  const password = String(formData.get("password") ?? "");

  const limit = await assertRateLimit({
    bucket: "signup",
    identifier: email || "anonymous",
    max: 5,
    windowMs: 60 * 60 * 1000,
  });
  if (!limit.ok) {
    redirect(`/signup?error=${encodeURIComponent(`Too many signup attempts. Try again in about ${limit.retryAfterSec} seconds.`)}`);
  }

  if (!firstName || !lastName || !email || !password) {
    redirect("/signup?error=First%20name,%20last%20name,%20email,%20and%20password%20are%20required");
  }

  if (!isStrongPassword(password)) {
    redirect("/signup?error=Password%20must%20be%20at%20least%208%20characters%20and%20include%201%20uppercase%20letter,%201%20number,%20and%201%20special%20character");
  }

  const baseUrl = getBaseUrl();
  const emailRedirectTo = `${baseUrl}/auth/callback?next=%2Fbilling`;

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo,
    },
  });

  if (error) {
    redirect(`/signup?error=${encodeURIComponent(error.message)}`);
  }

  if (data.user) {
    await supabase.from("profiles").upsert(
      {
        user_id: data.user.id,
        first_name: firstName,
        last_name: lastName,
        is_subscribed: false,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    );
  }

  if (data.session && data.user) {
    try {
      const env = requireServerEnv("signup-checkout-session", [
        "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY",
        "NEXT_PUBLIC_STRIPE_MONTHLY_PRICE_ID",
        "STRIPE_SECRET_KEY",
        "STRIPE_MONTHLY_PRICE_ID",
      ]);
      const stripe = getStripeClient("signup-checkout-session");
      const session = await stripe.checkout.sessions.create({
        mode: "subscription",
        line_items: [{ price: env.STRIPE_MONTHLY_PRICE_ID, quantity: 1 }],
        success_url: `${baseUrl}/dashboard?billing=success`,
        cancel_url: `${baseUrl}/billing?canceled=1`,
        customer_email: data.user.email ?? undefined,
        client_reference_id: data.user.id,
        subscription_data: {
          metadata: {
            user_id: data.user.id,
          },
        },
        metadata: {
          user_id: data.user.id,
        },
      });

      if (session.url) {
        redirect(session.url);
      }
    } catch (checkoutError) {
      console.error("[signup] Failed to start Stripe checkout after signup.", checkoutError);
      redirect("/billing?error=Could%20not%20start%20checkout.%20Please%20try%20again.");
    }
  }

  redirect("/login?message=Account%20created.%20Check%20your%20email%20to%20confirm,%20then%20you%E2%80%99ll%20continue%20to%20billing.&next=%2Fbilling");
}
