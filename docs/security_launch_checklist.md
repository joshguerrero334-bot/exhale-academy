## Exhale Security Launch Checklist

### Implemented in app code
- Security headers via `/Users/joshguerrero/exhale-academy/next.config.ts`
  - Content-Security-Policy
  - Strict-Transport-Security
  - X-Frame-Options
  - X-Content-Type-Options
  - Referrer-Policy
  - Permissions-Policy
  - Cross-Origin-Opener-Policy
- Server-side rate limiting added to:
  - `/Users/joshguerrero/exhale-academy/app/login/actions.ts`
  - `/Users/joshguerrero/exhale-academy/app/signup/actions.ts`
  - `/Users/joshguerrero/exhale-academy/app/feedback/actions.ts`
  - `/Users/joshguerrero/exhale-academy/app/master/actions.ts`
  - `/Users/joshguerrero/exhale-academy/app/cse/master/actions.ts`
  - `/Users/joshguerrero/exhale-academy/app/quiz/[category]/actions.ts`
  - `/Users/joshguerrero/exhale-academy/app/cse/case/[slug]/actions.ts`
- Stripe webhook signature verification via Stripe SDK:
  - `/Users/joshguerrero/exhale-academy/app/api/stripe/webhook/route.ts`
  - `stripe.webhooks.constructEvent(...)`
- Subscription access gate:
  - `/Users/joshguerrero/exhale-academy/proxy.ts`
  - fallback resolution helper: `/Users/joshguerrero/exhale-academy/lib/auth/subscription-access.ts`

### Must-do before production launch
- Confirm HTTPS-only on production domain.
- Confirm Supabase RLS is enabled for all student data tables.
- Rotate any leaked/test API keys and switch to production-only keys.
- Set `EXHALE_ADMIN_EMAILS` in production env.
- Add error monitoring (Sentry) for server + client.
- Verify Stripe webhook endpoint in live mode points to:
  - `https://<your-domain>/api/stripe/webhook`
- Replay at least one successful webhook event and verify DB write.

### Required environment variables
- `EXHALE_ADMIN_EMAILS`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (required for webhook/profile sync writes)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
- `NEXT_PUBLIC_STRIPE_MONTHLY_PRICE_ID`
- `STRIPE_SECRET_KEY`
- `STRIPE_MONTHLY_PRICE_ID`
- `STRIPE_WEBHOOK_SECRET`
- `UPSTASH_REDIS_REST_URL` (recommended for distributed rate limiting)
- `UPSTASH_REDIS_REST_TOKEN` (recommended for distributed rate limiting)

### Notes
- Rate limiter supports Upstash Redis and falls back to process-local memory if Upstash env vars are missing.
- Webhook verification fails closed if `STRIPE_WEBHOOK_SECRET` is missing/invalid.
- Billing fallback endpoint exists for user-initiated sync:
  - `/Users/joshguerrero/exhale-academy/app/api/stripe/sync-subscription-status/route.ts`
