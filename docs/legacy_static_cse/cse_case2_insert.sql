-- Exhale Academy CSE Case #2 Seed (STRICT structure)
-- Scene -> IG -> STOP/Data Reveal -> DM -> STOP/Data Reveal -> IG -> STOP/Data Reveal -> DM -> STOP/Final Outcome

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

-- Optional standardized mirror table requested by product spec.
create table if not exists public.cse_scenarios (
  id uuid primary key default gen_random_uuid(),
  case_id uuid unique not null references public.cse_cases(id) on delete cascade,
  source text,
  title text not null,
  is_published boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- If cse_scenarios already exists with older shape, align required columns.
alter table public.cse_scenarios add column if not exists case_id uuid;
alter table public.cse_scenarios add column if not exists slug text;
alter table public.cse_scenarios add column if not exists source text;
alter table public.cse_scenarios add column if not exists title text;
alter table public.cse_scenarios add column if not exists difficulty text;
alter table public.cse_scenarios add column if not exists is_published boolean not null default false;
alter table public.cse_scenarios add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.cse_scenarios add column if not exists created_at timestamptz not null default now();

-- Use index-based upsert target for compatibility.
create unique index if not exists idx_cse_scenarios_case_id_unique
  on public.cse_scenarios (case_id);

create temporary table _target_case (
  id uuid primary key,
  case_number int4
) on commit drop;

with matching_cases as (
  select c.id, c.created_at
  from public.cse_cases c
  where c.source = 'neonatal-delivery-room'
    and (
      lower(coalesce(c.title, '')) like '%case 2%'
      or lower(coalesce(c.title, '')) like '%term infant%'
      or lower(coalesce(c.title, '')) like '%meconium%'
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
    source = 'neonatal-delivery-room',
    case_number = 2,
    title = 'Case 2 -- Term Infant Delivered Through Meconium',
    stem = 'Term infant delivered through thick meconium with depressed respirations requiring structured stabilization.',
    difficulty = 'medium',
    age_group = 'Neonatal',
    tags = array['neonatal', 'delivery-room', 'oxygenation', 'ventilation', 'NRP'],
    version = 2,
    is_active = true,
    is_published = true,
    metadata = coalesce(c.metadata, '{}'::jsonb) || jsonb_build_object('category', 'neonatal', 'format', 'strict_cse_v1')
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
    'neonatal-delivery-room',
    2,
    'Case 2 -- Term Infant Delivered Through Meconium',
    'Term infant delivered through thick meconium with depressed respirations requiring structured stabilization.',
    'medium',
    'Neonatal',
    array['neonatal', 'delivery-room', 'oxygenation', 'ventilation', 'NRP'],
    2,
    true,
    true,
    jsonb_build_object('category', 'neonatal', 'format', 'strict_cse_v1')
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

-- Deactivate any extra duplicates so only one visible case remains.
update public.cse_cases c
set is_active = false,
    is_published = false
where c.source = 'neonatal-delivery-room'
  and lower(coalesce(c.title, '')) like '%case 2%'
  and c.id not in (select id from _target_case);

-- Mirror into cse_scenarios table.
insert into public.cse_scenarios (case_id, slug, source, title, difficulty, is_published, metadata)
select
  tc.id,
  'case-2-term-infant-delivered-through-meconium',
  'neonatal-delivery-room',
  'Case 2 -- Term Infant Delivered Through Meconium',
  'medium',
  true,
  jsonb_build_object('format', 'strict_cse_v1')
from _target_case tc
on conflict (case_id) do update
set
  slug = excluded.slug,
  source = excluded.source,
  title = excluded.title,
  difficulty = excluded.difficulty,
  is_published = excluded.is_published,
  metadata = excluded.metadata;

-- Clean old step content for this case.
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
    case_id,
    step_number,
    step_type,
    step_kind,
    prompt,
    rationale,
    reveal_text,
    min_selections,
    max_selections,
    metadata
  )
  select
    tc.id,
    1,
    'question',
    'ig',
    'Scene Introduction

You are called to the delivery room for a term infant born through thick meconium-stained amniotic fluid. Fetal heart tracing showed recurrent variable decelerations prior to delivery.

The infant is placed under the radiant warmer.

You observe:

- Limp tone
- No strong cry
- Occasional weak gasping respirations
- Heart rate: 84/min
- Skin pale with visible meconium staining

Resuscitation equipment is available at bedside.

You are the respiratory therapist responsible for initial stabilization.

QUESTION 1 -- INFORMATION GATHERING

What information and immediate actions are indicated at this time?
SELECT AS MANY AS ARE APPROPRIATE (MAX 4)',
    'Data Reveal 1

If effective ventilation was initiated promptly:
- Heart rate increases to 110/min
- Spontaneous effort remains weak
- Moderate retractions present
- Preductal SpO2: 78%

If ventilation was delayed:
- Heart rate decreases to 70/min
- Apnea develops
- Cyanosis worsens

If deep suctioning was attempted before ventilation:
- Heart rate drops into the 60s
- Respiratory effort diminishes

Current bedside condition (assuming appropriate early support):
- HR 110/min
- Irregular spontaneous respirations
- Moderate retractions
- Preductal SpO2 78%

The infant is improving but remains in respiratory distress.',
    'Data Reveal 1

If effective ventilation was initiated promptly:
- Heart rate increases to 110/min
- Spontaneous effort remains weak
- Moderate retractions present
- Preductal SpO2: 78%

If ventilation was delayed:
- Heart rate decreases to 70/min
- Apnea develops
- Cyanosis worsens

If deep suctioning was attempted before ventilation:
- Heart rate drops into the 60s
- Respiratory effort diminishes

Current bedside condition (assuming appropriate early support):
- HR 110/min
- Irregular spontaneous respirations
- Moderate retractions
- Preductal SpO2 78%

The infant is improving but remains in respiratory distress.',
    1,
    4,
    jsonb_build_object(
      'nbrc_step_kind', 'IG',
      'selection_rule', 'select_up_to',
      'min_selections', 1,
      'max_selections', 4,
      'stop_required', true,
      'display_stop_bar', true
    )
  from _target_case tc
  returning id
),
step_2 as (
  insert into public.cse_steps (
    case_id,
    step_number,
    step_type,
    step_kind,
    prompt,
    rationale,
    reveal_text,
    min_selections,
    max_selections,
    metadata
  )
  select
    tc.id,
    2,
    'question',
    'dm',
    'QUESTION 2 -- DECISION MAKING

The infant now has a heart rate above 100/min but continues to have labored breathing and low oxygen saturation.

What is the MOST appropriate next step?
CHOOSE ONLY ONE',
    'Data Reveal 2

If assisted ventilation is continued appropriately:
- HR rises to 128/min
- SpO2 increases gradually to 88-90%
- Spontaneous respirations improve but remain labored

If ventilation is stopped:
- HR declines into the 70s
- Cyanosis worsens

If intubation for suctioning is performed:
- Ventilation is delayed
- HR temporarily drops to 90/min

Current status (best progression):
- HR 128/min
- SpO2 90% on blended oxygen
- Moderate retractions
- Improving tone

The infant is transitioning but remains in distress.',
    'Data Reveal 2

If assisted ventilation is continued appropriately:
- HR rises to 128/min
- SpO2 increases gradually to 88-90%
- Spontaneous respirations improve but remain labored

If ventilation is stopped:
- HR declines into the 70s
- Cyanosis worsens

If intubation for suctioning is performed:
- Ventilation is delayed
- HR temporarily drops to 90/min

Current status (best progression):
- HR 128/min
- SpO2 90% on blended oxygen
- Moderate retractions
- Improving tone

The infant is transitioning but remains in distress.',
    1,
    1,
    jsonb_build_object(
      'nbrc_step_kind', 'DM',
      'selection_rule', 'choose_one',
      'min_selections', 1,
      'max_selections', 1,
      'stop_required', true,
      'display_stop_bar', true
    )
  from _target_case tc
  returning id
),
step_3 as (
  insert into public.cse_steps (
    case_id,
    step_number,
    step_type,
    step_kind,
    prompt,
    rationale,
    reveal_text,
    min_selections,
    max_selections,
    metadata
  )
  select
    tc.id,
    3,
    'question',
    'ig',
    'QUESTION 3 -- INFORMATION GATHERING

You must now reassess and determine whether escalation or transition of support is needed.

What additional information or assessments are indicated at this time?
SELECT AS MANY AS ARE APPROPRIATE (MAX 3)',
    'Data Reveal 3

The infant now demonstrates:
- HR 132/min
- SpO2 92%
- Persistent moderate retractions
- Nasal flaring
- Weak but consistent spontaneous respirations

The infant is oxygenating but still working to breathe.',
    'Data Reveal 3

The infant now demonstrates:
- HR 132/min
- SpO2 92%
- Persistent moderate retractions
- Nasal flaring
- Weak but consistent spontaneous respirations

The infant is oxygenating but still working to breathe.',
    1,
    3,
    jsonb_build_object(
      'nbrc_step_kind', 'IG',
      'selection_rule', 'select_up_to',
      'min_selections', 1,
      'max_selections', 3,
      'stop_required', true,
      'display_stop_bar', true
    )
  from _target_case tc
  returning id
),
step_4 as (
  insert into public.cse_steps (
    case_id,
    step_number,
    step_type,
    step_kind,
    prompt,
    rationale,
    reveal_text,
    min_selections,
    max_selections,
    metadata
  )
  select
    tc.id,
    4,
    'question',
    'dm',
    'QUESTION 4 -- DECISION MAKING

The infant is breathing spontaneously but with ongoing respiratory distress.

What is the MOST appropriate next intervention?
CHOOSE ONLY ONE',
    'Final Outcome

If CPAP is initiated:
- Work of breathing improves
- SpO2 stabilizes in target range
- Tone improves
- Infant is transferred to NICU for observation

If aggressive PPV is continued:
- Risk of air leak increases
- Potential hypocarbia develops

If intubation is performed unnecessarily:
- Hemodynamic instability risk increases
- Invasive intervention without clear indication',
    'Final Outcome

If CPAP is initiated:
- Work of breathing improves
- SpO2 stabilizes in target range
- Tone improves
- Infant is transferred to NICU for observation

If aggressive PPV is continued:
- Risk of air leak increases
- Potential hypocarbia develops

If intubation is performed unnecessarily:
- Hemodynamic instability risk increases
- Invasive intervention without clear indication',
    1,
    1,
    jsonb_build_object(
      'nbrc_step_kind', 'DM',
      'selection_rule', 'choose_one',
      'min_selections', 1,
      'max_selections', 1,
      'stop_required', true,
      'display_stop_bar', true,
      'final_step', true
    )
  from _target_case tc
  returning id
),

-- Step 1 choices
s1a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Warm, dry, and position the airway', true, 2,
    'Score +2: Strongly indicated initial stabilization action.',
    'Thermal control and airway positioning are immediate first priorities in neonatal resuscitation.',
    2
  from step_1
  returning id, step_id
),
s1b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Apply ECG leads or continuous heart rate monitoring', true, 2,
    'Score +2: Strongly indicated for real-time response tracking.',
    'Continuous heart-rate monitoring is essential for rapid response decisions.',
    2
  from step_1
  returning id, step_id
),
s1c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Begin positive-pressure ventilation', true, 2,
    'Score +2: Strongly indicated with weak gasping respirations and bradycardia.',
    'Prompt effective ventilation is the highest-yield intervention when respiratory effort is inadequate.',
    2
  from step_1
  returning id, step_id
),
s1d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Perform routine deep tracheal suctioning before ventilation', false, -2,
    'Score -2: Harmful due to delaying effective ventilation.',
    'Routine deep suctioning before ventilation can worsen bradycardia and delays definitive support.',
    2
  from step_1
  returning id, step_id
),
s1e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Apply preductal pulse oximeter (right hand/wrist)', true, 1,
    'Score +1: Moderately helpful to guide oxygen titration.',
    'Preductal saturation monitoring is useful, but ventilation quality is still the immediate priority.',
    2
  from step_1
  returning id, step_id
),
s1f as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'F', 'Wait to calculate the 1-minute Apgar score before intervening', false, -2,
    'Score -2: Harmful delay in active resuscitation.',
    'Apgar scoring must not delay urgent stabilization interventions.',
    2
  from step_1
  returning id, step_id
),

