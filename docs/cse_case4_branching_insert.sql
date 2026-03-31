-- Exhale Academy CSE Case #4 Branching Seed (Nocturnal Dyspnea / Fluid Overload)
-- Rewritten to reveal findings through selected assessments.

begin;

create temporary table _case4_target (id uuid primary key) on commit drop;
create temporary table _case4_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-4-nocturnal-dyspnea-fluid-overload-crisis'
     or lower(coalesce(title, '')) like '%case 4%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-fluid-overload-respiratory-crisis',
    disease_slug = 'cardiogenic-pulmonary-edema',
    disease_track = 'acute',
    case_number = 4,
    slug = 'case-4-nocturnal-dyspnea-fluid-overload-crisis',
    title = 'Case 4 -- Nocturnal Dyspnea Fluid Overload Crisis',
    intro_text = 'Adult with sudden nocturnal dyspnea and fluid-overload physiology requiring bedside evaluation, noninvasive support, and monitored admission planning.',
    description = 'Branching case focused on acute cardiogenic pulmonary edema that improves with early pressure support and medical therapy.',
    stem = 'Patient awakens with acute dyspnea and orthopnea requiring rapid bedside assessment and pressure-support treatment.',
    difficulty = 'medium',
    is_active = true,
    is_published = true
  where c.id in (select id from existing)
  returning c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty, is_active, is_published
  )
  select
    'adult-fluid-overload-respiratory-crisis',
    'cardiogenic-pulmonary-edema',
    'acute',
    4,
    'case-4-nocturnal-dyspnea-fluid-overload-crisis',
    'Case 4 -- Nocturnal Dyspnea Fluid Overload Crisis',
    'Adult with sudden nocturnal dyspnea and fluid-overload physiology requiring bedside evaluation, noninvasive support, and monitored admission planning.',
    'Branching case focused on acute cardiogenic pulmonary edema that improves with early pressure support and medical therapy.',
    'Patient awakens with acute dyspnea and orthopnea requiring rapid bedside assessment and pressure-support treatment.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case4_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":122,"rr":32,"spo2":82,"bp_sys":176,"bp_dia":102}'::jsonb
where id in (select id from _case4_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case4_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case4_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case4_target)
);

delete from public.cse_attempts where case_id in (select id from _case4_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case4_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case4_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case4_target));
delete from public.cse_steps where case_id in (select id from _case4_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata
  )
  select id, 1, 1, 'IG',
'A 67-year-old woman awakens suddenly because of shortness of breath and cannot lie flat.

While breathing room air, the following are noted:
HR 122/min
RR 32/min
BP 176/102 mm Hg
SpO2 82%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "the patient is anxious and using accessory muscles",
      "extra_reveals": [
        { "text": "Breath sounds reveal diffuse crackles bilaterally.", "keys_any": ["A"] },
        { "text": "Pink frothy sputum is present.", "keys_any": ["B"] },
        { "text": "Chest radiograph reveals cardiomegaly with bilateral perihilar infiltrates.", "keys_any": ["C"] },
        { "text": "ABG: pH 7.33, PaCO2 47 torr, PaO2 50 torr, HCO3 24 mEq/L.", "keys_any": ["D"] },
        { "text": "BNP is markedly elevated.", "keys_any": ["E"] }
      ]
    }'::jsonb from _case4_target
  union all
  select id, 2, 2, 'DM',
'The findings are most consistent with acute cardiogenic pulmonary edema. Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb from _case4_target
  union all
  select id, 3, 3, 'IG',
'After oxygen therapy, noninvasive ventilation, and medical treatment are started, the patient improves but remains ill.

