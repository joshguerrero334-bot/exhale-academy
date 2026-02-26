type SubscriptionStatus = string | null | undefined;

export function hasActiveSubscription(status: SubscriptionStatus) {
  const normalized = String(status ?? "").trim().toLowerCase();
  return normalized === "active" || normalized === "trialing";
}