-- Step 2 choices
s2a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Continue assisted ventilation and titrate oxygen to target saturation', true, 2,
    'Score +2: Correct next step with ongoing distress and low SpO2.',
    'Continuing effective ventilation with oxygen titration addresses both ventilation and oxygenation targets.',
    3
  from step_2
  returning id, step_id
),
s2b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Intubate immediately for routine tracheal suctioning', false, -2,
    'Score -2: Harmful when done routinely and without clear indication.',
    'This delays appropriate support and may worsen clinical stability.',
    3
  from step_2
  returning id, step_id
),
s2c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Stop ventilatory support and observe', false, -2,
    'Score -2: Harmful; infant remains in active distress.',
    'Stopping support at this point risks rapid decompensation.',
    3
  from step_2
  returning id, step_id
),
s2d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Initiate chest compressions', false, -2,
    'Score -2: Not indicated with heart rate above 100/min.',
    'Compressions are reserved for persistent severe bradycardia despite effective ventilation.',
    3
  from step_2
  returning id, step_id
),
s2e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Increase oxygen to 100% without reassessing ventilation strategy', false, -1,
    'Score -1: Unnecessary/excessive without reassessing ventilation quality.',
    'Blind FiO2 escalation can miss the primary issue and exceed target oxygen strategy.',
    3
  from step_2
  returning id, step_id
),

