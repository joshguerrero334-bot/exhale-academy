-- Exhale Academy CSE Branching Seed (COPD Critical - NPPV Failure Escalation)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case14_target (id uuid primary key) on commit drop;
create temporary table _case14_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-14-copd-critical-nppv-failure-escalation',
    'copd-critical-nppv-failure-escalation'
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
    case_number = coalesce(c.case_number, 14),
    slug = 'copd-critical-nppv-failure-escalation',
    title = 'COPD Critical (NPPV Failure Escalation)',
    intro_text = 'Critical COPD flare with rising CO2 and worsening ABGs while on BiPAP, requiring clear timing-based escalation.',
    description = 'Critical COPD branching case focused on ABG-guided escalation from NPPV to intubation.',
    stem = 'Known COPD patient in severe distress; ABGs are worsening after initial BiPAP support.',
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
    14,
    'copd-critical-nppv-failure-escalation',
    'COPD Critical (NPPV Failure Escalation)',
    'Critical COPD flare with rising CO2 and worsening ABGs while on BiPAP, requiring clear timing-based escalation.',
    'Critical COPD branching case focused on ABG-guided escalation from NPPV to intubation.',
    'Known COPD patient in severe distress; ABGs are worsening after initial BiPAP support.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case14_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":126,"rr":36,"spo2":82,"bp_sys":154,"bp_dia":94,"etco2":62}'::jsonb
where id in (select id from _case14_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case14_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case14_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case14_target)
);

delete from public.cse_attempts where case_id in (select id from _case14_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case14_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case14_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case14_target));
delete from public.cse_steps where case_id in (select id from _case14_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 68-year-old male with worsening shortness of breath, audible wheeze, and increasing fatigue despite home inhalers. Focused bedside exam is still pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "anxious, diaphoretic, tachypneic, using accessory muscles, speaking in short phrases",
      "appearance_keys_any": ["B", "C", "D", "F"],
      "show_vitals_after_submit": true,
      "vitals_keys_any": ["A", "D", "E"],
      "vitals_fields": ["spo2", "rr", "hr", "etco2"],
      "extra_reveals": [
        { "text": "ABG: pH 7.30, PaCO2 64 torr, PaO2 55 torr, HCO3 30 mEq/L.", "keys_any": ["E"] }
      ]
    }'::jsonb from _case14_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is your FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _case14_target
  union all
  select id, 3, 3, 'IG',
    '30 minutes after BiPAP initiation, the patient remains in distress. SELECT AS MANY AS INDICATED (MAX 8). What reassessment data matter most?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "still tachypneic with fatigue signs; limited improvement in work of breathing",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "etco2"],
      "extra_reveals": [
        { "text": "2-hour ABG: pH 7.25, PaCO2 70 torr, PaO2 54 torr, HCO3 30 mEq/L.", "keys_any": ["D"] }
      ]
    }'::jsonb from _case14_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. ABGs worsen in the first 2 hours on BiPAP. What is your NEXT step?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "fatigue and poor air movement are progressing",
      "show_vitals_after_submit": true,
      "vitals_fields": ["hr", "rr", "spo2", "etco2"]
    }'::jsonb from _case14_target
  union all
  select id, 5, 5, 'IG',
    'Post-intubation ventilator data: AC/VC, VT 460 mL (~7 mL/kg IBW), RR 18/min, FiO2 0.60, PEEP 5 cmH2O. ABG: pH 7.28, PaCO2 58 torr, PaO2 62 torr, HCO3 27 mEq/L. SELECT AS MANY AS INDICATED (MAX 8). What checks and ventilator adjustments are most important in the first phase?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "sedated, ventilated, improved synchrony but still high-risk",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "bp", "etco2"],
      "extra_reveals": [
        { "text": "Post-intubation ABG repeat: pH 7.30, PaCO2 54 torr, PaO2 68 torr, HCO3 26 mEq/L.", "keys_any": ["A", "B"] }
      ]
    }'::jsonb from _case14_target
  union all
  select id, 6, 6, 'DM',
    'CHOOSE ONLY ONE. What is the best disposition after stabilization begins?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "improving but still requires close monitoring",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "rr", "bp"]
    }'::jsonb from _case14_target
  returning id, step_order
)
insert into _case14_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Start controlled oxygen and continuous monitoring right away', 3, 'Correct immediate oxygen and monitoring priority.' from _case14_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess work of breathing, speaking tolerance, and mental status', 2, 'Important severity checks.' from _case14_steps s where s.step_order = 1
union all select s.id, 'C', 'Listen for wheeze versus very poor air movement', 2, 'Helps define how severe this is.' from _case14_steps s where s.step_order = 1
union all select s.id, 'D', 'Get full vitals and trend them closely', 2, 'Needed in critical status.' from _case14_steps s where s.step_order = 1
union all select s.id, 'E', 'Get ABG to guide next treatment decisions', 2, 'ABG is key for escalation timing.' from _case14_steps s where s.step_order = 1
union all select s.id, 'F', 'Check sputum color and fever history for possible infection', 1, 'Useful for antibiotic decision.' from _case14_steps s where s.step_order = 1
union all select s.id, 'G', 'Delay treatment until all nonurgent tests return', -3, 'Unsafe delay.' from _case14_steps s where s.step_order = 1
union all select s.id, 'H', 'Send for spirometry now during critical distress', -3, 'Low-value test right now and delays care.' from _case14_steps s where s.step_order = 1

