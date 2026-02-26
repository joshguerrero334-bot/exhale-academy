import { NextResponse } from "next/server";
import { isAdminUser } from "../../../../lib/auth/admin";
import { createClient } from "../../../../lib/supabase/server";

function detectMode(value: string | undefined) {
  const v = String(value ?? "").trim();
  if (!v) return "missing";
  if (v.startsWith("pk_test_") || v.startsWith("sk_test_") || v.startsWith("price_")) return "test_or_unknown";
  if (v.startsWith("pk_live_") || v.startsWith("sk_live_")) return "live";
  return "unknown";
}

function summarize(value: string | undefined) {
  const v = String(value ?? "").trim();
  if (!v) return { present: false, length: 0 };
  return { present: true, length: v.length };
}

export async function GET() {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!isAdminUser({ id: user.id, email: user.email ?? null })) {
    return NextResponse.json({ error: "Admin only" }, { status: 403 });
  }

  const publishable = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;
  const secret = process.env.STRIPE_SECRET_KEY;
  const priceMonthly = process.env.STRIPE_PRICE_MONTHLY_ID;
  const webhook = process.env.STRIPE_WEBHOOK_SECRET;

  const publishableMode = detectMode(publishable);
  const secretMode = detectMode(secret);

  return NextResponse.json({
    ok: true,
    user: {
      email: user.email,
      isAdmin: true,
    },
    stripe: {
      publishable: {
        ...summarize(publishable),
        mode: publishableMode,
      },
      secret: {
        ...summarize(secret),
        mode: secretMode,
      },
      priceMonthly: {
        ...summarize(priceMonthly),
        startsWithPrice: String(priceMonthly ?? "").startsWith("price_"),
      },
      webhook: summarize(webhook),
      modeAligned:
        publishableMode !== "missing" &&
        secretMode !== "missing" &&
        ((publishableMode === "live" && secretMode === "live") ||
          (publishableMode === "test_or_unknown" && secretMode === "test_or_unknown")),
    },
    hint:
      "No secret values are returned. Confirm all required keys are present, modeAligned=true, and redeploy after env changes.",
  });
}