-- Step 3 choices
s3a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Evaluate work of breathing and chest expansion', true, 2,
    'Score +2: Strongly indicated reassessment.',
    'Work-of-breathing and chest expansion directly determine next respiratory support decisions.',
    4
  from step_3
  returning id, step_id
),
s3b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Assess whether CPAP would be appropriate', true, 2,
    'Score +2: Strongly indicated transition planning.',
    'CPAP consideration is appropriate with spontaneous effort plus persistent distress.',
    4
  from step_3
  returning id, step_id
),
s3c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Obtain arterial blood gas immediately', false, -1,
    'Score -1: Potentially helpful later but not the immediate priority now.',
    'Immediate bedside reassessment and support adjustment are higher yield than invasive sampling first.',
    4
  from step_3
  returning id, step_id
),
s3d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Monitor SpO2 trend over several minutes', true, 1,
    'Score +1: Moderately helpful trend assessment.',
    'SpO2 trending helps verify response trajectory but should accompany direct respiratory assessment.',
    4
  from step_3
  returning id, step_id
),
s3e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Prepare for chest compressions', false, -2,
    'Score -2: Harmful/incorrect target with stable improving heart rate.',
    'Compressions are not indicated in this physiologic state and distract from needed respiratory management.',
    4
  from step_3
  returning id, step_id
),

