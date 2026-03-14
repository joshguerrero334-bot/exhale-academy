import { createAdminClient } from "../supabase/admin";

function parseAllowlist(raw: string) {
  return new Set(
    raw
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean)
  );
}

export function isPeerAccessTokenValid(token: string) {
  const provided = String(token ?? "").trim();
  const configured = String(process.env.PEER_ACCESS_TOKEN ?? "").trim();
  return Boolean(provided && configured && provided === configured);
}

export function isPeerAccessLinkExpired(now = new Date()) {
  const raw = String(process.env.PEER_ACCESS_LINK_EXPIRES_AT ?? "").trim();
  if (!raw) return false;
  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return false;
  return now.getTime() > parsed.getTime();
}

export function isPeerAccessEmailAllowed(email: string) {
  const allowlist = parseAllowlist(String(process.env.PEER_ACCESS_ALLOWLIST ?? ""));
  if (allowlist.size === 0) return true;
  return allowlist.has(String(email ?? "").trim().toLowerCase());
}

export async function activatePeerAccessTrial(userId: string, now = new Date()) {
  const admin = createAdminClient();
  const nowIso = now.toISOString();
  const trialDaysRaw = Number(process.env.FREE_ACCESS_TRIAL_DAYS ?? "7");
  const trialDays = Number.isFinite(trialDaysRaw) && trialDaysRaw > 0 ? Math.floor(trialDaysRaw) : 7;
  const trialExpiresAt = new Date(now.getTime() + trialDays * 24 * 60 * 60 * 1000);
  const trialExpiresAtIso = trialExpiresAt.toISOString();

  const { error: profilesError } = await admin
    .from("profiles")
    .upsert(
      {
        user_id: userId,
        is_subscribed: true,
        updated_at: nowIso,
      },
      { onConflict: "user_id" }
    );
  if (profilesError) throw new Error(profilesError.message);

  const { error: legacyError } = await admin
    .from("user_profiles")
    .upsert(
      {
        id: userId,
        subscription_status: "active",
        subscription_current_period_end: trialExpiresAtIso,
        subscription_cancel_at_period_end: true,
        subscription_updated_at: nowIso,
        updated_at: nowIso,
      },
      { onConflict: "id" }
    );
  if (legacyError) throw new Error(legacyError.message);

  const { data: existingSub } = await admin
    .from("user_subscriptions")
    .select("id")
    .eq("user_id", userId)
    .eq("source_event_type", "manual.peer_access")
    .order("updated_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (existingSub?.id) {
    const { error: updateSubError } = await admin
      .from("user_subscriptions")
      .update({
        status: "active",
        current_period_end: trialExpiresAtIso,
        cancel_at_period_end: true,
        source_event_type: "manual.peer_access",
        latest_payload: { grant: "peer_access_qr", granted_at: nowIso, trial_expires_at: trialExpiresAtIso },
        updated_at: nowIso,
      })
      .eq("id", existingSub.id);
    if (updateSubError) throw new Error(updateSubError.message);
  } else {
    const { error: insertSubError } = await admin.from("user_subscriptions").insert({
      user_id: userId,
      status: "active",
      current_period_end: trialExpiresAtIso,
      cancel_at_period_end: true,
      source_event_type: "manual.peer_access",
      latest_payload: { grant: "peer_access_qr", granted_at: nowIso, trial_expires_at: trialExpiresAtIso },
      created_at: nowIso,
      updated_at: nowIso,
    });
    if (insertSubError) throw new Error(insertSubError.message);
  }

  return {
    trialDays,
    trialExpiresAtIso,
  };
}
