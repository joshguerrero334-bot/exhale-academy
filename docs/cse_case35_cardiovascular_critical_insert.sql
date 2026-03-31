-- Exhale Academy CSE Branching Seed (Case 35)
-- Cardiovascular Critical (Pulmonary Embolism Post-Op Sudden Deadspace)

begin;

create temporary table _case35_target (id uuid primary key) on commit drop;
create temporary table _case35_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'adult-cardiovascular-critical',
    disease_slug = 'pulmonary-embolism',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 35),
    slug = 'cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace',
    title = 'Cardiovascular Critical (Pulmonary Embolism Post-Op Sudden Deadspace)',
    intro_text = 'Postoperative patient with abrupt dyspnea, hypoxemia, and hemodynamic instability requiring bedside recognition of pulmonary embolism.',
    description = 'Critical PE case focused on sudden dead-space physiology, targeted testing, and urgent anticoagulation or thrombolytic escalation.',
    stem = 'Post-op patient develops sudden dyspnea and hypoxemia with hemodynamic strain.',
    difficulty = 'hard',
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
    'adult-cardiovascular-critical',
    'pulmonary-embolism',
    'critical',
    35,
    'cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace',
    'Cardiovascular Critical (Pulmonary Embolism Post-Op Sudden Deadspace)',
    'Postoperative patient with abrupt dyspnea, hypoxemia, and hemodynamic instability requiring bedside recognition of pulmonary embolism.',
    'Critical PE case focused on sudden dead-space physiology, targeted testing, and urgent anticoagulation or thrombolytic escalation.',
    'Post-op patient develops sudden dyspnea and hypoxemia with hemodynamic strain.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case35_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":132,"rr":34,"spo2":79,"bp_sys":94,"bp_dia":58,"etco2":28}'::jsonb
where id in (select id from _case35_target);

delete from public.cse_attempt_events
where attempt_id in (select a.id from public.cse_attempts a where a.case_id in (select id from _case35_target))
   or step_id in (select s.id from public.cse_steps s where s.case_id in (select id from _case35_target))
   or outcome_id in (
      select o.id from public.cse_outcomes o
      join public.cse_steps s on s.id = o.step_id
      where s.case_id in (select id from _case35_target)
   );

delete from public.cse_attempts where case_id in (select id from _case35_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case35_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case35_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case35_target));
delete from public.cse_steps where case_id in (select id from _case35_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
'A 55-year-old woman is on postoperative day 2 after orthopedic surgery and suddenly becomes short of breath.

While receiving O2 by nasal cannula at 4 L/min, the following are noted:
HR 132/min
RR 34/min
BP 94/58 mm Hg
SpO2 79%
EtCO2 28 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).',
  4, 'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "the patient is anxious and tachypneic",
    "extra_reveals": [
      { "text": "Breath sounds are clear bilaterally.", "keys_any": ["A"] },
      { "text": "The patient reports sudden pleuritic chest pain and one episode of hemoptysis.", "keys_any": ["B"] },
      { "text": "ABG: pH 7.47, PaCO2 30 torr, PaO2 52 torr, HCO3 22 mEq/L.", "keys_any": ["C"] },
      { "text": "ECG reveals sinus tachycardia with new right-heart strain pattern.", "keys_any": ["D"] },
      { "text": "CBC shows hemoglobin 11.4 g/dL and platelets 240,000/mm3.", "keys_any": ["E"] }
    ]
  }'::jsonb from _case35_target
  union all
  select id, 2, 2, 'DM',
'Findings suggest acute pulmonary embolism with hemodynamic strain. Which of the following should be recommended FIRST?',
  null, 'STOP', '{}'::jsonb from _case35_target
  union all
  select id, 3, 3, 'IG',
'After initial treatment is started, the patient remains unstable.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 128/min
RR 32/min
BP 88/54 mm Hg
SpO2 84%
EtCO2 26 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).',
  4, 'STOP',
  '{
    "show_appearance_after_submit": true,
    "appearance_text": "the patient remains anxious and poorly perfused",
    "extra_reveals": [
      { "text": "Bedside echocardiography reveals right-ventricular dilation and strain.", "keys_any": ["A"] },
      { "text": "Lower-extremity ultrasound reveals acute deep venous thrombosis.", "keys_any": ["B"] },
      { "text": "Lactate is 3.8 mmol/L.", "keys_any": ["C"] },
      { "text": "Systemic thrombolytic therapy should be considered because hypotension persists.", "keys_any": ["D"] },
      { "text": "Repeat ABG: pH 7.46, PaCO2 29 torr, PaO2 56 torr, HCO3 21 mEq/L.", "keys_any": ["E"] }
    ]
  }'::jsonb from _case35_target
  union all
  select id, 4, 4, 'DM',
