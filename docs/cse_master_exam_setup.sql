-- Exhale Academy CSE Master Exam schema
-- 20-case NBRC-blueprint master CSE attempts with Tutor/Exam mode.

create extension if not exists pgcrypto;

create table if not exists public.cse_master_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  mode text not null check (mode in ('tutor', 'exam')),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  total_cases int4 not null default 20 check (total_cases > 0),
  completed_cases int4 not null default 0 check (completed_cases >= 0),
  total_score int4 not null default 0,
  created_at timestamptz not null default now(),
  completed_at timestamptz null
);

create table if not exists public.cse_master_attempt_cases (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.cse_master_attempts(id) on delete cascade,
  case_id uuid not null references public.cse_cases(id) on delete restrict,
  order_index int4 not null,
  blueprint_category_code text not null,
  blueprint_subcategory text null,
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed')),
  cse_attempt_id uuid null references public.cse_attempts(id) on delete set null,
  case_score int4 null,
  started_at timestamptz null,
  completed_at timestamptz null,
  unique (attempt_id, order_index),
  unique (attempt_id, case_id),
  unique (cse_attempt_id)
);

create index if not exists idx_cse_master_attempts_user_created
  on public.cse_master_attempts (user_id, created_at desc);

create index if not exists idx_cse_master_attempt_cases_attempt_order
  on public.cse_master_attempt_cases (attempt_id, order_index);

create index if not exists idx_cse_master_attempt_cases_cse_attempt
  on public.cse_master_attempt_cases (cse_attempt_id);

alter table public.cse_master_attempts enable row level security;
alter table public.cse_master_attempt_cases enable row level security;

drop policy if exists cse_master_attempts_select_own on public.cse_master_attempts;
create policy cse_master_attempts_select_own
  on public.cse_master_attempts
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists cse_master_attempts_insert_own on public.cse_master_attempts;
create policy cse_master_attempts_insert_own
  on public.cse_master_attempts
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists cse_master_attempts_update_own on public.cse_master_attempts;
create policy cse_master_attempts_update_own
  on public.cse_master_attempts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists cse_master_attempt_cases_select_own on public.cse_master_attempt_cases;
create policy cse_master_attempt_cases_select_own
  on public.cse_master_attempt_cases
  for select to authenticated
  using (
    exists (
      select 1
      from public.cse_master_attempts a
      where a.id = cse_master_attempt_cases.attempt_id
        and a.user_id = auth.uid()
    )
  );

drop policy if exists cse_master_attempt_cases_insert_own on public.cse_master_attempt_cases;
create policy cse_master_attempt_cases_insert_own
  on public.cse_master_attempt_cases
  for insert to authenticated
  with check (
    exists (
      select 1
      from public.cse_master_attempts a
      where a.id = cse_master_attempt_cases.attempt_id
        and a.user_id = auth.uid()
    )
  );

drop policy if exists cse_master_attempt_cases_update_own on public.cse_master_attempt_cases;
create policy cse_master_attempt_cases_update_own
  on public.cse_master_attempt_cases
  for update to authenticated
  using (
    exists (
      select 1
      from public.cse_master_attempts a
      where a.id = cse_master_attempt_cases.attempt_id
        and a.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.cse_master_attempts a
      where a.id = cse_master_attempt_cases.attempt_id
        and a.user_id = auth.uid()
    )
  );