union all select s.id, 'A', 'Give/increase beta-agonist, add anticholinergic, give systemic steroid, continue controlled oxygen, and start BiPAP', 3, 'Best immediate full treatment bundle.' from _case14_steps s where s.step_order = 2
union all select s.id, 'B', 'Use high-flow oxygen alone and wait', -3, 'Unsafe and incomplete treatment.' from _case14_steps s where s.step_order = 2
union all select s.id, 'C', 'Use routine antibiotics even without infection signs', -3, 'Not indicated without infection clues.' from _case14_steps s where s.step_order = 2
union all select s.id, 'D', 'Use sedative-first approach before respiratory treatment', -3, 'Dangerous sequence.' from _case14_steps s where s.step_order = 2
union all select s.id, 'E', 'Only use bronchodilator and skip ABG follow-up', -2, 'Misses critical escalation data.' from _case14_steps s where s.step_order = 2
union all select s.id, 'F', 'Start full bronchodilator/steroid bundle and controlled oxygen now, then reassess early ABG response before further escalation', 1, 'Reasonable bridge decision, but less explicit than immediate paired NPPV initiation when indicated.' from _case14_steps s where s.step_order = 2

union all select s.id, 'A', 'Repeat ABG at short interval and compare pH/PaCO2 trend', 3, 'Core NPPV failure check.' from _case14_steps s where s.step_order = 3
union all select s.id, 'B', 'Track RR, accessory-muscle use, and mental status', 2, 'Directly tracks deterioration.' from _case14_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend SpO2 and EtCO2 closely', 2, 'Important respiratory trend markers.' from _case14_steps s where s.step_order = 3
union all select s.id, 'D', 'Apply 2-hour and 4-hour NPPV response timing rules', 2, 'Needed for timely intubation decision.' from _case14_steps s where s.step_order = 3
union all select s.id, 'E', 'Watch for P/F ratio below 200', 1, 'Important hypoxemia trigger.' from _case14_steps s where s.step_order = 3
union all select s.id, 'F', 'Ignore ABGs if SpO2 looks a little better', -3, 'Can miss worsening acidosis.' from _case14_steps s where s.step_order = 3
union all select s.id, 'G', 'Wait until next shift before reassessing', -3, 'Unsafe delay.' from _case14_steps s where s.step_order = 3
union all select s.id, 'H', 'Assume BiPAP is working unless arrest occurs', -2, 'Misses early failure signs.' from _case14_steps s where s.step_order = 3

union all select s.id, 'A', 'Intubate and start mechanical ventilation now', 3, 'Correct escalation for worsening ABGs on BiPAP.' from _case14_steps s where s.step_order = 4
union all select s.id, 'B', 'Continue BiPAP unchanged for several more hours', -3, 'Unsafe delay despite clear failure criteria.' from _case14_steps s where s.step_order = 4
union all select s.id, 'C', 'Lower treatment intensity because fatigue means patient is calming down', -3, 'Dangerous misread of fatigue.' from _case14_steps s where s.step_order = 4
union all select s.id, 'D', 'Discontinue oxygen to reassess baseline', -3, 'Unsafe in severe hypoxemia.' from _case14_steps s where s.step_order = 4
union all select s.id, 'E', 'Use antibiotics only and defer ventilatory escalation', -3, 'Wrong priority in respiratory failure.' from _case14_steps s where s.step_order = 4
union all select s.id, 'F', 'Adjust BiPAP settings and repeat ABG promptly while preparing for likely intubation if trajectory stays poor', 1, 'Reasonable transitional move, but definitive intubation is stronger once failure criteria are established.' from _case14_steps s where s.step_order = 4