'Hypotension persists with evidence of right-heart strain. Which of the following should be recommended now?',
  null, 'STOP', '{}'::jsonb from _case35_target
  returning id, step_order
)
insert into _case35_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Auscultate breath sounds', 2, 'This is indicated in the initial assessment.' from _case35_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess for sudden pleuritic chest pain and hemoptysis', 2, 'This is indicated in the initial assessment.' from _case35_steps s where s.step_order = 1
union all select s.id, 'C', 'Obtain an ABG', 2, 'This helps define gas-exchange severity.' from _case35_steps s where s.step_order = 1
union all select s.id, 'D', 'Review the ECG', 2, 'This helps assess for right-heart strain and competing diagnoses.' from _case35_steps s where s.step_order = 1
union all select s.id, 'E', 'Review the CBC', 1, 'This provides useful supporting data before anticoagulation.' from _case35_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay treatment until CT angiography is completed', -3, 'This delays indicated therapy in an unstable patient.' from _case35_steps s where s.step_order = 1
union all select s.id, 'G', 'Transfer the patient to an unmonitored area', -3, 'This is unsafe.' from _case35_steps s where s.step_order = 1

union all select s.id, 'A', 'Provide high-concentration oxygen, support hemodynamics, and activate the urgent PE treatment pathway with anticoagulation readiness', 3, 'This is the best first treatment in this situation.' from _case35_steps s where s.step_order = 2
union all select s.id, 'B', 'Use oxygen only and wait for imaging before beginning PE-specific treatment', -3, 'This is inadequate.' from _case35_steps s where s.step_order = 2
union all select s.id, 'C', 'Give a large fluid bolus only and reassess later', -2, 'This does not address the primary problem.' from _case35_steps s where s.step_order = 2
union all select s.id, 'D', 'Transfer to a regular floor bed when saturation improves briefly', -3, 'This is unsafe.' from _case35_steps s where s.step_order = 2

union all select s.id, 'A', 'Obtain bedside echocardiography results', 2, 'This helps assess right-heart strain.' from _case35_steps s where s.step_order = 3
union all select s.id, 'B', 'Assess for deep venous thrombosis with lower-extremity ultrasound', 2, 'This is appropriate supporting evaluation.' from _case35_steps s where s.step_order = 3
union all select s.id, 'C', 'Review the lactate and perfusion trend', 2, 'This helps quantify ongoing shock.' from _case35_steps s where s.step_order = 3
union all select s.id, 'D', 'Determine whether thrombolytic therapy is now indicated', 2, 'This is the key escalation decision.' from _case35_steps s where s.step_order = 3
union all select s.id, 'E', 'Repeat the ABG', 1, 'This provides supporting data.' from _case35_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop close monitoring after the first response', -3, 'This is unsafe.' from _case35_steps s where s.step_order = 3
union all select s.id, 'G', 'Delay escalation until the next routine reassessment cycle', -3, 'This is unsafe.' from _case35_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue ICU-level management and begin definitive PE rescue therapy because shock persists', 3, 'This is the best next step.' from _case35_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue the same therapy unchanged for several hours', -3, 'This delays indicated escalation.' from _case35_steps s where s.step_order = 4
union all select s.id, 'C', 'Transfer to an unmonitored bed', -3, 'This is not an appropriate level of care.' from _case35_steps s where s.step_order = 4
union all select s.id, 'D', 'Discharge after transient oxygenation improvement', -3, 'This is unsafe.' from _case35_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Pulmonary embolism findings are identified, and hypoxemia persists with hemodynamic strain.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case35_steps s1 cross join _case35_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Assessment is incomplete, and instability worsens.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-6,"bp_dia":-4,"etco2":2}'::jsonb
from _case35_steps s1 cross join _case35_steps s2 where s1.step_order = 1 and s2.step_order = 2
union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Initial PE treatment is started, but shock persists.',
  '{"spo2":4,"hr":-2,"rr":-2,"bp_sys":-4,"bp_dia":-2,"etco2":-1}'::jsonb
from _case35_steps s2 cross join _case35_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Treatment is inadequate, and shock worsens.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-8,"bp_dia":-5,"etco2":3}'::jsonb
from _case35_steps s2 cross join _case35_steps s3 where s2.step_order = 2 and s3.step_order = 3
union all
select s3.id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.id,
  'Reassessment confirms massive PE physiology requiring rescue-level treatment.',
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _case35_steps s3 cross join _case35_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Delayed reassessment allows worsening shock and hypoxemia.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-6,"bp_dia":-4,"etco2":2}'::jsonb
from _case35_steps s3 cross join _case35_steps s4 where s3.step_order = 3 and s4.step_order = 4
union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: the patient remains in the ICU for definitive PE rescue therapy and hemodynamic monitoring.',
  '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":2,"bp_dia":1,"etco2":-1}'::jsonb
from _case35_steps s4 where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to recurrent cardiovascular collapse.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-8,"bp_dia":-5,"etco2":3}'::jsonb
from _case35_steps s4 where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE35_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
    'bp_dia', coalesce((b.baseline_vitals->>'bp_dia')::int, 0) + coalesce((r.vitals_delta->>'bp_dia')::int, 0),
    'etco2', coalesce((b.baseline_vitals->>'etco2')::int, 0) + coalesce((r.vitals_delta->>'etco2')::int, 0)
  )
from public.cse_rules r
join public.cse_steps s on s.id = r.step_id
join public.cse_cases b on b.id = s.case_id
where s.case_id in (select id from _case35_target);

commit;
