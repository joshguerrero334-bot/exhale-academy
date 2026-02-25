-- Combined runner for case 18 + case 19
-- Generated: 2026-02-24

-- Exhale Academy CSE Branching Seed (Trauma Critical - Flail Chest with Pulmonary Contusion)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case18_target (id uuid primary key) on commit drop;
create temporary table _case18_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-18-trauma-critical-flail-chest-contusion',
    'trauma-critical-flail-chest-contusion'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'trauma-critical',
    disease_slug = 'chest-trauma',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 18),
    slug = 'trauma-critical-flail-chest-contusion',
    title = 'Trauma Critical (Flail Chest + Pulmonary Contusion)',
    intro_text = 'Blunt chest trauma with paradoxical movement and worsening oxygenation requiring high-priority stabilization.',
    description = 'Critical trauma branching case focused on flail chest recognition, oxygenation support, pain control, and escalation.',
    stem = 'Trauma patient has paradoxical chest movement, chest pain, and progressive hypoxemia.',
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
    'trauma-critical',
    'chest-trauma',
    'critical',
    18,
    'trauma-critical-flail-chest-contusion',
    'Trauma Critical (Flail Chest + Pulmonary Contusion)',
    'Blunt chest trauma with paradoxical movement and worsening oxygenation requiring high-priority stabilization.',
    'Critical trauma branching case focused on flail chest recognition, oxygenation support, pain control, and escalation.',
    'Trauma patient has paradoxical chest movement, chest pain, and progressive hypoxemia.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case18_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":132,"rr":36,"spo2":81,"bp_sys":162,"bp_dia":96,"etco2":52}'::jsonb
where id in (select id from _case18_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case18_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case18_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case18_target)
);

delete from public.cse_attempts where case_id in (select id from _case18_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case18_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case18_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case18_target));
delete from public.cse_steps where case_id in (select id from _case18_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 29-year-old male after blunt chest trauma with severe pain, shallow breaths, and visible paradoxical chest-wall motion. Focused chest assessment is still pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "severe pain, paradoxical segment movement, tachypnea",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"],
      "extra_reveals": [
        { "text": "Chest imaging shows patchy unilateral alveolar opacities with increasing oxygenation deficit.", "keys_any": ["A", "B", "D"] }
      ]
    }'::jsonb from _case18_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment plan now?',
    null, 'STOP', '{}'::jsonb from _case18_target
  union all
  select id, 3, 3, 'IG',
    'Fifteen minutes after initial treatment, SELECT AS MANY AS INDICATED (MAX 8). What reassessment data are most important NEXT?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "ongoing distress but partial response",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"]
    }'::jsonb from _case18_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. If ventilatory failure progresses, what is the best NEXT escalation/disposition?',
    null, 'STOP', '{}'::jsonb from _case18_target
  returning id, step_order
)
insert into _case18_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Recognize flail chest pattern (>=3 adjacent rib fractures with paradoxical movement)', 3, 'Core diagnosis signal.' from _case18_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess bruising, unilateral expansion limits, and work of breathing severity', 2, 'High-yield trauma exam priorities.' from _case18_steps s where s.step_order = 1
union all select s.id, 'C', 'Check for hemoptysis and pain-limited ventilation pattern', 1, 'Helpful supporting data.' from _case18_steps s where s.step_order = 1
union all select s.id, 'D', 'Order chest x-ray and ABG to assess contusion/hypoxemia severity', 2, 'Important severity confirmation.' from _case18_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay treatment until all nonurgent studies return', -3, 'Unsafe delay.' from _case18_steps s where s.step_order = 1
union all select s.id, 'F', 'Send for PFT first in acute distress', -3, 'Low-value and unsafe in this phase.' from _case18_steps s where s.step_order = 1
union all select s.id, 'G', 'Ignore paradoxical movement because oxygen is low anyway', -3, 'Dangerous misinterpretation.' from _case18_steps s where s.step_order = 1
union all select s.id, 'H', 'Skip CBC despite possible blood loss concern', -2, 'Misses bleeding assessment.' from _case18_steps s where s.step_order = 1

