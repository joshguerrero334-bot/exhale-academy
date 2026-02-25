-- Exhale Academy CSE Branching Seed (COPD Critical - NPPV Contraindication Pathway)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case15_target (id uuid primary key) on commit drop;
create temporary table _case15_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-15-copd-critical-nppv-contraindication-pathway',
    'copd-critical-nppv-contraindication-pathway'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'copd-critical',
    disease_slug = 'copd',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 15),
    slug = 'copd-critical-nppv-contraindication-pathway',
    title = 'COPD Critical (High-Risk Airway Pathway)',
    intro_text = 'Critical COPD flare with airway protection concerns and instability, requiring direct intubation decisions.',
    description = 'Critical COPD branching case focused on recognizing when to skip NPPV and intubate immediately.',
    stem = 'Severe COPD exacerbation with airway protection concern and instability markers.',
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
    'copd-critical',
    'copd',
    'critical',
    15,
    'copd-critical-nppv-contraindication-pathway',
    'COPD Critical (High-Risk Airway Pathway)',
    'Critical COPD flare with airway protection concerns and instability, requiring direct intubation decisions.',
    'Critical COPD branching case focused on recognizing when to skip NPPV and intubate immediately.',
    'Severe COPD exacerbation with airway protection concern and instability markers.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case15_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":132,"rr":38,"spo2":80,"bp_sys":88,"bp_dia":54,"etco2":66}'::jsonb
where id in (select id from _case15_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case15_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case15_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case15_target)
);

delete from public.cse_attempts where case_id in (select id from _case15_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case15_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case15_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case15_target));
delete from public.cse_steps where case_id in (select id from _case15_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 59-year-old female with severe dyspnea, confusion, weak cough, and heavy secretions after several hours of worsening respiratory distress. Focused exam details require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "confused, very fatigued, weak cough, copious secretions, severe accessory-muscle use",
      "appearance_keys_any": ["B", "C", "D", "F"],
      "show_vitals_after_submit": true,
      "vitals_keys_any": ["A", "D", "E"],
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"],
      "extra_reveals": [
        { "text": "Airway protection is worsening with heavy secretion burden and hemodynamic instability.", "keys_any": ["F"] }
      ]
    }'::jsonb from _case15_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is your FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _case15_target
  union all
  select id, 3, 3, 'IG',
    'After intubation, ventilator data: AC/VC, VT 430 mL (~6-7 mL/kg IBW), RR 20/min, FiO2 0.70, PEEP 8 cmH2O. ABG: pH 7.21, PaCO2 72 torr, PaO2 58 torr, HCO3 28 mEq/L. SELECT AS MANY AS INDICATED (MAX 8). What should be reassessed and adjusted early?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "sedated and ventilated; perfusion and gas exchange still need close checks",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "bp", "etco2"],
      "extra_reveals": [
        { "text": "ABG repeat after adjustment: pH 7.26, PaCO2 64 torr, PaO2 66 torr, HCO3 28 mEq/L.", "keys_any": ["A", "B"] }
      ]
    }'::jsonb from _case15_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is your NEXT management decision after initial intubation stabilization?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "stabilizing slowly; still high risk for setback",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "bp", "etco2"]
    }'::jsonb from _case15_target
  union all
  select id, 5, 5, 'IG',
    'As the patient begins to improve, SELECT AS MANY AS INDICATED (MAX 8). What transition planning data are most important?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "more stable but still needs intensive monitoring and structured handoff planning",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp"]
    }'::jsonb from _case15_target
  union all
  select id, 6, 6, 'DM',
    'CHOOSE ONLY ONE. What is the most appropriate disposition plan now?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "clinical progress remains fragile and requires ICU-level continuity",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp"]
    }'::jsonb from _case15_target
  returning id, step_order
)
insert into _case15_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Start controlled oxygen and full cardiorespiratory monitoring immediately', 3, 'Correct immediate support.' from _case15_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess airway protection, mental status, and secretion clearance ability', 3, 'Directly checks airway safety and mask-ventilation risk.' from _case15_steps s where s.step_order = 1
union all select s.id, 'C', 'Check for aspiration risk and hemodynamic instability', 2, 'Critical for airway strategy.' from _case15_steps s where s.step_order = 1
union all select s.id, 'D', 'Get ABG and trend severity markers', 2, 'Supports urgent ventilatory decisions.' from _case15_steps s where s.step_order = 1
union all select s.id, 'E', 'Assess for infection clues (fever/purulent sputum) to guide antibiotics', 1, 'Appropriate targeted check.' from _case15_steps s where s.step_order = 1
union all select s.id, 'F', 'Identify airway-protection, secretion, and hemodynamic risks before choosing mask ventilation', 3, 'Key decision point in this case.' from _case15_steps s where s.step_order = 1
union all select s.id, 'G', 'Delay treatment while obtaining spirometry', -3, 'Unsafe and low-value in this moment.' from _case15_steps s where s.step_order = 1
union all select s.id, 'H', 'Ignore mental status changes because SpO2 is low anyway', -3, 'Dangerous oversight.' from _case15_steps s where s.step_order = 1

