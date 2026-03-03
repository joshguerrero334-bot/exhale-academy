type MinimalSupabaseClient = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: string) => {
        eq: (column: string, value: string) => {
          order: (column: string, options: { ascending: boolean }) => {
            limit: (count: number) => {
              maybeSingle: () => PromiseLike<{ data: Record<string, unknown> | null; error: unknown }>;
            };
          };
          maybeSingle: () => PromiseLike<{ data: Record<string, unknown> | null; error: unknown }>;
        };
        maybeSingle: () => PromiseLike<{ data: Record<string, unknown> | null; error: unknown }>;
      };
    };
  };
};

export async function resolveIsSubscribed(supabase: unknown, userId: string) {
  const client = supabase as MinimalSupabaseClient;
  const profilesResult = await client
    .from("profiles")
    .select("is_subscribed")
    .eq("user_id", userId)
    .maybeSingle();
  const profileIsSubscribed = !profilesResult.error && profilesResult.data?.is_subscribed === true;

  const legacyResult = await client
    .from("user_profiles")
    .select("subscription_status, stripe_subscription_id")
    .eq("id", userId)
    .maybeSingle();

  const trialResult = await client
    .from("user_subscriptions")
    .select("current_period_end, source_event_type, status")
    .eq("user_id", userId)
    .eq("source_event_type", "manual.peer_access")
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  const legacyStatus = String(legacyResult.data?.subscription_status ?? "").toLowerCase();
  const legacyHasStripeSub = String(legacyResult.data?.stripe_subscription_id ?? "").trim().length > 0;
  const legacyIsActive = legacyStatus === "active" || legacyStatus === "trialing";

  if (!trialResult.error && trialResult.data) {
    const trialStatus = String(trialResult.data.status ?? "").toLowerCase();
    const trialEndRaw = String(trialResult.data.current_period_end ?? "").trim();
    const trialEndMs = trialEndRaw ? new Date(trialEndRaw).getTime() : Number.NaN;
    const isTrialActive = trialStatus === "active" && Number.isFinite(trialEndMs) && trialEndMs > Date.now();

    if (isTrialActive) {
      return true;
    }
    if (legacyIsActive && legacyHasStripeSub) {
      return true;
    }
    return false;
  }

  if (profileIsSubscribed) {
    return true;
  }

  if (!legacyResult.error && legacyResult.data) {
    return legacyIsActive;
  }

  return false;
}
