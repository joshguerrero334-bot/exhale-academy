-- Exhale Academy: Case 2 cleanup + hidden placeholder
-- Run in Supabase SQL editor.

begin;

-- Add publication flag if schema does not have it yet.
alter table public.cse_cases
  add column if not exists is_published boolean not null default false;

with targets as (
  select c.id
  from public.cse_cases c
  where lower(coalesce(c.title, '')) like '%case 2%'
     or lower(coalesce(c.title, '')) like '%term infant%'
),
target_steps as (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from targets)
),
deleted_choices as (
  delete from public.cse_choices ch
  where ch.step_id in (select id from target_steps)
  returning ch.id
),
deleted_steps as (
  delete from public.cse_steps s
  where s.id in (select id from target_steps)
  returning s.id, s.case_id
),
deleted_cases as (
  delete from public.cse_cases c
  where c.id in (select id from targets)
  returning c.id
),
placeholder as (
  insert into public.cse_cases (
    source,
    case_number,
    title,
    stem,
    difficulty,
    is_active,
    is_published
  )
  values (
    'neonatal-delivery-room',
    2,
    'Case 2 — Term Infant (Placeholder, Hidden)',
    'Temporary placeholder while Case 2 is under QA.',
    'medium',
    false,
    false
  )
  returning id
)
select
  (select json_agg(id order by id) from deleted_cases) as deleted_case_ids,
  (select id from placeholder) as placeholder_case_id;

commit;
