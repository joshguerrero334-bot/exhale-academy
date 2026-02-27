"use client";

import { useState } from "react";

export default function RefreshAccessButton() {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function refreshAccess() {
    setLoading(true);
    setError(null);
    setMessage(null);
    try {
      const response = await fetch("/api/stripe/sync-subscription-status", {
        method: "POST",
      });
      const payload = (await response.json().catch(() => ({}))) as {
        isSubscribed?: boolean;
        error?: string;
      };

      if (!response.ok) {
        throw new Error(payload.error ?? "Could not sync subscription status.");
      }

      if (payload.isSubscribed) {
        setMessage("Subscription confirmed. Redirecting to dashboard...");
        window.location.assign("/dashboard");
        return;
      }

      setMessage("No active subscription found yet. If you just paid, wait 10-20 seconds and try again.");
    } catch (err) {
      const text = err instanceof Error ? err.message : "Sync failed.";
      setError(text);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-2">
      <button type="button" className="btn-secondary" disabled={loading} onClick={refreshAccess}>
        {loading ? "Checking..." : "I've paid, refresh access"}
      </button>
      {message ? <p className="text-sm text-graysoft">{message}</p> : null}
      {error ? <p className="text-sm text-red-700">{error}</p> : null}
    </div>
  );
}

