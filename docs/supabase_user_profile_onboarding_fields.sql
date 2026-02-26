-- Adds onboarding/account fields required by the subscription checkout flow
-- Run in Supabase SQL editor (production + local as needed).

begin;

alter table public.user_profiles add column if not exists contact_email text;
alter table public.user_profiles add column if not exists phone_number text;
alter table public.user_profiles add column if not exists date_of_birth date;
alter table public.user_profiles add column if not exists graduation_date date;
alter table public.user_profiles add column if not exists exam_date date;
alter table public.user_profiles add column if not exists prior_attempt_count int4;

commit;
