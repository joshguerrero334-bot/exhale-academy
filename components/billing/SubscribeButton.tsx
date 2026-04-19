"use client";

import { useCallback, useEffect, useRef, useState } from "react";

type SubscribeButtonProps = {
  className?: string;
  label?: string;
  autoStart?: boolean;
};

export default function SubscribeButton({
  className = "btn-primary",
  label = "Subscribe",
  autoStart = false,
}: SubscribeButtonProps) {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const didAutoStart = useRef(false);

  const onSubscribe = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch("/api/stripe/create-checkout-session", {
        method: "POST",
      });
      const payload = (await response.json().catch(() => ({}))) as { url?: string; error?: string };
      if (!response.ok || !payload.url) {
        throw new Error(payload.error ?? "Could not start subscription checkout.");
      }
      window.location.assign(payload.url);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Could not start checkout.";
      setError(message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!autoStart || didAutoStart.current) return;
    didAutoStart.current = true;
    void onSubscribe();
  }, [autoStart, onSubscribe]);

  return (
    <div className="space-y-2">
      <button type="button" className={className} disabled={loading} onClick={onSubscribe}>
        {loading ? "Redirecting..." : label}
      </button>
      {error ? <p className="text-sm text-red-700">{error}</p> : null}
    </div>
  );
}
