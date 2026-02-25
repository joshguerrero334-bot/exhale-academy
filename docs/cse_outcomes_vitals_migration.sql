-- Exhale Academy CSE outcomes + deterministic vitals migration

begin;

create extension if not exists pgcrypto;

alter table public.cse_cases
  add column if not exists baseline_vitals jsonb not null default '{}'::jsonb;

create table if not exists public.cse_outcomes (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.cse_steps(id) on delete cascade,
  label text,
  rule_priority int4 not null default 1,
  rule_type text not null check (rule_type in ('INCLUDES_ANY', 'INCLUDES_ALL', 'SCORE_AT_LEAST', 'SCORE_AT_MOST', 'DEFAULT')),
  rule_value jsonb,
  next_step_id uuid references public.cse_steps(id),
  outcome_text text not null,
  vitals_override jsonb,
  created_at timestamptz not null default now()
);

alter table public.cse_outcomes
  add column if not exists vitals_override jsonb;

create index if not exists idx_cse_outcomes_step_priority
  on public.cse_outcomes (step_id, rule_priority);

alter table public.cse_attempt_events
  add column if not exists outcome_id uuid references public.cse_outcomes(id);

alter table public.cse_outcomes enable row level security;

drop policy if exists cse_outcomes_authenticated_read on public.cse_outcomes;
create policy cse_outcomes_authenticated_read
  on public.cse_outcomes
  for select to authenticated
  using (true);

commit;
