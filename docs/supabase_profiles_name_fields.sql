-- Adds first/last name fields for signup capture.
-- Run manually in Supabase SQL editor.

begin;

alter table public.profiles
  add column if not exists first_name text;

alter table public.profiles
  add column if not exists last_name text;

commit;

