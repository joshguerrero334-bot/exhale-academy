-- Exhale Academy billing/subscription sync tables + policies
-- Run this in Supabase SQL editor before enabling Stripe webhook sync in production.

begin;

create extension if not exists pgcrypto;

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  stripe_customer_id text unique,
  stripe_subscription_id text unique,
  subscription_status text not null default 'inactive',
  subscription_current_period_end timestamptz,
  subscription_cancel_at_period_end boolean not null default false,
  subscription_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_profiles_subscription_status_idx
  on public.user_profiles(subscription_status);

create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  stripe_customer_id text,
  stripe_subscription_id text unique,
  status text not null default 'unknown',
  price_id text,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  source_event_type text,
  latest_payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_subscriptions_user_id_idx
  on public.user_subscriptions(user_id);
create index if not exists user_subscriptions_customer_id_idx
  on public.user_subscriptions(stripe_customer_id);
create index if not exists user_subscriptions_status_idx
  on public.user_subscriptions(status);

create table if not exists public.stripe_webhook_events (
  stripe_event_id text primary key,
  event_type text not null,
  received_at timestamptz not null default now(),
  payload jsonb not null
);

create index if not exists stripe_webhook_events_received_at_idx
  on public.stripe_webhook_events(received_at desc);

alter table public.user_profiles enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.stripe_webhook_events enable row level security;

drop policy if exists user_profiles_select_own on public.user_profiles;
create policy user_profiles_select_own
on public.user_profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists user_profiles_insert_own on public.user_profiles;
create policy user_profiles_insert_own
on public.user_profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists user_profiles_update_own on public.user_profiles;
create policy user_profiles_update_own
on public.user_profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Student-facing access to subscription history (optional for future account page)
drop policy if exists user_subscriptions_select_own on public.user_subscriptions;
create policy user_subscriptions_select_own
on public.user_subscriptions
for select
to authenticated
using (auth.uid() = user_id);

-- No authenticated insert/update/delete policies for webhook tables.
-- Service role (server-side only) bypasses RLS and performs sync writes.

commit;
