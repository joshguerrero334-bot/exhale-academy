-- Exhale Academy CSE Case #3 Seed
-- Case 3 -- Adult Acute Respiratory Distress (Undifferentiated Smoker)

begin;

-- Compatibility columns (safe on older schemas)
alter table public.cse_cases add column if not exists age_group text;
alter table public.cse_cases add column if not exists tags text[] default '{}'::text[];
alter table public.cse_cases add column if not exists version int4 not null default 1;
alter table public.cse_cases add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.cse_cases add column if not exists is_published boolean not null default false;

alter table public.cse_steps add column if not exists step_kind text;
alter table public.cse_steps add column if not exists reveal_text text;
alter table public.cse_steps add column if not exists min_selections int4;
alter table public.cse_steps add column if not exists max_selections int4;

alter table public.cse_choices add column if not exists score_value int4;
alter table public.cse_choices add column if not exists rationale_text text;

-- Standardized scenarios table (compatible with older shapes)
create table if not exists public.cse_scenarios (
  id uuid primary key default gen_random_uuid(),
  slug text,
  title text not null,
  difficulty text,
  case_number int4,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  case_id uuid unique references public.cse_cases(id) on delete cascade,
  source text,
  is_published boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  description text
);

alter table public.cse_scenarios add column if not exists case_id uuid;
alter table public.cse_scenarios add column if not exists slug text;
alter table public.cse_scenarios add column if not exists source text;
alter table public.cse_scenarios add column if not exists title text;
alter table public.cse_scenarios add column if not exists description text;
alter table public.cse_scenarios add column if not exists difficulty text;
alter table public.cse_scenarios add column if not exists case_number int4;
alter table public.cse_scenarios add column if not exists is_active boolean not null default true;
alter table public.cse_scenarios add column if not exists is_published boolean not null default false;
alter table public.cse_scenarios add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.cse_scenarios add column if not exists created_at timestamptz not null default now();

create unique index if not exists idx_cse_scenarios_case_id_unique
  on public.cse_scenarios (case_id);

create temporary table _target_case (
  id uuid primary key,
  case_number int4
) on commit drop;

with matching_cases as (
  select c.id, c.created_at
  from public.cse_cases c
  where (
    lower(coalesce(c.title, '')) like '%case 3%'
    or lower(coalesce(c.title, '')) like '%undifferentiated smoker%'
    or lower(coalesce(c.title, '')) like '%adult acute respiratory distress%'
  )
),
target_existing as (
  select id
  from matching_cases
  order by created_at asc, id asc
  limit 1
),
updated_case as (
  update public.cse_cases c
  set
    source = 'adult-respiratory-distress',
    case_number = 3,
    title = 'Case 3 -- Adult Acute Respiratory Distress (Undifferentiated Smoker)',
    stem = 'Older smoker with severe acute dyspnea and unstable cardiopulmonary findings requiring staged stabilization.',
    difficulty = 'medium',
    age_group = 'Adult',
    tags = array['adult', 'respiratory-distress', 'oxygenation', 'ventilation', 'shock'],
    version = 2,
    is_active = true,
    is_published = true,
    metadata = coalesce(c.metadata, '{}'::jsonb) || jsonb_build_object('category', 'adult', 'format', 'strict_cse_v1', 'step_count', 6)
  where c.id in (select id from target_existing)
  returning c.id, c.case_number
),
created_case as (
  insert into public.cse_cases (
    source,
    case_number,
    title,
    stem,
    difficulty,
    age_group,
    tags,
    version,
    is_active,
    is_published,
    metadata
  )
  select
    'adult-respiratory-distress',
    3,
    'Case 3 -- Adult Acute Respiratory Distress (Undifferentiated Smoker)',
    'Older smoker with severe acute dyspnea and unstable cardiopulmonary findings requiring staged stabilization.',
    'medium',
    'Adult',
    array['adult', 'respiratory-distress', 'oxygenation', 'ventilation', 'shock'],
    2,
    true,
    true,
    jsonb_build_object('category', 'adult', 'format', 'strict_cse_v1', 'step_count', 6)
  where not exists (select 1 from target_existing)
  returning id, case_number
),
target_case as (
  select id, case_number from updated_case
  union all
  select id, case_number from created_case
)
insert into _target_case (id, case_number)
select id, case_number from target_case;

update public.cse_cases c
set is_active = false,
    is_published = false
where lower(coalesce(c.title, '')) like '%case 3%'
  and c.id not in (select id from _target_case);