union all select s.id, 'A', 'Give 100% oxygen, provide analgesia, and start aggressive monitoring with escalation readiness', 3, 'Best immediate stabilization pattern.' from _case18_steps s where s.step_order = 2
union all select s.id, 'B', 'Use analgesia only and reassess later', -3, 'Insufficient treatment.' from _case18_steps s where s.step_order = 2
union all select s.id, 'C', 'Avoid oxygen to prevent masking deterioration', -3, 'Unsafe in hypoxemia.' from _case18_steps s where s.step_order = 2
union all select s.id, 'D', 'Delay treatment pending formal rib imaging report', -3, 'Unsafe delay.' from _case18_steps s where s.step_order = 2
union all select s.id, 'E', 'Initiate oxygen and analgesia with tight reassessment while preparing escalation if ABG/oxygenation worsen', 1, 'Reasonable interim pathway but less decisive than full escalation-ready trauma plan.' from _case18_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend ABG/oxygenation for worsening hypoxemia and ventilatory failure', 2, 'Core escalation monitoring.' from _case18_steps s where s.step_order = 3
union all select s.id, 'B', 'Track RR, fatigue, and mental status closely', 2, 'Identifies failure trajectory.' from _case18_steps s where s.step_order = 3
union all select s.id, 'C', 'Monitor for pulmonary contusion progression and ARDS risk', 2, 'High-yield trauma complication focus.' from _case18_steps s where s.step_order = 3
union all select s.id, 'D', 'Add bronchopulmonary hygiene and hyperinflation therapy once stabilized enough', 1, 'Appropriate supportive therapy timing.' from _case18_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop monitoring after one short-term improvement', -3, 'Unsafe de-escalation.' from _case18_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay reassessment for several hours', -3, 'Dangerous delay.' from _case18_steps s where s.step_order = 3
union all select s.id, 'G', 'Ignore worsening hypoxemia if pain seems better', -3, 'Can miss respiratory collapse.' from _case18_steps s where s.step_order = 3
union all select s.id, 'H', 'Avoid considering mechanical ventilation despite failure signs', -3, 'Unsafe escalation failure.' from _case18_steps s where s.step_order = 3

union all select s.id, 'A', 'Escalate to mechanical ventilation with PEEP and ICU care when ventilatory failure appears', 3, 'Correct escalation/disposition.' from _case18_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to low-acuity floor despite worsening ABGs', -3, 'Unsafe transfer.' from _case18_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge once pain improves', -3, 'Unsafe disposition.' from _case18_steps s where s.step_order = 4
union all select s.id, 'D', 'Ignore surgical stabilization discussion in severe flail segment', -2, 'May miss needed intervention in severe cases.' from _case18_steps s where s.step_order = 4
union all select s.id, 'E', 'Continue high-acuity monitoring with explicit ABG/oxygenation escalation thresholds before transfer', 1, 'Reasonable pathway but less definitive than immediate ICU ventilatory strategy when failure is progressing.' from _case18_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial recognition is strong and supports early stabilization.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case18_steps s1 cross join _case18_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed trauma priorities delay stabilization and worsen oxygenation.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3, "etco2": 3}'::jsonb
from _case18_steps s1 cross join _case18_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Early oxygen, analgesia, and monitoring improve trajectory.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1, "etco2": -2}'::jsonb
from _case18_steps s2 cross join _case18_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Suboptimal management increases progression risk to ventilatory failure.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 5, "bp_dia": 3, "etco2": 4}'::jsonb
from _case18_steps s2 cross join _case18_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Reassessment is complete and supports timely escalation decisions.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case18_steps s3 cross join _case18_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps increase contusion-related deterioration risk.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 3}'::jsonb
from _case18_steps s3 cross join _case18_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: flail chest trajectory is stabilized with appropriate escalation and ICU continuity.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _case18_steps s4
where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to worsening respiratory failure risk.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _case18_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE18_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case18_target);

commit;