union all select s.id, 'A', 'Proceed directly to intubation now given airway protection, secretion, and instability risks', 3, 'Best action when airway protection and stability are compromised.' from _case15_steps s where s.step_order = 2
union all select s.id, 'B', 'Trial BiPAP anyway to avoid intubation', -3, 'Unsafe with airway protection and instability concerns.' from _case15_steps s where s.step_order = 2
union all select s.id, 'C', 'Treat with oxygen only and recheck later', -3, 'Insufficient in severe failure pattern.' from _case15_steps s where s.step_order = 2
union all select s.id, 'D', 'Give sedative first and decide airway later', -3, 'Dangerous sequence.' from _case15_steps s where s.step_order = 2
union all select s.id, 'E', 'Use antibiotics as the primary immediate treatment', -2, 'Not the main life-saving priority.' from _case15_steps s where s.step_order = 2
union all select s.id, 'F', 'Deliver immediate oxygen and airway-prep sequence with reassessment while moving toward definitive airway management', 1, 'Reasonable bridge, but slower than direct definitive airway action in this instability pattern.' from _case15_steps s where s.step_order = 2

union all select s.id, 'A', 'Repeat ABG and trend pH/PaCO2/PaO2/HCO3 after intubation', 2, 'Confirms full ventilatory and acid-base response.' from _case15_steps s where s.step_order = 3
union all select s.id, 'B', 'Adjust ventilator settings from ABG/oxygenation (RR or VT for PaCO2/pH; FiO2/PEEP for PaO2)', 2, 'Core post-intubation titration logic.' from _case15_steps s where s.step_order = 3
union all select s.id, 'C', 'Track hemodynamics and perfusion closely', 2, 'Needed due instability risk.' from _case15_steps s where s.step_order = 3
union all select s.id, 'D', 'Watch for complications (sepsis, pneumonia, PE, barotrauma, pleural effusion)', 2, 'Major deterioration risks.' from _case15_steps s where s.step_order = 3
union all select s.id, 'E', 'Review secretion burden and airway clearance progress', 1, 'Important airway recovery marker.' from _case15_steps s where s.step_order = 3
union all select s.id, 'F', 'Stop ABGs because ventilator is already in place', -2, 'Insufficient reassessment.' from _case15_steps s where s.step_order = 3
union all select s.id, 'G', 'Remove close monitoring after first improvement', -3, 'Unsafe de-escalation.' from _case15_steps s where s.step_order = 3
union all select s.id, 'H', 'Delay reassessment for several hours', -3, 'Dangerous delay.' from _case15_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue ventilator-guided management with frequent ABG and bedside trend checks', 3, 'Best next step for continued stabilization.' from _case15_steps s where s.step_order = 4
union all select s.id, 'B', 'Extubate early just because SpO2 improved briefly', -3, 'Unsafe premature extubation.' from _case15_steps s where s.step_order = 4
union all select s.id, 'C', 'Switch to BiPAP immediately despite persistent airway and instability risks', -3, 'Unsafe mismatch.' from _case15_steps s where s.step_order = 4
union all select s.id, 'D', 'Stop bronchodilator and steroid support now', -2, 'Premature treatment stop.' from _case15_steps s where s.step_order = 4
union all select s.id, 'E', 'Ignore complication workup while vitals look slightly better', -2, 'Can miss major secondary problems.' from _case15_steps s where s.step_order = 4
union all select s.id, 'F', 'Continue current ventilator settings briefly and repeat ABG before any major de-escalation decision', 1, 'Reasonable interim approach, but less complete than proactive ventilator-guided optimization.' from _case15_steps s where s.step_order = 4