insert into public.cse_scenarios (
  case_id,
  slug,
  source,
  title,
  description,
  difficulty,
  case_number,
  is_active,
  is_published,
  metadata
)
select
  tc.id,
  'case-3-adult-acute-respiratory-distress-undifferentiated-smoker',
  'adult-respiratory-distress',
  'Case 3 -- Adult Acute Respiratory Distress (Undifferentiated Smoker)',
  'Adult distress scenario with branching progression and urgent intervention decisions.',
  'medium',
  3,
  true,
  true,
  jsonb_build_object('format', 'strict_cse_v1', 'step_count', 6)
from _target_case tc
on conflict (case_id) do update
set
  slug = excluded.slug,
  source = excluded.source,
  title = excluded.title,
  description = excluded.description,
  difficulty = excluded.difficulty,
  case_number = excluded.case_number,
  is_active = excluded.is_active,
  is_published = excluded.is_published,
  metadata = excluded.metadata;

delete from public.cse_choices
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _target_case)
);

delete from public.cse_steps
where case_id in (select id from _target_case);

with step_1 as (
  insert into public.cse_steps (
    case_id, step_number, step_type, step_kind, prompt, rationale, reveal_text, min_selections, max_selections, metadata
  )
  select
    tc.id,
    1,
    'question',
    'ig',
    'A 67-year-old male presents to the emergency department with worsening shortness of breath over the past 48 hours. He appears anxious and is leaning forward on the stretcher using accessory muscles to breathe. Speech is limited to short phrases.

Vital signs:
HR 112/min
RR 32/min
BP 154/88 mm Hg
SpO2 84% on room air

He has a 40-pack-year smoking history.

SELECT AS MANY AS ARE INDICATED (MAX 4).
What information or immediate actions do you initiate?',
    null,
    null,
    1,
    4,
    jsonb_build_object('nbrc_step_kind', 'IG', 'selection_rule', 'select_up_to', 'min_selections', 1, 'max_selections', 4, 'stop_required', true, 'display_stop_bar', true, 'reveal_on_next_step', true)
  from _target_case tc
  returning id
),
step_2 as (
  insert into public.cse_steps (
    case_id, step_number, step_type, step_kind, prompt, rationale, reveal_text, min_selections, max_selections, metadata
  )
  select
    tc.id,
    2,
    'question',
    'dm',
    'Post-STOP Data Reveal:
If student prioritized oxygen, breath sound assessment, and IV preparation:
SpO2 improves to 90% with controlled oxygen via Venturi mask but BP drops to 82/50 mm Hg.
Right-sided breath sounds remain absent.
Tracheal deviation more pronounced.
Patient becomes increasingly restless.

If student delayed for imaging:
SpO2 drops to 78%.
BP falls to 74/48 mm Hg.
Patient becomes lethargic.

Current progression state for decision-making:
Severe hypoxemia
Hypotension
Absent right breath sounds
Tracheal deviation

CHOOSE ONLY ONE.
What is the most appropriate immediate intervention?',
    'After intervention:
If needle decompression is performed promptly, BP and oxygenation improve.
If delayed, obstructive shock worsens.',
    'After intervention:
If needle decompression is performed promptly, BP and oxygenation improve.
If delayed, obstructive shock worsens.',
    1,
    1,
    jsonb_build_object('nbrc_step_kind', 'DM', 'selection_rule', 'choose_one', 'min_selections', 1, 'max_selections', 1, 'stop_required', true, 'display_stop_bar', true)
  from _target_case tc
  returning id
),
step_3 as (
  insert into public.cse_steps (
    case_id, step_number, step_type, step_kind, prompt, rationale, reveal_text, min_selections, max_selections, metadata
  )
  select
    tc.id,
    3,
    'question',
    'ig',
    'Post-Intervention Update:
Sudden rush of air follows right needle decompression. BP improves to 102/64 mm Hg. SpO2 rises to 95% on controlled oxygen. HR decreases to 108/min. Breath sounds partially return on right.

SELECT AS MANY AS ARE INDICATED (MAX 3).
What reassessment and stabilization actions should occur next?',
    'Data Reveal:
Appropriate follow-up identifies persistent risk and supports definitive treatment planning.',
    'Data Reveal:
Appropriate follow-up identifies persistent risk and supports definitive treatment planning.',
    1,
    3,
    jsonb_build_object('nbrc_step_kind', 'IG', 'selection_rule', 'select_up_to', 'min_selections', 1, 'max_selections', 3, 'stop_required', true, 'display_stop_bar', true)
  from _target_case tc
  returning id
),
step_4 as (
  insert into public.cse_steps (
    case_id, step_number, step_type, step_kind, prompt, rationale, reveal_text, min_selections, max_selections, metadata
  )
  select
    tc.id,
    4,
    'question',
    'dm',
    'CHOOSE ONLY ONE.
What is the most appropriate definitive next intervention?',
    'Data Reveal:
Chest tube placement stabilizes ongoing air leak risk and supports sustained hemodynamic recovery.',
    'Data Reveal:
Chest tube placement stabilizes ongoing air leak risk and supports sustained hemodynamic recovery.',
    1,
    1,
    jsonb_build_object('nbrc_step_kind', 'DM', 'selection_rule', 'choose_one', 'min_selections', 1, 'max_selections', 1, 'stop_required', true, 'display_stop_bar', true)
  from _target_case tc
  returning id
),
step_5 as (
  insert into public.cse_steps (
    case_id, step_number, step_type, step_kind, prompt, rationale, reveal_text, min_selections, max_selections, metadata
  )
  select
    tc.id,
    5,
    'question',
    'ig',
    'After chest tube placement, the patient is more stable but still dyspneic.

SELECT AS MANY AS ARE INDICATED (MAX 3).
What ongoing monitoring and management actions are indicated now?',
    'Data Reveal:
ABG trend improves with controlled oxygen and ongoing treatment; work of breathing decreases but remains elevated.',
    'Data Reveal:
ABG trend improves with controlled oxygen and ongoing treatment; work of breathing decreases but remains elevated.',
    1,
    3,
    jsonb_build_object('nbrc_step_kind', 'IG', 'selection_rule', 'select_up_to', 'min_selections', 1, 'max_selections', 3, 'stop_required', true, 'display_stop_bar', true)
  from _target_case tc
  returning id
),
step_6 as (
  insert into public.cse_steps (
    case_id, step_number, step_type, step_kind, prompt, rationale, reveal_text, min_selections, max_selections, metadata
  )
  select
    tc.id,
    6,
    'question',
    'dm',
    'CHOOSE ONLY ONE.
What is the best disposition and immediate ongoing care plan?',
    'Final stabilization summary:
The case demonstrates recognition of evolving obstructive shock physiology, timely decompression, definitive chest drainage, and structured reassessment to prevent deterioration.',
    'Final stabilization summary:
The case demonstrates recognition of evolving obstructive shock physiology, timely decompression, definitive chest drainage, and structured reassessment to prevent deterioration.',
    1,
    1,
    jsonb_build_object('nbrc_step_kind', 'DM', 'selection_rule', 'choose_one', 'min_selections', 1, 'max_selections', 1, 'stop_required', true, 'display_stop_bar', true, 'final_step', true)
  from _target_case tc
  returning id
),