-- Exhale Academy CSE Branching Seed (Trauma Critical - Ventilator Pneumothorax Deterioration)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case19_target (id uuid primary key) on commit drop;
create temporary table _case19_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-19-trauma-critical-ventilator-pneumothorax',
    'trauma-critical-ventilator-pneumothorax'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'trauma-critical',
    disease_slug = 'chest-trauma',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, 19),
    slug = 'trauma-critical-ventilator-pneumothorax',
    title = 'Trauma Critical (Ventilator-Associated Pneumothorax Deterioration)',
    intro_text = 'Ventilated trauma patient develops abrupt pressure/volume alarm changes suggesting pneumothorax.',
    description = 'Critical trauma branching case focused on ventilator clue recognition and urgent pleural intervention.',
    stem = 'Intubated trauma patient suddenly shows rising airway pressure and falling tidal volume with hypoxemia.',
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
    'trauma-critical',
    'chest-trauma',
    'critical',
    19,
    'trauma-critical-ventilator-pneumothorax',
    'Trauma Critical (Ventilator-Associated Pneumothorax Deterioration)',
    'Ventilated trauma patient develops abrupt pressure/volume alarm changes suggesting pneumothorax.',
    'Critical trauma branching case focused on ventilator clue recognition and urgent pleural intervention.',
    'Intubated trauma patient suddenly shows rising airway pressure and falling tidal volume with hypoxemia.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case19_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":124,"rr":30,"spo2":79,"bp_sys":86,"bp_dia":52,"etco2":60}'::jsonb
where id in (select id from _case19_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case19_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case19_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case19_target)
);

delete from public.cse_attempts where case_id in (select id from _case19_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case19_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case19_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case19_target));
delete from public.cse_steps where case_id in (select id from _case19_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 52-year-old female on mechanical ventilation after trauma who suddenly desaturates and triggers high-pressure alarms. Current settings: AC/VC, VT 450 mL, RR 16/min, FiO2 0.60, PEEP 5 cmH2O. ABG: pH 7.24, PaCO2 60 torr, PaO2 56 torr, HCO3 26 mEq/L. Focused airway/chest assessment is still pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "ventilator alarms active; oxygenation worsening",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"],
      "extra_reveals": [
        { "text": "Airway pressures rose sharply and delivered tidal volume dropped.", "keys_any": ["A", "B"] },
        { "text": "ABG repeat: pH 7.27, PaCO2 55 torr, PaO2 64 torr, HCO3 25 mEq/L.", "keys_any": ["A", "B", "D"] }
      ]
    }'::jsonb from _case19_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _case19_target
  union all
  select id, 3, 3, 'IG',
    'Fifteen minutes after intervention, SELECT AS MANY AS INDICATED (MAX 8). Which reassessment priorities are critical NEXT?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "partially stabilized but remains high risk",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"]
    }'::jsonb from _case19_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the best NEXT continuing management/disposition?',
    null, 'STOP', '{}'::jsonb from _case19_target
  returning id, step_order
)
insert into _case19_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Identify abrupt rise in airway pressure with reduced tidal volume as pneumothorax warning', 3, 'Key ventilator clue.' from _case19_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess unilateral breath-sound loss and hyperresonance pattern', 2, 'Supports diagnosis rapidly.' from _case19_steps s where s.step_order = 1
union all select s.id, 'C', 'Recognize worsening hypoxemia/hemodynamic instability trajectory', 2, 'Confirms critical severity.' from _case19_steps s where s.step_order = 1
union all select s.id, 'D', 'Order urgent chest x-ray while preparing treatment', 1, 'Useful if it does not delay lifesaving intervention.' from _case19_steps s where s.step_order = 1
union all select s.id, 'E', 'Ignore ventilator mechanics and focus only on sedation dose', -3, 'Dangerous miss.' from _case19_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay intervention until ABG is repeated twice', -3, 'Unsafe delay.' from _case19_steps s where s.step_order = 1
union all select s.id, 'G', 'Assume alarm artifact because trauma patient is intubated', -3, 'Unsafe assumption.' from _case19_steps s where s.step_order = 1
union all select s.id, 'H', 'Stop monitoring once SpO2 briefly rises', -2, 'Risky de-escalation.' from _case19_steps s where s.step_order = 1

