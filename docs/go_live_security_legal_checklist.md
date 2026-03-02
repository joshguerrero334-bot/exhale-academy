## Exhale Go-Live Security + Legal Checklist

This checklist is mapped to the current Exhale codebase and deployment stack (Next.js + Supabase + Stripe + Vercel).

### 1. Security Controls (technical)

1. Confirm production env vars are set in Vercel (Production scope):
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
   - `NEXT_PUBLIC_STRIPE_MONTHLY_PRICE_ID`
   - `STRIPE_SECRET_KEY`
   - `STRIPE_MONTHLY_PRICE_ID`
   - `STRIPE_WEBHOOK_SECRET`
2. Confirm domain TLS + HTTPS redirect in Vercel.
3. Confirm security headers are active:
   - Source: `/Users/joshguerrero/exhale-academy/next.config.ts`
4. Confirm rate limiting is active on auth + key endpoints:
   - Source: `/Users/joshguerrero/exhale-academy/lib/security/rate-limit.ts`
5. Confirm subscription gate is active:
   - Source: `/Users/joshguerrero/exhale-academy/proxy.ts`
6. Confirm webhook signature verification works in live mode:
   - Endpoint: `/api/stripe/webhook`
   - Source: `/Users/joshguerrero/exhale-academy/app/api/stripe/webhook/route.ts`
7. Confirm fallback sync endpoint works for paid users:
   - Endpoint: `/api/stripe/sync-subscription-status`
   - Source: `/Users/joshguerrero/exhale-academy/app/api/stripe/sync-subscription-status/route.ts`

### 2. Database + Access Model (Supabase)

1. Confirm `profiles` table exists with:
   - `user_id` (uuid, linked to auth user)
   - `is_subscribed` (boolean)
   - `stripe_customer_id` (text, optional)
   - `stripe_subscription_id` (text, optional)
2. Confirm `profiles` has RLS enabled and self-access policies.
3. Confirm legacy compatibility tables if still used (`user_profiles`) are protected by RLS.
4. Run and archive migrations in order:
   - `/Users/joshguerrero/exhale-academy/docs/supabase_profiles_subscription_migration.sql`
   - `/Users/joshguerrero/exhale-academy/docs/supabase_profiles_name_fields.sql`
5. Verify the same paid user is marked active in DB after webhook:
   - `profiles.is_subscribed = true` (primary)
   - `user_profiles.subscription_status in ('active','trialing')` (legacy compatibility)

### 3. Stripe Production Readiness

1. Use live keys + live price ID in Production env only.
2. Verify webhook endpoint in Stripe live mode:
   - `https://<your-domain>/api/stripe/webhook`
3. Subscribe once with a real card:
   - Confirm `checkout.session.completed` returns 200.
   - Confirm `customer.subscription.updated` returns 200.
4. Verify app unlock flow:
   - New user: `signup -> billing -> checkout -> dashboard -> tmc/cse accessible`
   - Existing subscribed user: `login -> dashboard -> tmc/cse accessible`
5. Verify cancellation flow:
   - `customer.subscription.deleted` updates DB and access is revoked.

### 4. Legal + Policy Requirements

1. Expand Privacy page into a production policy:
   - Current file: `/Users/joshguerrero/exhale-academy/app/privacy/page.tsx`
   - Include data categories, purpose, retention, deletion request method, contact email.
2. Expand Terms page into production terms:
   - Current file: `/Users/joshguerrero/exhale-academy/app/terms/page.tsx`
   - Include subscriptions/renewal, refunds, account suspension, limitation of liability, governing law.
3. Add explicit marketing consent language if collecting outreach data:
   - Relevant tables/flows: `marketing_contacts`, signup/billing forms.
4. Add support/legal contact mailbox and show it in Privacy + Terms.
5. Define and publish data-request process:
   - Access request
   - Deletion request
   - Correction request

### 5. Operational Readiness

1. Monitoring:
   - Add runtime error monitoring (Sentry or equivalent).
   - Alert on webhook failures and auth failure spikes.
2. Backups:
   - Confirm Supabase backup plan and restore test date.
3. Incident response:
   - Create one-page breach response SOP with owner and escalation path.
4. Admin controls:
   - Confirm `EXHALE_ADMIN_EMAILS` production value only includes authorized admins.
5. Change management:
   - Block direct production changes without Git commit + deploy notes.

### 6. Final Go-Live Acceptance Test (must all pass)

1. Landing page mobile + desktop render (no horizontal overflow).
2. Signup captures first/last/email/password and stores profile row.
3. Stripe checkout opens and returns success URL.
4. Webhook marks user subscribed in DB.
5. Paid user can access `/tmc` and `/cse`.
6. Unpaid logged-in user gets redirected to `/billing`.
7. Privacy + Terms pages are finalized (not placeholder text).
8. Domain, SSL, and DNS are stable for 24h with no cert errors.

### 7. Decision Gate

Go live only when:
- All section 1-3 items are complete.
- Section 4 legal docs are finalized and published.
- Section 6 acceptance test is fully green.