-- Step 1 IG choices
s1a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Apply controlled oxygen via Venturi mask', true, 2, 'Score +2', 'Immediate correction of hypoxemia with controlled FiO2 supports oxygenation while avoiding excessive oxygen exposure.', 2 from step_1 returning id, step_id
),
s1b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Assess bilateral breath sounds and tracheal position', true, 2, 'Score +2', 'Identifies unilateral airflow loss and mediastinal shift suggesting tension physiology.', 2 from step_1 returning id, step_id
),
s1c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Prepare IV access and hemodynamic monitoring', true, 2, 'Score +2', 'Supports rapid treatment of evolving hypotension and shock.', 2 from step_1 returning id, step_id
),
s1d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Delay intervention to obtain imaging first', false, -2, 'Score -2', 'Imaging delays treatment in an unstable patient with obstructive physiology signs.', 2 from step_1 returning id, step_id
),
s1e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Administer nebulized bronchodilator before reassessment', false, -1, 'Score -1', 'May be reasonable in other causes of dyspnea but does not treat current obstructive shock pattern.', 2 from step_1 returning id, step_id
),
s1f as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'F', 'Continue observation without immediate intervention', false, -2, 'Score -2', 'Delays lifesaving action while hypoxemia and hypotension worsen.', 2 from step_1 returning id, step_id
),

-- Step 2 DM choices
s2a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Perform immediate needle decompression of right chest', true, 2, 'Score +2', 'Classic signs of tension physiology require immediate decompression.', 3 from step_2 returning id, step_id
),
s2b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Increase IV fluids and observe response', false, -1, 'Score -1', 'Does not correct obstructive cause of shock.', 3 from step_2 returning id, step_id
),
s2c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Order emergent CT scan of chest', false, -2, 'Score -2', 'Imaging delays lifesaving intervention.', 3 from step_2 returning id, step_id
),
s2d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Intubate immediately without addressing underlying issue', false, -1, 'Score -1', 'Positive pressure may worsen tension physiology before decompression.', 3 from step_2 returning id, step_id
),

