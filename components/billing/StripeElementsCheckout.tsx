"use client";

import Script from "next/script";
import { useCallback, useMemo, useRef, useState } from "react";

type InitResponse = {
  publishableKey: string;
  clientSecret: string;
  error?: string;
};

type CheckoutProfile = {
  email: string;
  phone_number: string;
  date_of_birth: string;
  graduation_date: string;
  exam_date: string;
  prior_attempt_count: string;
  marketing_opt_in: boolean;
};

type StripeLike = {
  elements: (options: { clientSecret: string; appearance?: Record<string, unknown> }) => {
    create: (type: string, options?: Record<string, unknown>) => { mount: (selector: string) => void };
  };
  confirmPayment: (options: {
    elements: unknown;
    confirmParams: { return_url: string };
    redirect: "if_required";
  }) => Promise<{ error?: { message?: string } }>;
};

declare global {
  interface Window {
    Stripe?: (publishableKey: string) => StripeLike;
  }
}

type StripeElementsCheckoutProps = {
  defaultEmail?: string | null;
};

export default function StripeElementsCheckout({ defaultEmail }: StripeElementsCheckoutProps) {
  const [scriptReady, setScriptReady] = useState(false);
  const [loading, setLoading] = useState(false);
  const [initializing, setInitializing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [isInitialized, setIsInitialized] = useState(false);
  const [profile, setProfile] = useState<CheckoutProfile>({
    email: defaultEmail ?? "",
    phone_number: "",
    date_of_birth: "",
    graduation_date: "",
    exam_date: "",
    prior_attempt_count: "0",
    marketing_opt_in: false,
  });

  const stripeRef = useRef<StripeLike | null>(null);
  const elementsRef = useRef<unknown>(null);

  const canInitialize = useMemo(() => scriptReady && !initializing && !isInitialized, [scriptReady, initializing, isInitialized]);

  const canSubmitProfile = useMemo(() => {
    const hasEmail = profile.email.trim().length > 0;
    const hasPhone = profile.phone_number.trim().length > 0;
    const hasDob = profile.date_of_birth.trim().length > 0;
    const hasGradDate = profile.graduation_date.trim().length > 0;
    const hasExamDate = profile.exam_date.trim().length > 0;
    const hasAttempts = profile.prior_attempt_count.trim().length > 0;
    return hasEmail && hasPhone && hasDob && hasGradDate && hasExamDate && hasAttempts;
  }, [profile]);

  const initialize = useCallback(async () => {
    setError(null);
    setSuccess(null);
    if (!canSubmitProfile) {
      setError("Please complete all required account fields before starting checkout.");
      return;
    }
    setInitializing(true);

    try {
      const response = await fetch("/api/stripe/create-subscription-intent", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(profile),
      });
      const payload = (await response.json()) as InitResponse;

      if (!response.ok || payload.error) {
        throw new Error(payload.error ?? "Could not initialize secure payment.");
      }

      if (!window.Stripe) {
        throw new Error("Stripe.js failed to load.");
      }

      const stripe = window.Stripe(payload.publishableKey);
      if (!stripe) {
        throw new Error("Could not initialize Stripe.");
      }

      const elements = stripe.elements({
        clientSecret: payload.clientSecret,
        appearance: { theme: "stripe" },
      });

      const paymentElement = elements.create("payment", {
        layout: "tabs",
      });
      paymentElement.mount("#payment-element");

      stripeRef.current = stripe;
      elementsRef.current = elements;
      setIsInitialized(true);
    } catch (initError) {
      const message = initError instanceof Error ? initError.message : "Initialization failed.";
      setError(message);
    } finally {
      setInitializing(false);
    }
  }, [canSubmitProfile, profile]);

  const handleSubmit = useCallback(async () => {
    setError(null);
    setSuccess(null);
    const stripe = stripeRef.current;
    const elements = elementsRef.current;
    if (!stripe || !elements) {
      setError("Payment form is not ready yet.");
      return;
    }

    setLoading(true);
    try {
      const returnUrl = `${window.location.origin}/account?billing=success`;
      const result = await stripe.confirmPayment({
        elements,
        confirmParams: { return_url: returnUrl },
        redirect: "if_required",
      });
      if (result.error) {
        throw new Error(result.error.message ?? "Payment confirmation failed.");
      }

      setSuccess("Payment method accepted. Your subscription will activate in a few seconds.");
      window.location.assign("/account?billing=success");
    } catch (submitError) {
      const message = submitError instanceof Error ? submitError.message : "Payment failed.";
      setError(message);
    } finally {
      setLoading(false);
    }
  }, []);

  return (
    <div className="space-y-4">
      <Script src="https://js.stripe.com/v3/" strategy="afterInteractive" onLoad={() => setScriptReady(true)} />

      <div className="grid gap-3 sm:grid-cols-2">
        <label className="space-y-1 text-sm">
          <span className="font-semibold text-charcoal">Email</span>
          <input
            type="email"
            required
            value={profile.email}
            onChange={(e) => setProfile((prev) => ({ ...prev, email: e.target.value }))}
            className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <label className="space-y-1 text-sm">
          <span className="font-semibold text-charcoal">Phone Number</span>
          <input
            type="tel"
            required
            value={profile.phone_number}
            onChange={(e) => setProfile((prev) => ({ ...prev, phone_number: e.target.value }))}
            className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <label className="space-y-1 text-sm">
          <span className="font-semibold text-charcoal">Graduation Date</span>
          <input
            type="date"
            required
            value={profile.graduation_date}
            onChange={(e) => setProfile((prev) => ({ ...prev, graduation_date: e.target.value }))}
            className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <label className="space-y-1 text-sm">
          <span className="font-semibold text-charcoal">Date of Birth</span>
          <input
            type="date"
            required
            value={profile.date_of_birth}
            onChange={(e) => setProfile((prev) => ({ ...prev, date_of_birth: e.target.value }))}
            className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <label className="space-y-1 text-sm">
          <span className="font-semibold text-charcoal">Exam Date</span>
          <input
            type="date"
            required
            value={profile.exam_date}
            onChange={(e) => setProfile((prev) => ({ ...prev, exam_date: e.target.value }))}
            className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <label className="space-y-1 text-sm sm:col-span-2">
          <span className="font-semibold text-charcoal">How many times have you taken this test?</span>
          <input
            type="number"
            min={0}
            required
            value={profile.prior_attempt_count}
            onChange={(e) => setProfile((prev) => ({ ...prev, prior_attempt_count: e.target.value }))}
            className="w-full rounded-lg border border-graysoft/40 bg-white px-3 py-2 text-sm text-charcoal outline-none focus:border-primary focus:ring-2 focus:ring-primary/20"
          />
        </label>

        <label className="flex items-start gap-2 text-sm sm:col-span-2">
          <input
            type="checkbox"
            checked={profile.marketing_opt_in}
            onChange={(e) => setProfile((prev) => ({ ...prev, marketing_opt_in: e.target.checked }))}
            className="mt-1 h-4 w-4 accent-primary"
          />
          <span className="text-graysoft">
            Yes, I want Exhale Academy updates, product announcements, and study tips by email/SMS.
          </span>
        </label>
      </div>

      {!isInitialized ? (
        <button type="button" className="btn-primary" disabled={!canInitialize || !canSubmitProfile} onClick={initialize}>
          {initializing ? "Initializing secure checkout..." : "Start Secure Checkout"}
        </button>
      ) : null}

      <div id="payment-element" className={isInitialized ? "block" : "hidden"} />

      {isInitialized ? (
        <button type="button" className="btn-primary" disabled={loading} onClick={handleSubmit}>
          {loading ? "Processing..." : "Pay and Subscribe"}
        </button>
      ) : null}

      {error ? <p className="text-sm text-red-700">{error}</p> : null}
      {success ? <p className="text-sm text-green-700">{success}</p> : null}
    </div>
  );
}