While receiving NPPV with an FiO2 of 0.60, the following are noted:
HR 108/min
RR 26/min
BP 158/92 mm Hg
SpO2 90%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
    4, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "work of breathing is improved, but crackles remain",
      "extra_reveals": [
        { "text": "Repeat ABG: pH 7.36, PaCO2 44 torr, PaO2 66 torr, HCO3 24 mEq/L.", "keys_any": ["A"] },
        { "text": "Urine output increases after diuretic therapy, and blood pressure remains adequate.", "keys_any": ["B"] },
        { "text": "Mental status is intact, and the patient is less anxious than on arrival.", "keys_any": ["C"] },
        { "text": "Serum potassium is 3.4 mEq/L and creatinine is 1.4 mg/dL.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case4_target
  union all
  select id, 4, 4, 'DM',
'Gas exchange improves with treatment and the patient no longer appears to be failing noninvasive support. Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb from _case4_target
  returning id, step_order
)
insert into _case4_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Auscultate breath sounds', 2, 'This is indicated in the initial bedside assessment.' from _case4_steps s where s.step_order = 1
union all select s.id, 'B', 'Inspect the sputum', 2, 'This helps identify cardiogenic edema pattern.' from _case4_steps s where s.step_order = 1
union all select s.id, 'C', 'Review the chest radiograph', 2, 'This helps confirm pulmonary edema.' from _case4_steps s where s.step_order = 1
union all select s.id, 'D', 'Obtain an ABG', 2, 'This helps define gas-exchange severity.' from _case4_steps s where s.step_order = 1
union all select s.id, 'E', 'Review the BNP', 1, 'This supports the diagnosis but is less urgent than bedside stabilization data.' from _case4_steps s where s.step_order = 1
union all select s.id, 'F', 'Obtain bedside spirometry', -3, 'This is not indicated during acute respiratory distress.' from _case4_steps s where s.step_order = 1
union all select s.id, 'G', 'Delay treatment until all studies are completed', -3, 'This delays indicated therapy.' from _case4_steps s where s.step_order = 1

union all select s.id, 'A', 'Position upright, provide oxygen, begin NPPV, and support diuretic and vasodilator therapy while monitoring blood pressure', 3, 'This is the best first treatment in this situation.' from _case4_steps s where s.step_order = 2
union all select s.id, 'B', 'Use low-flow nasal cannula and observe for 30 minutes', -3, 'This is inadequate for the current severity.' from _case4_steps s where s.step_order = 2
union all select s.id, 'C', 'Give a rapid fluid bolus for tachycardia', -3, 'This may worsen cardiogenic pulmonary edema.' from _case4_steps s where s.step_order = 2
union all select s.id, 'D', 'Proceed directly to intubation before attempting noninvasive support', -1, 'This may become necessary later, but it is not the best first step while mentation is preserved.' from _case4_steps s where s.step_order = 2

union all select s.id, 'A', 'Repeat the ABG', 2, 'This is indicated to assess the response to therapy.' from _case4_steps s where s.step_order = 3
union all select s.id, 'B', 'Monitor urine output and blood pressure response', 2, 'This helps assess response to diuretic and vasodilator therapy.' from _case4_steps s where s.step_order = 3
union all select s.id, 'C', 'Reassess mental status and work of breathing', 2, 'This helps determine whether NPPV is succeeding.' from _case4_steps s where s.step_order = 3
union all select s.id, 'D', 'Review serum potassium and renal function', 1, 'This is appropriate after early diuresis.' from _case4_steps s where s.step_order = 3
union all select s.id, 'E', 'Plan discharge if oxygen saturation briefly improves', -3, 'This is premature.' from _case4_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop close monitoring after the first response', -3, 'This is unsafe.' from _case4_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue monitored admission with NPPV weaning, oxygen titration, and ongoing diuretic therapy', 3, 'This is the safest next step after partial improvement.' from _case4_steps s where s.step_order = 4
union all select s.id, 'B', 'Discharge home with outpatient follow-up later in the week', -3, 'This is unsafe.' from _case4_steps s where s.step_order = 4
union all select s.id, 'C', 'Transfer to an unmonitored bed immediately', -3, 'This does not provide appropriate surveillance.' from _case4_steps s where s.step_order = 4
union all select s.id, 'D', 'Remove NPPV and oxygen because the ABG improved', -2, 'This is premature de-escalation.' from _case4_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Diffuse crackles and cardiogenic edema findings are identified. Severe hypoxemia persists.',
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0}'::jsonb
from _case4_steps s1 cross join _case4_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete, and the patient becomes more distressed.',
  '{"spo2": -4, "hr": 6, "rr": 3, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case4_steps s1 cross join _case4_steps s2 where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Oxygenation improves with pressure support and medical therapy.',
  '{"spo2": 8, "hr": -10, "rr": -6, "bp_sys": -12, "bp_dia": -8}'::jsonb
from _case4_steps s2 cross join _case4_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Hypoxemia and work of breathing worsen because treatment is inadequate.',
  '{"spo2": -6, "hr": 8, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case4_steps s2 cross join _case4_steps s3 where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.id,
  'Gas exchange and hemodynamics improve enough to continue noninvasive care in a monitored setting.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case4_steps s3 cross join _case4_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps increase the risk of recurrent respiratory failure.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case4_steps s3 cross join _case4_steps s4 where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient is admitted for continued monitored treatment of cardiogenic pulmonary edema.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case4_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: premature de-escalation leads to recurrent respiratory distress.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case4_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE4_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
  r.rule_priority,
  r.rule_type,
  r.rule_value,
  r.next_step_id,
  r.outcome_text,
  jsonb_build_object(
    'hr', coalesce((b.baseline_vitals->>'hr')::int, 0) + coalesce((r.vitals_delta->>'hr')::int, 0),
    'rr', coalesce((b.baseline_vitals->>'rr')::int, 0) + coalesce((r.vitals_delta->>'rr')::int, 0),
    'spo2', coalesce((b.baseline_vitals->>'spo2')::int, 0) + coalesce((r.vitals_delta->>'spo2')::int, 0),
    'bp_sys', coalesce((b.baseline_vitals->>'bp_sys')::int, 0) + coalesce((r.vitals_delta->>'bp_sys')::int, 0),
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
where s.case_id in (select id from _case4_target);

commit;