union all select s.id, 'A', 'Check post-intubation ABG and trend pH/PaCO2/PaO2/HCO3', 2, 'Confirms ventilation and acid-base effectiveness.' from _case14_steps s where s.step_order = 5
union all select s.id, 'B', 'Adjust ventilator settings from ABG/oxygenation (RR or VT for PaCO2/pH; FiO2/PEEP for PaO2)', 2, 'Core ventilator titration logic.' from _case14_steps s where s.step_order = 5
union all select s.id, 'C', 'Watch for complications (sepsis, PE, barotrauma, pleural effusion)', 2, 'High-risk complication surveillance.' from _case14_steps s where s.step_order = 5
union all select s.id, 'D', 'Reassess hemodynamics and perfusion frequently', 1, 'Critical stability check.' from _case14_steps s where s.step_order = 5
union all select s.id, 'E', 'Skip reassessment because patient is intubated now', -3, 'Unsafe assumption.' from _case14_steps s where s.step_order = 5
union all select s.id, 'F', 'Stop trending ABGs once one value improves', -2, 'Insufficient monitoring.' from _case14_steps s where s.step_order = 5
union all select s.id, 'G', 'Turn off alarms to reduce noise', -3, 'Dangerous monitoring practice.' from _case14_steps s where s.step_order = 5
union all select s.id, 'H', 'Plan prevention teaching for later after stabilization', 1, 'Appropriate timing for education.' from _case14_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU for ongoing ventilatory and ABG-guided management', 3, 'Best disposition for this critical case.' from _case14_steps s where s.step_order = 6
union all select s.id, 'B', 'Step down to low-acuity bed now', -3, 'Unsafe premature transfer.' from _case14_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge once SpO2 briefly reaches target', -3, 'Unsafe disposition.' from _case14_steps s where s.step_order = 6
union all select s.id, 'D', 'Keep in hallway observation with no ventilator plan', -3, 'Inadequate care setting.' from _case14_steps s where s.step_order = 6
union all select s.id, 'E', 'Transfer without structured reassessment plan', -2, 'High-risk handoff gap.' from _case14_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.id,
  'Initial critical data gathering is strong and supports immediate treatment.',
  '{"spo2": 3, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case14_steps s1 cross join _case14_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missing critical priorities delays treatment and worsens distress.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3, "etco2": 3}'::jsonb
from _case14_steps s1 cross join _case14_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Initial treatment starts correctly, but close reassessment is still needed.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case14_steps s2 cross join _case14_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Suboptimal treatment leads to worsening gas exchange risk.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 5, "bp_dia": 3, "etco2": 4}'::jsonb
from _case14_steps s2 cross join _case14_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s4.id,
  'Reassessment identifies BiPAP failure early and safely.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": 0}'::jsonb
from _case14_steps s3 cross join _case14_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Reassessment gaps delay escalation while patient deteriorates.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": 4, "bp_dia": 3, "etco2": 5}'::jsonb
from _case14_steps s3 cross join _case14_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Timely intubation stabilizes the patient trajectory.',
  '{"spo2": 5, "hr": -4, "rr": -5, "bp_sys": -2, "bp_dia": -2, "etco2": -6}'::jsonb
from _case14_steps s4 cross join _case14_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Failure to intubate on time leads to worsening respiratory failure.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": 5, "bp_dia": 4, "etco2": 6}'::jsonb
from _case14_steps s4 cross join _case14_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s6.id,
  'Post-intubation checks are solid and support safe ICU continuation.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -2}'::jsonb
from _case14_steps s5 cross join _case14_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Monitoring gaps increase risk for secondary deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 3}'::jsonb
from _case14_steps s5 cross join _case14_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient is safely managed in ICU after timely escalation from BiPAP to ventilation.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case14_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to avoidable instability and complications.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _case14_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE14_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case14_target);

commit;