-- Step 4 choices
s4a as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'A', 'Transition to CPAP with blended oxygen', true, 2,
    'Score +2: Correct transition strategy.',
    'CPAP with blended oxygen supports spontaneous breathing while reducing work of breathing and preserving oxygen targets.',
    null
  from step_4
  returning id, step_id
),
s4b as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'B', 'Continue aggressive PPV despite spontaneous respirations', false, -1,
    'Score -1: Excessive support risks avoidable harm.',
    'Aggressive PPV despite spontaneous respirations can increase air leak and inappropriate ventilation.',
    null
  from step_4
  returning id, step_id
),
s4c as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'C', 'Intubate and initiate mechanical ventilation', false, -1,
    'Score -1: Unnecessary escalation without current definitive indication.',
    'Invasive ventilation may be needed if deterioration occurs, but this infant is improving with noninvasive support trajectory.',
    null
  from step_4
  returning id, step_id
),
s4d as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'D', 'Discontinue oxygen and monitor', false, -2,
    'Score -2: Harmful premature withdrawal of support.',
    'Ongoing distress and support requirement make discontinuation unsafe.',
    null
  from step_4
  returning id, step_id
),
s4e as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, score_value, feedback, rationale_text, next_step_number)
  select id, 'E', 'Begin chest compressions', false, -2,
    'Score -2: Harmful and not indicated in this state.',
    'Compressions are not appropriate with strong heart rate and improving oxygenation.',
    null
  from step_4
  returning id, step_id
),

set_dm_correct_step2 as (
  update public.cse_steps s
  set correct_choice_id = c.id
  from s2a c
  where s.id = c.step_id
  returning s.id
),
set_dm_correct_step4 as (
  update public.cse_steps s
  set correct_choice_id = c.id
  from s4a c
  where s.id = c.step_id
  returning s.id
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