union all select s.id, 'A', 'Give 100% oxygen, urgently decompress/insert chest tube, and adjust vent strategy to lower peak pressures', 3, 'Correct immediate sequence.' from _case19_steps s where s.step_order = 2
union all select s.id, 'B', 'Increase tidal volume and PIP to force oxygenation improvement', -3, 'Can worsen barotrauma/instability.' from _case19_steps s where s.step_order = 2
union all select s.id, 'C', 'Wait for routine imaging before pleural intervention', -3, 'Unsafe delay in unstable pattern.' from _case19_steps s where s.step_order = 2
union all select s.id, 'D', 'Use bronchodilator only and reassess later', -2, 'Insufficient for pleural emergency.' from _case19_steps s where s.step_order = 2
union all select s.id, 'E', 'Lower injurious ventilator pressures and call for immediate pleural procedure support while preparing decompression', 1, 'Helpful bridge, but definitive pleural intervention still must occur immediately.' from _case19_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend ventilator mechanics, oxygenation, and hemodynamics continuously', 2, 'Core reassessment bundle.' from _case19_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat ABG (pH/PaCO2/PaO2/HCO3) and chest imaging to confirm response and risk', 2, 'Supports ongoing adjustment with full gas-exchange data.' from _case19_steps s where s.step_order = 3
union all select s.id, 'C', 'Continue chest tube patency and recurrence surveillance', 2, 'Essential after decompression.' from _case19_steps s where s.step_order = 3
union all select s.id, 'D', 'Adjust RR/VT for PaCO2-pH and FiO2/PEEP for PaO2 while monitoring pressure limits', 2, 'Core ventilator titration logic after decompression.' from _case19_steps s where s.step_order = 3
union all select s.id, 'E', 'Remove close monitoring after first improvement', -3, 'Unsafe de-escalation.' from _case19_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay reassessment for several hours', -3, 'Dangerous delay.' from _case19_steps s where s.step_order = 3
union all select s.id, 'G', 'Ignore persistent hypotension if SpO2 improves a little', -3, 'Misses unstable physiology.' from _case19_steps s where s.step_order = 3
union all select s.id, 'H', 'Avoid ventilator setting optimization after tube placement', -2, 'Incomplete management.' from _case19_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue ICU-level management with structured ventilator and chest-tube reassessment', 3, 'Best ongoing plan.' from _case19_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to low-acuity floor once alarms quiet briefly', -3, 'Unsafe premature transition.' from _case19_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge once awake and oxygen briefly improves', -3, 'Unsafe disposition.' from _case19_steps s where s.step_order = 4
union all select s.id, 'D', 'Stop ventilator optimization because chest tube is enough', -2, 'Incomplete approach.' from _case19_steps s where s.step_order = 4
union all select s.id, 'E', 'Continue high-acuity monitoring with documented ventilator and recurrence reassessment triggers', 1, 'Reasonable but less complete than explicit ICU-level trajectory plan.' from _case19_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Ventilator-complication pattern was recognized quickly.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case19_steps s1 cross join _case19_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed ventilator warning signs increase collapse risk.',
  '{"spo2": -5, "hr": 5, "rr": 3, "bp_sys": -5, "bp_dia": -4, "etco2": 4}'::jsonb
from _case19_steps s1 cross join _case19_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Immediate decompression and vent optimization improve stability.',
  '{"spo2": 7, "hr": -4, "rr": -4, "bp_sys": 8, "bp_dia": 6, "etco2": -5}'::jsonb
from _case19_steps s2 cross join _case19_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inadequate intervention worsens respiratory/hemodynamic failure.',
  '{"spo2": -7, "hr": 7, "rr": 4, "bp_sys": -8, "bp_dia": -6, "etco2": 6}'::jsonb
from _case19_steps s2 cross join _case19_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Reassessment is structured and supports safe ICU continuation.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 2, "bp_dia": 1, "etco2": -2}'::jsonb
from _case19_steps s3 cross join _case19_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps leave high risk for recurrent deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -3, "bp_dia": -2, "etco2": 3}'::jsonb
from _case19_steps s3 cross join _case19_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: ventilator-associated pneumothorax deterioration is managed with timely intervention and ICU continuity.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case19_steps s4
where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed treatment and poor monitoring cause recurrent instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _case19_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE19_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case19_target);

commit;