union all select s.id, 'A', 'Confirm sustained ventilatory improvement before any de-escalation', 2, 'Core readiness check.' from _case15_steps s where s.step_order = 5
union all select s.id, 'B', 'Finalize ICU handoff priorities and return-to-escalation triggers', 2, 'Safer continuity planning.' from _case15_steps s where s.step_order = 5
union all select s.id, 'C', 'Plan infection prevention and trigger-avoidance education for later recovery phase', 1, 'Appropriate long-term planning.' from _case15_steps s where s.step_order = 5
union all select s.id, 'D', 'Review smoking cessation and COPD action planning for post-critical phase', 1, 'Important relapse prevention.' from _case15_steps s where s.step_order = 5
union all select s.id, 'E', 'Skip transition planning because ICU will handle everything automatically', -2, 'Weak handoff practice.' from _case15_steps s where s.step_order = 5
union all select s.id, 'F', 'Discontinue close checks once one ABG improves', -2, 'Not enough stability evidence.' from _case15_steps s where s.step_order = 5
union all select s.id, 'G', 'Ignore airway secretion issues after intubation', -3, 'Misses ongoing risk.' from _case15_steps s where s.step_order = 5
union all select s.id, 'H', 'Discharge planning now from ICU-level care', -3, 'Clearly premature.' from _case15_steps s where s.step_order = 5

union all select s.id, 'A', 'Continue ICU-level care with structured reassessment and escalation readiness', 3, 'Best disposition in this stage.' from _case15_steps s where s.step_order = 6
union all select s.id, 'B', 'Transfer to low-acuity floor now', -3, 'Unsafe premature transfer.' from _case15_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge home once awake', -3, 'Unsafe disposition.' from _case15_steps s where s.step_order = 6
union all select s.id, 'D', 'Hold in unstructured observation with no ICU-level plan', -3, 'Inadequate for this risk level.' from _case15_steps s where s.step_order = 6
union all select s.id, 'E', 'Step down without ABG trend stability', -2, 'Transition not justified yet.' from _case15_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '9'::jsonb, s2.id,
  'Airway-risk screening is strong and supports immediate safe airway strategy.',
  '{"spo2": 2, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": 0}'::jsonb
from _case15_steps s1 cross join _case15_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed airway and stability risks delay life-saving airway action.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": -4, "bp_dia": -3, "etco2": 4}'::jsonb
from _case15_steps s1 cross join _case15_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Immediate intubation aligns with the risk profile and stabilizes trajectory.',
  '{"spo2": 5, "hr": -4, "rr": -6, "bp_sys": 4, "bp_dia": 3, "etco2": -5}'::jsonb
from _case15_steps s2 cross join _case15_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inappropriate NPPV attempt in this high-risk patient worsens instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -5, "bp_dia": -4, "etco2": 6}'::jsonb
from _case15_steps s2 cross join _case15_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s4.id,
  'Post-intubation reassessment is complete and supports steady progress.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": 2, "bp_dia": 1, "etco2": -2}'::jsonb
from _case15_steps s3 cross join _case15_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps leave high risk for secondary deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _case15_steps s3 cross join _case15_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Management remains aligned with critical-care goals and ABG trend response.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -2}'::jsonb
from _case15_steps s4 cross join _case15_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Premature de-escalation causes avoidable instability.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _case15_steps s4 cross join _case15_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s6.id,
  'Transition planning is solid and supports safer ICU continuity.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case15_steps s5 cross join _case15_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Handoff and planning gaps increase relapse and complication risk.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _case15_steps s5 cross join _case15_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient is stabilized with appropriate ICU-level critical COPD management.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _case15_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent critical deterioration.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _case15_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE15_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case15_target);

commit;
