type SupabaseLike = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: string) => {
        maybeSingle: () => Promise<{ data: Record<string, unknown> | null; error: { message: string } | null }>;
      };
    };
  };
};

export async function resolveIsSubscribed(supabase: SupabaseLike, userId: string) {
  const profilesResult = await supabase
    .from("profiles")
    .select("is_subscribed")
    .eq("user_id", userId)
    .maybeSingle();

  if (!profilesResult.error && profilesResult.data) {
    return profilesResult.data.is_subscribed === true;
  }

  const legacyResult = await supabase
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

