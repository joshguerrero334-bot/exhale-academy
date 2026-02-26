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
- Stripe webhook signature verification route:
  - `/Users/joshguerrero/exhale-academy/app/api/stripe/webhook/route.ts`
  - verifier: `/Users/joshguerrero/exhale-academy/lib/security/stripe-webhook.ts`

### Must-do before production launch
- Confirm HTTPS-only on production domain.
- Confirm Supabase RLS is enabled for all student data tables.
- Rotate any leaked/test API keys and use production-only keys.
- Set `EXHALE_ADMIN_EMAILS` in production env.
- Add error monitoring (Sentry) for server + client.

### Required environment variables
- `EXHALE_ADMIN_EMAILS`
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (required for server-side webhook sync writes)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_PRICE_MONTHLY_ID`
- `UPSTASH_REDIS_REST_URL` (recommended for distributed rate limiting)
- `UPSTASH_REDIS_REST_TOKEN` (recommended for distributed rate limiting)
- `STRIPE_WEBHOOK_SECRET` (required when Stripe webhooks are enabled)

### Notes
- Rate limiter supports Upstash Redis and automatically falls back to process-local memory if Upstash env vars are missing.
- Stripe webhook now fails closed if `STRIPE_WEBHOOK_SECRET` is not set.
- Stripe event idempotency is enforced in `public.stripe_webhook_events` (duplicate events are ignored safely).
