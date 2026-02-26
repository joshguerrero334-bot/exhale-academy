-- Stores onboarding/lead data for future marketing workflows
-- Run in Supabase SQL editor.

begin;

create extension if not exists pgcrypto;

create table if not exists public.marketing_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text not null,
  phone_number text,
  date_of_birth date,
  graduation_date date,
  exam_date date,
  prior_attempt_count int4,
  marketing_opt_in boolean not null default false,
  source text not null default 'subscription_checkout',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create index if not exists marketing_contacts_email_idx on public.marketing_contacts(email);
create index if not exists marketing_contacts_exam_date_idx on public.marketing_contacts(exam_date);
create index if not exists marketing_contacts_opt_in_idx on public.marketing_contacts(marketing_opt_in);

alter table public.marketing_contacts enable row level security;

drop policy if exists marketing_contacts_select_own on public.marketing_contacts;
create policy marketing_contacts_select_own
on public.marketing_contacts
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists marketing_contacts_insert_own on public.marketing_contacts;
create policy marketing_contacts_insert_own
on public.marketing_contacts
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists marketing_contacts_update_own on public.marketing_contacts;
create policy marketing_contacts_update_own
on public.marketing_contacts
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

commit;
