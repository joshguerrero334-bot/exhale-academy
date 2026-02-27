type MinimalSupabaseClient = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: string) => {
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

  if (!profilesResult.error && profilesResult.data) {
    return profilesResult.data.is_subscribed === true;
  }

  const legacyResult = await client
    .from("user_profiles")
    .select("subscription_status")
    .eq("id", userId)
    .maybeSingle();

  if (!legacyResult.error && legacyResult.data) {
    const status = String(legacyResult.data.subscription_status ?? "").toLowerCase();
    return status === "active" || status === "trialing";
  }

  return false;
}
