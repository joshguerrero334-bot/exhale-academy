import type { Metadata } from "next";
import Link from "next/link";
import { redirect } from "next/navigation";
import {
  activatePeerAccessTrial,
  isPeerAccessEmailAllowed,
  isPeerAccessLinkExpired,
  isPeerAccessTokenValid,
} from "../../lib/auth/free-access";
import { createClient } from "../../lib/supabase/server";

type FreeAccessPageProps = {
  searchParams: Promise<{ token?: string }>;
};

export const metadata: Metadata = {
  title: "Free Access | Exhale Academy",
  description: "Peer invite access redemption for Exhale Academy.",
};

export default async function FreeAccessPage({ searchParams }: FreeAccessPageProps) {
  const query = await searchParams;
  const token = String(query.token ?? "").trim();
  const now = new Date();
  if (isPeerAccessLinkExpired(now)) {
    return (
      <main className="page-shell">
        <div className="mx-auto w-full max-w-xl rounded-2xl border border-red-300 bg-red-50 p-6 text-red-700">
          <h1 className="text-xl font-semibold">Invalid access link</h1>
          <p className="mt-2 text-sm">This invite link has expired. Contact support if you expected access.</p>
        </div>
      </main>
    );
  }

  if (!isPeerAccessTokenValid(token)) {
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

  const userEmail = String(user.email ?? "").trim().toLowerCase();
  if (!isPeerAccessEmailAllowed(userEmail)) {
    return (
      <main className="page-shell">
        <div className="mx-auto w-full max-w-xl rounded-2xl border border-amber-300 bg-amber-50 p-6 text-amber-800">
          <h1 className="text-xl font-semibold">Not approved for this invite</h1>
          <p className="mt-2 text-sm">This free-access invite is restricted to a specific email list.</p>
        </div>
      </main>
    );
  }

  let trialDays = 7;
  let trialExpiresAtIso = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString();

  try {
    const activated = await activatePeerAccessTrial(user.id, now);
    trialDays = activated.trialDays;
    trialExpiresAtIso = activated.trialExpiresAtIso;
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
        <p className="mt-2 text-sm">
          Your account now has active access for {trialDays} days. Trial ends on{" "}
          {new Date(trialExpiresAtIso).toLocaleString()}.
        </p>
        <div className="mt-4">
          <Link href="/dashboard" className="btn-primary">
            Go to Dashboard
          </Link>
        </div>
      </div>
    </main>
  );
}
