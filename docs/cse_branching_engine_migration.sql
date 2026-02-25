-- Exhale Academy CSE branching engine migration
-- State-driven simulation with rules + dynamic vitals

begin;

create extension if not exists pgcrypto;

create table if not exists public.cse_cases (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text,
  intro_text text,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.cse_cases add column if not exists source text;
alter table public.cse_cases add column if not exists case_number int4;
alter table public.cse_cases add column if not exists stem text;
alter table public.cse_cases add column if not exists description text;
alter table public.cse_cases add column if not exists difficulty text;
alter table public.cse_cases add column if not exists is_published boolean not null default false;
alter table public.cse_cases add column if not exists slug text;
alter table public.cse_cases add column if not exists intro_text text;

update public.cse_cases
set slug = coalesce(
  nullif(slug, ''),
  lower(regexp_replace(regexp_replace(coalesce(title, ''), '[^a-zA-Z0-9]+', '-', 'g'), '(^-|-$)', '', 'g')),
  'case-' || left(replace(id::text, '-', ''), 12)
);

update public.cse_cases
set intro_text = coalesce(intro_text, stem, description, title)
where intro_text is null;

create unique index if not exists idx_cse_cases_slug_unique
  on public.cse_cases (slug);

create table if not exists public.cse_steps (
  id uuid primary key default gen_random_uuid(),
  case_id uuid not null references public.cse_cases(id) on delete cascade,
  step_order int4 not null,
  step_type text not null check (step_type in ('IG', 'DM')),
  prompt text not null,
  max_select int4,
  stop_label text not null default 'STOP',
  created_at timestamptz not null default now()
);

alter table public.cse_steps add column if not exists step_number int4;
alter table public.cse_steps add column if not exists step_kind text;
alter table public.cse_steps add column if not exists min_selections int4;
alter table public.cse_steps add column if not exists max_selections int4;
alter table public.cse_steps add column if not exists reveal_text text;
alter table public.cse_steps add column if not exists rationale text;
alter table public.cse_steps add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.cse_steps add column if not exists correct_choice_id uuid;
alter table public.cse_steps add column if not exists step_order int4;
alter table public.cse_steps add column if not exists step_type text;
alter table public.cse_steps add column if not exists max_select int4;
alter table public.cse_steps add column if not exists stop_label text not null default 'STOP';

do $$
declare
  r record;
begin
  for r in
    select conname
    from pg_constraint
    where conrelid = 'public.cse_steps'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%step_type%'
  loop
    execute format('alter table public.cse_steps drop constraint if exists %I', r.conname);
  end loop;
end
$$;

update public.cse_steps
set
  step_number = coalesce(step_number, step_order),
  step_order = coalesce(step_order, step_number),
  step_type = case
    when upper(coalesce(step_type, '')) in ('IG', 'DM') then upper(step_type)
    when lower(coalesce(step_kind, metadata->>'nbrc_step_kind', '')) = 'ig' then 'IG'
    when lower(coalesce(step_kind, metadata->>'nbrc_step_kind', '')) = 'dm' then 'DM'
    when coalesce(max_select, max_selections, (metadata->>'max_selections')::int, 1) = 1 then 'DM'
    else 'IG'
  end,
  max_select = coalesce(
    max_select,
    max_selections,
    case
      when lower(coalesce(step_kind, metadata->>'nbrc_step_kind', '')) = 'ig' then nullif((metadata->>'max_selections')::int, 0)
      else 1
    end
  )
where step_order is null
   or step_type is null
   or upper(coalesce(step_type, '')) not in ('IG', 'DM')
   or max_select is null;

update public.cse_steps
set step_type = upper(step_type)
where step_type is not null;

alter table public.cse_steps
  alter column step_order set not null;

alter table public.cse_steps
  alter column step_number drop not null;

alter table public.cse_steps
  alter column step_type set not null;

alter table public.cse_steps
  add constraint cse_steps_step_type_check check (upper(step_type) in ('IG', 'DM'));

create or replace function public.normalize_cse_step_type()
returns trigger
language plpgsql
as $$
begin
  new.step_number := coalesce(new.step_number, new.step_order);
  new.step_order := coalesce(new.step_order, new.step_number);

  if new.step_type is null or upper(new.step_type) not in ('IG', 'DM') then
    if lower(coalesce(new.step_kind, new.metadata->>'nbrc_step_kind', '')) = 'ig' then
      new.step_type := 'IG';
    elsif lower(coalesce(new.step_kind, new.metadata->>'nbrc_step_kind', '')) = 'dm' then
      new.step_type := 'DM';
    elsif coalesce(new.max_select, new.max_selections, 1) = 1 then
      new.step_type := 'DM';
    else
      new.step_type := 'IG';
    end if;
  else
    new.step_type := upper(new.step_type);
  end if;

  return new;
end;
$$;

drop trigger if exists trg_normalize_cse_step_type on public.cse_steps;
create trigger trg_normalize_cse_step_type
before insert or update on public.cse_steps
for each row
execute function public.normalize_cse_step_type();

create unique index if not exists idx_cse_steps_case_order_unique
  on public.cse_steps (case_id, step_order);

create table if not exists public.cse_options (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.cse_steps(id) on delete cascade,
  option_key text not null,
  option_text text not null,
  score int4 not null,
  rationale text not null,
  created_at timestamptz not null default now(),
  unique (step_id, option_key)
);

create table if not exists public.cse_rules (
  id uuid primary key default gen_random_uuid(),
  step_id uuid not null references public.cse_steps(id) on delete cascade,
  rule_priority int4 not null default 1,
  rule_type text not null check (rule_type in ('INCLUDES_ANY', 'INCLUDES_ALL', 'SCORE_AT_LEAST', 'SCORE_AT_MOST', 'DEFAULT')),
  rule_value jsonb,
  next_step_id uuid references public.cse_steps(id),
  outcome_text text not null,
  vitals_delta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.cse_rules
  alter column rule_value type jsonb
  using case
    when rule_value is null then null
    when left(trim(rule_value::text), 1) in ('{', '[', '"')
      or trim(rule_value::text) ~ '^-?[0-9]+(\\.[0-9]+)?$'
      or lower(trim(rule_value::text)) in ('true', 'false', 'null')
    then rule_value::jsonb
    else jsonb_build_object('value', rule_value::text)
  end;

create index if not exists idx_cse_rules_step_priority
  on public.cse_rules (step_id, rule_priority);

create table if not exists public.cse_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  case_id uuid not null references public.cse_cases(id) on delete cascade,
  mode text not null check (mode in ('tutor', 'exam')),
  current_step_id uuid references public.cse_steps(id),
  status text not null default 'in_progress' check (status in ('in_progress', 'completed')),
  total_score int4 not null default 0,
  vitals jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.cse_attempts add column if not exists current_step_index int4;
alter table public.cse_attempts add column if not exists total_steps int4;
alter table public.cse_attempts add column if not exists total_points int4;
alter table public.cse_attempts add column if not exists current_step_id uuid references public.cse_steps(id);
alter table public.cse_attempts add column if not exists total_score int4 not null default 0;
alter table public.cse_attempts add column if not exists vitals jsonb not null default '{}'::jsonb;

update public.cse_attempts
set total_score = coalesce(total_score, total_points, 0)
where total_score is null;

create table if not exists public.cse_attempt_events (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.cse_attempts(id) on delete cascade,
  step_id uuid not null references public.cse_steps(id) on delete cascade,
  selected_keys text[] not null,
  step_score int4 not null,
  outcome_text text not null,
  vitals_after jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_cse_attempt_events_attempt_created
  on public.cse_attempt_events (attempt_id, created_at desc);

alter table public.cse_attempts enable row level security;
alter table public.cse_attempt_events enable row level security;
alter table public.cse_cases enable row level security;
alter table public.cse_steps enable row level security;
alter table public.cse_options enable row level security;
alter table public.cse_rules enable row level security;

drop policy if exists cse_attempts_select_own on public.cse_attempts;
create policy cse_attempts_select_own
  on public.cse_attempts
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists cse_attempts_insert_own on public.cse_attempts;
create policy cse_attempts_insert_own
  on public.cse_attempts
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists cse_attempts_update_own on public.cse_attempts;
create policy cse_attempts_update_own
  on public.cse_attempts
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists cse_attempt_events_select_own on public.cse_attempt_events;
create policy cse_attempt_events_select_own
  on public.cse_attempt_events
  for select to authenticated
  using (
    exists (
      select 1
      from public.cse_attempts a
      where a.id = cse_attempt_events.attempt_id
        and a.user_id = auth.uid()
    )
  );

drop policy if exists cse_attempt_events_insert_own on public.cse_attempt_events;
create policy cse_attempt_events_insert_own
  on public.cse_attempt_events
  for insert to authenticated
  with check (
    exists (
      select 1
      from public.cse_attempts a
      where a.id = cse_attempt_events.attempt_id
        and a.user_id = auth.uid()
    )
  );

drop policy if exists cse_cases_authenticated_read on public.cse_cases;
create policy cse_cases_authenticated_read
  on public.cse_cases
  for select to authenticated
  using (true);

drop policy if exists cse_steps_authenticated_read on public.cse_steps;
create policy cse_steps_authenticated_read
  on public.cse_steps
  for select to authenticated
  using (true);

drop policy if exists cse_options_authenticated_read on public.cse_options;
create policy cse_options_authenticated_read
  on public.cse_options
  for select to authenticated
  using (true);

drop policy if exists cse_rules_authenticated_read on public.cse_rules;
create policy cse_rules_authenticated_read
  on public.cse_rules
  for select to authenticated
  using (true);

create or replace function public.cse_debug_rows()
returns table (
  case_id uuid,
  case_slug text,
  case_title text,
  step_id uuid,
  step_order int4,
  step_type text,
  max_select int4,
  default_rule_count int8,
  outcome_if_student_hits int8
)
language sql
security definer
set search_path = public
as $$
  select
    c.id as case_id,
    c.slug as case_slug,
    c.title as case_title,
    s.id as step_id,
    s.step_order,
    s.step_type,
    s.max_select,
    (
      select count(*)
      from public.cse_rules r
      where r.step_id = s.id
        and r.rule_type = 'DEFAULT'
    ) as default_rule_count,
    (
      select count(*)
      from public.cse_rules r
      where r.step_id = s.id
        and lower(r.outcome_text) like '%if student%'
    ) as outcome_if_student_hits
  from public.cse_cases c
  join public.cse_steps s on s.case_id = c.id
  where c.is_active = true
  order by c.title asc, s.step_order asc;
$$;

revoke all on function public.cse_debug_rows() from public;
grant execute on function public.cse_debug_rows() to authenticated;

commit;
