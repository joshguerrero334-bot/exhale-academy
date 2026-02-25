begin;

with existing_case as (
  select id, case_number
  from public.cse_cases
  where source = 'adult-airway'
    and title = 'Adult Acute Upper Airway Obstruction'
  order by created_at desc, id desc
  limit 1
),
created_case as (
  insert into public.cse_cases (
    source,
    case_number,
    title,
    stem,
    difficulty,
    is_active
  )
  select
    'adult-airway',
    coalesce((select max(case_number) + 1 from public.cse_cases where source = 'adult-airway'), 1),
    'Adult Acute Upper Airway Obstruction',
    'Adult patient with acute inspiratory stridor after allergic exposure.',
    'medium',
    true
  where not exists (select 1 from existing_case)
  returning id, case_number
),
target_case as (
  select id, case_number from existing_case
  union all
  select id, case_number from created_case
),

-- Remove old steps/choices for this case so reinserts stay clean and avoid unique(step_number) conflicts
removed_choices as (
  delete from public.cse_choices
  where step_id in (
    select s.id
    from public.cse_steps s
    join target_case tc on tc.id = s.case_id
  )
  returning id
),
removed_steps as (
  delete from public.cse_steps
  where case_id in (select id from target_case)
  returning id
),

step_1 as (
  insert into public.cse_steps (
    case_id,
    step_number,
    step_type,
    prompt,
    rationale,
    metadata
  )
  select
    tc.id,
    1,
    'question',
    'A 45-year-old male presents with acute onset inspiratory stridor following an allergic exposure. He is anxious, sitting upright, and speaking in short phrases. SpO2 is 89% on room air. HR 112. RR 28. BP 142/88.

SELECT AS MANY as are indicated.',
    'Information-gathering step for acute upper airway compromise.',
    jsonb_build_object(
      'nbrc_step_kind', 'IG',
      'max_selections', 3,
      'selection_rule', 'select_up_to',
      'scoring_model', jsonb_build_object('strongly_indicated', 2, 'moderately_indicated', 1, 'premature', -1, 'harmful', -2)
    )
  from target_case tc
  returning id
),

step_2 as (
  insert into public.cse_steps (
    case_id,
    step_number,
    step_type,
    prompt,
    rationale,
    metadata
  )
  select
    tc.id,
    2,
    'question',
    'Stridor persists despite oxygen. Patient now has mild suprasternal retractions.

CHOOSE ONLY ONE most appropriate next action.',
    'Decision-making step for escalation in persistent upper airway obstruction.',
    jsonb_build_object(
      'nbrc_step_kind', 'DM',
      'max_selections', 1,
      'selection_rule', 'choose_one',
      'scoring_model', jsonb_build_object('strongly_indicated', 2, 'insufficient', -1, 'incorrect_target', -1, 'premature', -2)
    )
  from target_case tc
  returning id
),

step_3 as (
  insert into public.cse_steps (
    case_id,
    step_number,
    step_type,
    prompt,
    rationale,
    metadata
  )
  select
    tc.id,
    3,
    'question',
    'After racemic epinephrine, stridor improves. Mild airway edema remains.

CHOOSE ONLY ONE most appropriate next action.',
    'Decision-making step for post-stabilization airway edema management.',
    jsonb_build_object(
      'nbrc_step_kind', 'DM',
      'max_selections', 1,
      'selection_rule', 'choose_one',
      'scoring_model', jsonb_build_object('strongly_indicated', 2, 'harmful', -2, 'unnecessary', -1, 'incorrect', -2)
    )
  from target_case tc
  returning id
),

s1c1 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's1_assess_accessory', 'Assess for use of accessory muscles', true,
         'Score +2 (strongly_indicated): High-yield immediate airway work-of-breathing assessment.',
         2
  from step_1
  returning id, step_id
),
s1c2 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's1_apply_nc_o2', 'Apply nasal cannula oxygen', true,
         'Score +2 (strongly_indicated): Immediate oxygen support is appropriate.',
         2
  from step_1
  returning id, step_id
),
s1c3 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's1_auscultate', 'Auscultate lung fields', true,
         'Score +1 (moderately_indicated): Useful adjunct assessment but not highest priority.',
         2
  from step_1
  returning id, step_id
),
s1c4 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's1_prepare_intubation', 'Prepare for immediate intubation', false,
         'Score -1 (premature): Escalation may be needed, but immediate intubation is premature here.',
         2
  from step_1
  returning id, step_id
),
s1c5 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's1_sputum_culture', 'Obtain sputum culture', false,
         'Score -2 (harmful): Delays management of acute airway compromise.',
         2
  from step_1
  returning id, step_id
),

s2c1 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's2_racemic_epi', 'Administer racemic epinephrine nebulization', true,
         'Score +2 (strongly_indicated): Best next action for persistent stridor from airway edema.',
         3
  from step_2
  returning id, step_id
),
s2c2 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's2_increase_nc', 'Increase nasal cannula flow', false,
         'Score -1 (insufficient): Oxygen-only escalation is inadequate for persistent obstruction.',
         3
  from step_2
  returning id, step_id
),
s2c3 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's2_albuterol', 'Administer albuterol nebulizer', false,
         'Score -1 (incorrect_target): Does not target primary upper airway edema mechanism.',
         3
  from step_2
  returning id, step_id
),
s2c4 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's2_immediate_intubation', 'Perform immediate endotracheal intubation', false,
         'Score -2 (premature): Not yet the best next step before indicated escalation threshold.',
         3
  from step_2
  returning id, step_id
),

s3c1 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's3_iv_steroids', 'Administer IV corticosteroids', true,
         'Score +2 (strongly_indicated): Appropriate management for residual airway edema.',
         null
  from step_3
  returning id, step_id
),
s3c2 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's3_stop_monitoring', 'Discontinue monitoring', false,
         'Score -2 (harmful): Ongoing monitoring is mandatory after airway instability.',
         null
  from step_3
  returning id, step_id
),
s3c3 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's3_bipap', 'Begin BiPAP', false,
         'Score -1 (unnecessary): Not first-line in this improving upper airway edema context.',
         null
  from step_3
  returning id, step_id
),
s3c4 as (
  insert into public.cse_choices (step_id, choice_key, label, is_correct, feedback, next_step_number)
  select id, 's3_diuretics', 'Administer diuretics', false,
         'Score -2 (incorrect): Does not address this clinical problem.',
         null
  from step_3
  returning id, step_id
),

set_dm_correct_step2 as (
  update public.cse_steps s
  set correct_choice_id = c.id
  from s2c1 c
  where s.id = c.step_id
  returning s.id
),

set_dm_correct_step3 as (
  update public.cse_steps s
  set correct_choice_id = c.id
  from s3c1 c
  where s.id = c.step_id
  returning s.id
)

select
  (select id from target_case limit 1) as case_id,
  (select case_number from target_case limit 1) as case_number,
  (
    select json_agg(json_build_object('step_id', s.id, 'step_number', s.step_number) order by s.step_number)
    from public.cse_steps s
    where s.case_id = (select id from target_case limit 1)
  ) as inserted_steps,
  (
    select json_agg(json_build_object('choice_id', ch.id, 'step_id', ch.step_id, 'choice_key', ch.choice_key) order by ch.step_id, ch.id)
    from public.cse_choices ch
    where ch.step_id in (
      select id from public.cse_steps where case_id = (select id from target_case limit 1)
    )
  ) as inserted_choices;

commit;
