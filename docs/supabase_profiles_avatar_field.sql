-- Adds avatar_url field for student profile photos.
-- Run manually in Supabase SQL editor.

begin;

alter table public.profiles
  add column if not exists avatar_url text;

commit;
