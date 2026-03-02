"use client";

import { useState } from "react";

type ManageBillingButtonProps = {
  className?: string;
};

export default function ManageBillingButton({ className = "btn-secondary" }: ManageBillingButtonProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onManageBilling() {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch("/api/stripe/create-portal-session", {
        method: "POST",
      });
      const payload = (await response.json().catch(() => ({}))) as {
        url?: string;
        error?: string;
      };
      if (!response.ok || !payload.url) {
        throw new Error(payload.error ?? "Could not open billing portal.");
      }
      window.location.assign(payload.url);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Could not open billing portal.";
      setError(message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-2">
      <button type="button" className={className} disabled={loading} onClick={onManageBilling}>
        {loading ? "Opening..." : "Manage Payment Methods & Invoices"}
      </button>
      {error ? <p className="text-sm text-red-700">{error}</p> : null}
    </div>
  );
}