-- Step 3 IG choices
s3a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Reassess bilateral breath sounds and chest expansion', true, 2, 'Score +2', 'Confirms physiologic response and detects persistent asymmetry.', 4 from step_3 returning id, step_id
),
s3b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Prepare for definitive chest tube placement', true, 2, 'Score +2', 'Needle decompression is temporizing; definitive pleural drainage is required.', 4 from step_3 returning id, step_id
),
s3c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Continue continuous SpO2 and blood pressure monitoring', true, 1, 'Score +1', 'Trend monitoring supports early detection of recurrent instability.', 4 from step_3 returning id, step_id
),
s3d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Send for CT scan before chest tube placement', false, -2, 'Score -2', 'Defers definitive treatment while risk of decompensation persists.', 4 from step_3 returning id, step_id
),
s3e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Discontinue oxygen now that saturation improved', false, -1, 'Score -1', 'Premature weaning can reverse gains during unstable transition.', 4 from step_3 returning id, step_id
),

-- Step 4 DM choices
s4a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Insert right chest tube and connect to drainage', true, 2, 'Score +2', 'Definitive management after decompression prevents recurrence and supports recovery.', 5 from step_4 returning id, step_id
),
s4b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Leave needle catheter in place and observe only', false, -1, 'Score -1', 'Insufficient as sole ongoing management.', 5 from step_4 returning id, step_id
),
s4c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Prioritize CT imaging before tube placement', false, -2, 'Score -2', 'Imaging-first approach delays definitive therapy.', 5 from step_4 returning id, step_id
),
s4d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Start sedation for agitation without respiratory reassessment', false, -1, 'Score -1', 'Can obscure deterioration and does not treat primary cause.', 5 from step_4 returning id, step_id
),

-- Step 5 IG choices
s5a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Repeat ABG to trend ventilation and oxygenation', true, 2, 'Score +2', 'Objectively confirms response and guides oxygen/ventilation strategy.', 6 from step_5 returning id, step_id
),
s5b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Titrate oxygen to an SpO2 target range', true, 2, 'Score +2', 'Targeted oxygenation minimizes hypoxemia while avoiding overtreatment.', 6 from step_5 returning id, step_id
),
s5c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Continue frequent hemodynamic reassessment', true, 1, 'Score +1', 'Supports safe transition after shock physiology.', 6 from step_5 returning id, step_id
),
s5d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Increase FiO2 to 100% indefinitely', false, -1, 'Score -1', 'Unnecessary escalation without reassessment.', 6 from step_5 returning id, step_id
),
s5e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Administer sedative to suppress tachypnea', false, -2, 'Score -2', 'May worsen respiratory status and mask deterioration.', 6 from step_5 returning id, step_id
),

-- Step 6 DM choices
s6a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Admit for monitored care with ongoing respiratory reassessment', true, 2, 'Score +2', 'Appropriate disposition after critical instability with need for close follow-up.', null from step_6 returning id, step_id
),
s6b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Discharge after transient stabilization', false, -2, 'Score -2', 'Unsafe given recent obstructive shock physiology and intervention needs.', null from step_6 returning id, step_id
),
s6c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Intubate electively despite improving status', false, -1, 'Score -1', 'Not indicated without current failure pattern.', null from step_6 returning id, step_id
),
s6d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Stop monitoring once saturation briefly normalizes', false, -1, 'Score -1', 'Premature de-escalation risks missed relapse.', null from step_6 returning id, step_id
),

set_dm_correct_step2 as (
  update public.cse_steps s set correct_choice_id = c.id from s2a c where s.id = c.step_id returning s.id
),
set_dm_correct_step4 as (
  update public.cse_steps s set correct_choice_id = c.id from s4a c where s.id = c.step_id returning s.id
),
set_dm_correct_step6 as (
  update public.cse_steps s set correct_choice_id = c.id from s6a c where s.id = c.step_id returning s.id
)
select
  (select id from _target_case limit 1) as case_id,
  (select case_number from _target_case limit 1) as case_number,
  (
    select json_agg(json_build_object('step_id', s.id, 'step_number', s.step_number) order by s.step_number)
    from public.cse_steps s
    where s.case_id = (select id from _target_case limit 1)
  ) as inserted_steps,
  (
    select json_agg(json_build_object('choice_id', ch.id, 'step_id', ch.step_id, 'choice_key', ch.choice_key) order by ch.step_id, ch.choice_key)
    from public.cse_choices ch
    where ch.step_id in (
      select id from public.cse_steps where case_id = (select id from _target_case limit 1)
    )
  ) as inserted_choices;

commit;
