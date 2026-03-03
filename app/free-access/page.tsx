import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import { createAdminClient } from "../../lib/supabase/admin";
import { createClient } from "../../lib/supabase/server";

type FreeAccessPageProps = {
  searchParams: Promise<{ token?: string }>;
};

export const metadata: Metadata = {
  title: "Free Access | Exhale Academy",
  description: "Peer invite access redemption for Exhale Academy.",
};

function parseAllowlist(raw: string) {
  return new Set(
    raw
      .split(",")
      .map((value) => value.trim().toLowerCase())
      .filter(Boolean)
  );
}

export default async function FreeAccessPage({ searchParams }: FreeAccessPageProps) {
  const query = await searchParams;
  const token = String(query.token ?? "").trim();
  const configuredToken = String(process.env.PEER_ACCESS_TOKEN ?? "").trim();

  if (!token || !configuredToken || token !== configuredToken) {
    return (
      <main className="page-shell">
        <div className="mx-auto w-full max-w-xl rounded-2xl border border-red-300 bg-red-50 p-6 text-red-700">
          <h1 className="text-xl font-semibold">Invalid access link</h1>
          <p className="mt-2 text-sm">This invite link is invalid or expired. Contact support if you expected access.</p>
        </div>
      </main>
    );
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect(`/login?next=${encodeURIComponent(`/free-access?token=${token}`)}`);
  }

  const allowlist = parseAllowlist(String(process.env.PEER_ACCESS_ALLOWLIST ?? ""));
  const userEmail = String(user.email ?? "").trim().toLowerCase();
  if (allowlist.size > 0 && !allowlist.has(userEmail)) {
    return (
      <main className="page-shell">
        <div className="mx-auto w-full max-w-xl rounded-2xl border border-amber-300 bg-amber-50 p-6 text-amber-800">
          <h1 className="text-xl font-semibold">Not approved for this invite</h1>
          <p className="mt-2 text-sm">This free-access invite is restricted to a specific email list.</p>
        </div>
      </main>
    );
  }

  const nowIso = new Date().toISOString();

  try {
    const admin = createAdminClient();

    const { error: profilesError } = await admin
      .from("profiles")
      .upsert(
        {
          user_id: user.id,
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
          id: user.id,
          subscription_status: "active",
          subscription_updated_at: nowIso,
          updated_at: nowIso,
        },
        { onConflict: "id" }
      );
    if (legacyError) throw new Error(legacyError.message);

    const { data: existingSub } = await admin
      .from("user_subscriptions")
      .select("id")
      .eq("user_id", user.id)
      .eq("source_event_type", "manual.peer_access")
      .order("updated_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingSub?.id) {
      const { error: updateSubError } = await admin
        .from("user_subscriptions")
        .update({
          status: "active",
          source_event_type: "manual.peer_access",
          latest_payload: { grant: "peer_access_qr", granted_at: nowIso },
          updated_at: nowIso,
        })
        .eq("id", existingSub.id);
      if (updateSubError) throw new Error(updateSubError.message);
    } else {
      const { error: insertSubError } = await admin.from("user_subscriptions").insert({
        user_id: user.id,
        status: "active",
        source_event_type: "manual.peer_access",
        latest_payload: { grant: "peer_access_qr", granted_at: nowIso },
        created_at: nowIso,
        updated_at: nowIso,
      });
      if (insertSubError) throw new Error(insertSubError.message);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : "Could not activate free access.";
    return (
      <main className="page-shell">
        <div className="mx-auto w-full max-w-xl rounded-2xl border border-red-300 bg-red-50 p-6 text-red-700">
          <h1 className="text-xl font-semibold">Activation failed</h1>
          <p className="mt-2 text-sm">{message}</p>
        </div>
      </main>
    );
  }

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-xl rounded-2xl border border-green-300 bg-green-50 p-6 text-green-800">
        <h1 className="text-xl font-semibold">Free access activated</h1>
        <p className="mt-2 text-sm">Your account now has active access. You can start practicing immediately.</p>
        <div className="mt-4">
          <Link href="/dashboard" className="btn-primary">
            Go to Dashboard
          </Link>
        </div>
      </div>
    </main>
  );
}
