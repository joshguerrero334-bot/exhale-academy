-- Exhale Academy CSE schema migration (safe / additive)
-- Run this first, then run docs/cse_case2_insert.sql

begin;

create extension if not exists pgcrypto;

-- cse_cases metadata
alter table public.cse_cases add column if not exists age_group text;
alter table public.cse_cases add column if not exists tags text[] default '{}'::text[];
alter table public.cse_cases add column if not exists version int4 not null default 1;
alter table public.cse_cases add column if not exists metadata jsonb not null default '{}'::jsonb;

-- cse_steps metadata and selection rules
alter table public.cse_steps add column if not exists step_kind text;
alter table public.cse_steps add column if not exists min_selections int4;
alter table public.cse_steps add column if not exists max_selections int4;
alter table public.cse_steps add column if not exists reveal_text text;

update public.cse_steps
set
  step_kind = coalesce(step_kind, lower(nullif(metadata->>'nbrc_step_kind', ''))),
  min_selections = coalesce(min_selections, case when lower(coalesce(metadata->>'nbrc_step_kind', '')) = 'dm' then 1 else 1 end),
  max_selections = coalesce(max_selections, (metadata->>'max_selections')::int, case when lower(coalesce(metadata->>'nbrc_step_kind', '')) = 'dm' then 1 else 3 end),
  reveal_text = coalesce(reveal_text, rationale);

alter table public.cse_steps alter column min_selections set default 1;
alter table public.cse_steps alter column max_selections set default 1;

-- Drop/recreate check to ensure valid step kinds if constraint exists already
alter table public.cse_steps drop constraint if exists cse_steps_step_kind_check;
alter table public.cse_steps
  add constraint cse_steps_step_kind_check
  check (step_kind is null or step_kind in ('ig', 'dm'));

-- cse_choices scoring/rationale fields
alter table public.cse_choices add column if not exists score_value int4;
alter table public.cse_choices add column if not exists rationale_text text;

update public.cse_choices
set
  score_value = coalesce(score_value, nullif(regexp_replace(coalesce(feedback, ''), '.*[Ss]core\s*([+-]?\d+).*', '\\1'), '')::int),
  rationale_text = coalesce(rationale_text, feedback)
where score_value is null or rationale_text is null;

alter table public.cse_choices drop constraint if exists cse_choices_score_value_check;
alter table public.cse_choices
  add constraint cse_choices_score_value_check
  check (score_value is null or score_value in (-2, -1, 1, 2));

-- Attempt tables
create table if not exists public.cse_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  case_id uuid not null references public.cse_cases(id) on delete cascade,
  mode text not null check (mode in ('tutor', 'exam')),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  current_step_index int4 not null default 0,
  total_steps int4 not null default 0,
  total_points int4 not null default 0,
  created_at timestamptz not null default now(),
  completed_at timestamptz null
);

create table if not exists public.cse_attempt_steps (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.cse_attempts(id) on delete cascade,
  step_id uuid not null references public.cse_steps(id) on delete cascade,
  step_index int4 not null,
  selected_choice_ids jsonb not null default '[]'::jsonb,
  points_earned int4 not null default 0,
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  unique (attempt_id, step_index),
  unique (attempt_id, step_id)
);

create index if not exists idx_cse_attempts_user_status
  on public.cse_attempts (user_id, status, created_at desc);

create index if not exists idx_cse_attempts_case
  on public.cse_attempts (case_id);

create index if not exists idx_cse_attempt_steps_attempt_index
  on public.cse_attempt_steps (attempt_id, step_index);

-- RLS
alter table public.cse_attempts enable row level security;
alter table public.cse_attempt_steps enable row level security;

drop policy if exists cse_attempts_select_own on public.cse_attempts;
create policy cse_attempts_select_own
  on public.cse_attempts
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists cse_attempts_insert_own on public.cse_attempts;
create policy cse_attempts_insert_own
  on public.cse_attempts
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists cse_attempts_update_own on public.cse_attempts;
create policy cse_attempts_update_own
  on public.cse_attempts
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists cse_attempt_steps_select_own on public.cse_attempt_steps;
create policy cse_attempt_steps_select_own
  on public.cse_attempt_steps
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.cse_attempts a
      where a.id = cse_attempt_steps.attempt_id
        and a.user_id = auth.uid()
    )
  );

drop policy if exists cse_attempt_steps_insert_own on public.cse_attempt_steps;
create policy cse_attempt_steps_insert_own
  on public.cse_attempt_steps
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.cse_attempts a
      where a.id = cse_attempt_steps.attempt_id
        and a.user_id = auth.uid()
    )
  );

drop policy if exists cse_attempt_steps_update_own on public.cse_attempt_steps;
create policy cse_attempt_steps_update_own
  on public.cse_attempt_steps
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.cse_attempts a
      where a.id = cse_attempt_steps.attempt_id
        and a.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.cse_attempts a
      where a.id = cse_attempt_steps.attempt_id
        and a.user_id = auth.uid()
    )
  );

commit;
