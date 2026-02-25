-- Exhale Academy CSE reference values storage
-- Stores normal ranges/targets for scenario and item generation.

begin;

create extension if not exists pgcrypto;

create table if not exists public.cse_reference_values (
  id uuid primary key default gen_random_uuid(),
  source_name text not null,
  source_revision text,
  category text not null,
  item_name text not null,
  normal_text text not null,
  low_value numeric,
  high_value numeric,
  unit text,
  notes text,
  created_at timestamptz not null default now(),
  unique (source_name, category, item_name)
);

alter table public.cse_reference_values enable row level security;

drop policy if exists cse_reference_values_authenticated_read on public.cse_reference_values;
create policy cse_reference_values_authenticated_read
  on public.cse_reference_values
  for select to authenticated
  using (true);

create index if not exists idx_cse_reference_values_category
  on public.cse_reference_values (category, item_name);

commit;
