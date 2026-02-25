-- Exhale Academy feedback feature schema + RLS policies
-- Run this in the Supabase SQL editor.

begin;

create extension if not exists pgcrypto;

create table if not exists public.user_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  email text,
  product_area text,
  rating int2 check (rating between 1 and 5),
  what_looks_great text not null,
  where_improve text not null,
  additional_notes text,
  created_at timestamptz not null default now()
);

create index if not exists user_feedback_user_id_idx on public.user_feedback(user_id);
create index if not exists user_feedback_created_at_idx on public.user_feedback(created_at desc);
create index if not exists user_feedback_product_area_idx on public.user_feedback(product_area);

alter table public.user_feedback enable row level security;

drop policy if exists user_feedback_insert_own on public.user_feedback;
create policy user_feedback_insert_own
on public.user_feedback
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists user_feedback_select_own on public.user_feedback;
create policy user_feedback_select_own
on public.user_feedback
for select
to authenticated
using (auth.uid() = user_id);

commit;
