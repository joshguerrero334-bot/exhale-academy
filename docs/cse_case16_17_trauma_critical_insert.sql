-- Combined runner for case 16 + case 17
-- Generated: 2026-02-24

-- Exhale Academy CSE Branching Seed (Trauma Critical - Tension Pneumothorax)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case16_target (id uuid primary key) on commit drop;
create temporary table _case16_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-16-trauma-critical-tension-pneumothorax',
    'trauma-critical-tension-pneumothorax'
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
    case_number = coalesce(c.case_number, 16),
    slug = 'trauma-critical-tension-pneumothorax',
    title = 'Trauma Critical (Tension Pneumothorax)',
    intro_text = 'Chest trauma with signs of tension pneumothorax requiring immediate decompression before routine imaging.',
    description = 'Critical trauma branching case focused on recognizing unstable tension pneumothorax and immediate treatment sequence.',
    stem = 'Trauma patient with severe distress, unilateral absent breath sounds, and hemodynamic instability.',
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
    16,
    'trauma-critical-tension-pneumothorax',
    'Trauma Critical (Tension Pneumothorax)',
    'Chest trauma with signs of tension pneumothorax requiring immediate decompression before routine imaging.',
    'Critical trauma branching case focused on recognizing unstable tension pneumothorax and immediate treatment sequence.',
    'Trauma patient with severe distress, unilateral absent breath sounds, and hemodynamic instability.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case16_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":48,"rr":38,"spo2":78,"bp_sys":78,"bp_dia":46,"etco2":58}'::jsonb
where id in (select id from _case16_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case16_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case16_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case16_target)
);

delete from public.cse_attempts where case_id in (select id from _case16_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case16_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case16_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case16_target));
delete from public.cse_steps where case_id in (select id from _case16_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 34-year-old male after a motorcycle crash who now has sudden chest pain and rapidly worsening respiratory distress. Focused chest exam is still pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "cyanotic, severe distress, unilateral chest movement reduction",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"],
      "extra_reveals": [
        { "text": "Trachea appears shifted away from affected side.", "keys_any": ["B", "D"] }
      ]
    }'::jsonb from _case16_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _case16_target
  union all
  select id, 3, 3, 'IG',
    'Ten minutes after the initial intervention, SELECT AS MANY AS INDICATED (MAX 8). What reassessment checks are most important NEXT?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "improving oxygenation but still unstable trauma physiology",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"]
    }'::jsonb from _case16_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the best NEXT management/disposition plan?',
    null, 'STOP', '{}'::jsonb from _case16_target
  returning id, step_order
)
insert into _case16_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Recognize sudden distress with increased work of breathing and severe chest pain', 2, 'Core tension-pneumothorax presentation.' from _case16_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess tracheal/mediastinal shift away from affected side', 3, 'High-priority sign in unstable unilateral pleural emergency.' from _case16_steps s where s.step_order = 1
union all select s.id, 'C', 'Find hyperresonant percussion and absent/diminished unilateral breath sounds', 3, 'Classic pneumothorax bedside pattern.' from _case16_steps s where s.step_order = 1
union all select s.id, 'D', 'Check for cyanosis, tachypnea, and hemodynamic instability pattern', 2, 'Confirms life-threatening severity.' from _case16_steps s where s.step_order = 1
union all select s.id, 'E', 'Delay treatment until chest x-ray is completed', -3, 'Unsafe in unstable tension physiology.' from _case16_steps s where s.step_order = 1
union all select s.id, 'F', 'Prioritize nonurgent PFT testing before emergency intervention', -3, 'Incorrect sequence in critical trauma.' from _case16_steps s where s.step_order = 1
union all select s.id, 'G', 'Ignore unilateral exam asymmetry if pulse oximetry is low', -3, 'Dangerous oversight.' from _case16_steps s where s.step_order = 1
union all select s.id, 'H', 'Evaluate for ventilator alarm pattern if intubated (rising pressure/falling VT)', 1, 'Helpful contextual clue when ventilated.' from _case16_steps s where s.step_order = 1

union all select s.id, 'A', 'Give 100% oxygen and perform immediate needle decompression/thoracostomy, then chest tube', 3, 'Correct lifesaving sequence.' from _case16_steps s where s.step_order = 2
union all select s.id, 'B', 'Get chest x-ray first, then decide if decompression is needed', -3, 'Unsafe delay in unstable tension pneumothorax.' from _case16_steps s where s.step_order = 2
union all select s.id, 'C', 'Provide analgesics only and reassess later', -3, 'Misses definitive emergency intervention.' from _case16_steps s where s.step_order = 2
union all select s.id, 'D', 'Start antibiotics as primary immediate therapy', -2, 'Not primary lifesaving action.' from _case16_steps s where s.step_order = 2
union all select s.id, 'E', 'Give 100% oxygen and call for immediate procedural support while decompression setup is prepared', 1, 'Helpful bridge action, but incomplete unless decompression proceeds immediately.' from _case16_steps s where s.step_order = 2

union all select s.id, 'A', 'Confirm improved oxygenation/hemodynamics and chest expansion trend', 2, 'Required post-intervention check.' from _case16_steps s where s.step_order = 3
union all select s.id, 'B', 'Obtain chest x-ray after decompression/chest tube to confirm status', 2, 'Correct timing for imaging confirmation.' from _case16_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend ABG (pH/PaCO2/PaO2/HCO3) and ventilatory status for persistent failure; if intubated, document mode/VT/RR/FiO2/PEEP and adjust RR/VT/FiO2/PEEP', 2, 'Supports escalation decisions.' from _case16_steps s where s.step_order = 3
union all select s.id, 'D', 'Continue close monitoring for recurrence or secondary deterioration', 2, 'High-yield safety monitoring.' from _case16_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop close monitoring immediately after brief improvement', -3, 'Unsafe de-escalation.' from _case16_steps s where s.step_order = 3
union all select s.id, 'F', 'Delay reassessment for several hours', -3, 'Dangerous delay.' from _case16_steps s where s.step_order = 3
union all select s.id, 'G', 'Ignore ventilator alarms if SpO2 transiently improves', -2, 'Can miss persistent pleural problem.' from _case16_steps s where s.step_order = 3
union all select s.id, 'H', 'Recommend bronchopulmonary hygiene once stabilized', 1, 'Reasonable supportive care after stabilization.' from _case16_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue ICU-level care with chest tube management and escalation readiness', 3, 'Best disposition for this stage.' from _case16_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to low-acuity floor immediately after chest tube placement', -3, 'Unsafe premature transfer.' from _case16_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge after one improved pulse-ox reading', -3, 'Unsafe disposition.' from _case16_steps s where s.step_order = 4
union all select s.id, 'D', 'Remove chest tube early because symptoms improved once', -3, 'High recurrence risk and unsafe timing.' from _case16_steps s where s.step_order = 4
union all select s.id, 'E', 'Continue monitored care with serial imaging and hemodynamic checks before considering transfer', 1, 'Reasonable but less complete than explicit ICU-level escalation-ready plan.' from _case16_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Critical findings were identified quickly, supporting immediate intervention.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case16_steps s1 cross join _case16_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Key signs were missed, increasing immediate decompensation risk.',
  '{"spo2": -5, "hr": -4, "rr": 4, "bp_sys": -8, "bp_dia": -6, "etco2": 4}'::jsonb
from _case16_steps s1 cross join _case16_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Timely decompression and chest-tube pathway stabilize trajectory.',
  '{"spo2": 8, "hr": 12, "rr": -6, "bp_sys": 14, "bp_dia": 10, "etco2": -5}'::jsonb
from _case16_steps s2 cross join _case16_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Delay or incorrect treatment worsens shock and gas-exchange failure.',
  '{"spo2": -7, "hr": -8, "rr": 4, "bp_sys": -10, "bp_dia": -8, "etco2": 6}'::jsonb
from _case16_steps s2 cross join _case16_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Reassessment is complete and supports safer ongoing care.',
  '{"spo2": 2, "hr": 4, "rr": -2, "bp_sys": 4, "bp_dia": 2, "etco2": -2}'::jsonb
from _case16_steps s3 cross join _case16_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps leave high risk for recurrence and deterioration.',
  '{"spo2": -4, "hr": -4, "rr": 3, "bp_sys": -6, "bp_dia": -4, "etco2": 3}'::jsonb
from _case16_steps s3 cross join _case16_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: tension pneumothorax was managed with correct emergency sequence and ICU continuity.',
  '{"spo2": 1, "hr": 2, "rr": -1, "bp_sys": 2, "bp_dia": 1, "etco2": -1}'::jsonb
from _case16_steps s4
where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed or premature de-escalation leads to recurrent instability.',
  '{"spo2": -6, "hr": -6, "rr": 4, "bp_sys": -8, "bp_dia": -6, "etco2": 5}'::jsonb
from _case16_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE16_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case16_target);

commit;


-- Exhale Academy CSE Branching Seed (Trauma Critical - Hemothorax)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case17_target (id uuid primary key) on commit drop;
create temporary table _case17_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-17-trauma-critical-hemothorax',
    'trauma-critical-hemothorax'
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
    case_number = coalesce(c.case_number, 17),
    slug = 'trauma-critical-hemothorax',
    title = 'Trauma Critical (Hemothorax)',
    intro_text = 'Chest trauma with pleural blood accumulation requiring drainage and close oxygenation monitoring.',
    description = 'Critical trauma branching case focused on hemothorax recognition and drainage-first treatment pathway.',
    stem = 'Trauma patient with unilateral dullness, reduced breath sounds, and suspected pleural blood loss.',
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
    17,
    'trauma-critical-hemothorax',
    'Trauma Critical (Hemothorax)',
    'Chest trauma with pleural blood accumulation requiring drainage and close oxygenation monitoring.',
    'Critical trauma branching case focused on hemothorax recognition and drainage-first treatment pathway.',
    'Trauma patient with unilateral dullness, reduced breath sounds, and suspected pleural blood loss.',
    'hard',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case17_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":126,"rr":34,"spo2":84,"bp_sys":146,"bp_dia":90,"etco2":50}'::jsonb
where id in (select id from _case17_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case17_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case17_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case17_target)
);

delete from public.cse_attempts where case_id in (select id from _case17_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case17_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case17_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case17_target));
delete from public.cse_steps where case_id in (select id from _case17_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 47-year-old female after blunt chest trauma with pleuritic pain, dyspnea, and unilateral chest expansion asymmetry. Focused percussion/auscultation findings require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "dyspneic, tachypneic, chest pain with bruising over affected side",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"]
    }'::jsonb from _case17_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment plan?',
    null, 'STOP', '{}'::jsonb from _case17_target
  union all
  select id, 3, 3, 'IG',
    'Thirty minutes after pleural drainage begins, SELECT AS MANY AS INDICATED (MAX 8). What reassessment priorities are most important NEXT?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "work of breathing improved but remains high-risk",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr", "bp", "etco2"]
    }'::jsonb from _case17_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the best NEXT management/disposition after initial stabilization?',
    null, 'STOP', '{}'::jsonb from _case17_target
  returning id, step_order
)
insert into _case17_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Identify severe chest pain, dyspnea/tachypnea, and trauma context', 2, 'Core presentation.' from _case17_steps s where s.step_order = 1
union all select s.id, 'B', 'Find unilateral dull/flat percussion with decreased fremitus and diminished breath sounds', 3, 'High-yield hemothorax exam pattern.' from _case17_steps s where s.step_order = 1
union all select s.id, 'C', 'Check CBC for reduced RBC/Hb/Hct when bleeding is suspected', 2, 'Supports blood-loss severity assessment.' from _case17_steps s where s.step_order = 1
union all select s.id, 'D', 'Order chest x-ray looking for increased radiodensity and shift away from affected side', 2, 'Appropriate diagnostic pattern.' from _case17_steps s where s.step_order = 1
union all select s.id, 'E', 'Assume hyperresonance on affected side confirms hemothorax', -3, 'Hyperresonance favors pneumothorax, not hemothorax.' from _case17_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay treatment decisions until PFT is performed', -3, 'Unsafe and low-value in acute trauma.' from _case17_steps s where s.step_order = 1
union all select s.id, 'G', 'Ignore possible hemoptysis because it is not relevant to trauma', -2, 'Can be clinically relevant finding.' from _case17_steps s where s.step_order = 1
union all select s.id, 'H', 'Skip oxygen because blood loss is the only issue', -3, 'Unsafe in hypoxemia.' from _case17_steps s where s.step_order = 1

union all select s.id, 'A', 'Give 100% oxygen and perform thoracentesis/chest tube to drain pleural blood', 3, 'Correct immediate strategy.' from _case17_steps s where s.step_order = 2
union all select s.id, 'B', 'Use analgesics only and observe first', -3, 'Misses definitive drainage need.' from _case17_steps s where s.step_order = 2
union all select s.id, 'C', 'Delay drainage and start hyperinflation therapy first', -3, 'Wrong sequence; drainage first.' from _case17_steps s where s.step_order = 2
union all select s.id, 'D', 'Start antibiotics as sole immediate intervention', -2, 'Not primary lifesaving step.' from _case17_steps s where s.step_order = 2
union all select s.id, 'E', 'Give oxygen and prepare immediate pleural drainage setup while trauma team is mobilized', 1, 'Helpful early coordination, but drainage must still be performed without delay.' from _case17_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend oxygenation, hemodynamics, and chest-drain response', 2, 'Core reassessment bundle.' from _case17_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat chest imaging and ABG (pH/PaCO2/PaO2/HCO3) as clinically indicated; if intubated, document mode/VT/RR/FiO2/PEEP and adjust RR/VT/FiO2/PEEP', 2, 'Supports ongoing stabilization decisions.' from _case17_steps s where s.step_order = 3
union all select s.id, 'C', 'Continue blood-loss monitoring with CBC/Hb/Hct trend', 2, 'Tracks bleeding severity and response.' from _case17_steps s where s.step_order = 3
union all select s.id, 'D', 'Add hyperinflation therapy and bronchopulmonary hygiene after drainage', 2, 'Appropriate post-drainage support.' from _case17_steps s where s.step_order = 3
union all select s.id, 'E', 'Stop close monitoring after first temporary SpO2 improvement', -3, 'Unsafe de-escalation.' from _case17_steps s where s.step_order = 3
union all select s.id, 'F', 'Ignore worsening hypoxemia because chest tube is in place', -3, 'Can miss deterioration/ARDS risk.' from _case17_steps s where s.step_order = 3
union all select s.id, 'G', 'Delay reassessment for several hours', -3, 'Dangerous delay.' from _case17_steps s where s.step_order = 3
union all select s.id, 'H', 'Avoid ventilatory support despite clear failure signs', -3, 'Unsafe when ventilatory failure emerges.' from _case17_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue ICU-level care with chest-tube management and escalation readiness', 3, 'Best disposition for ongoing risk.' from _case17_steps s where s.step_order = 4
union all select s.id, 'B', 'Transfer to low-acuity floor immediately', -3, 'Unsafe premature transfer.' from _case17_steps s where s.step_order = 4
union all select s.id, 'C', 'Discharge once pain improves', -3, 'Unsafe disposition.' from _case17_steps s where s.step_order = 4
union all select s.id, 'D', 'Stop oxygen early because drainage was done', -2, 'Potentially unsafe if hypoxemia persists.' from _case17_steps s where s.step_order = 4
union all select s.id, 'E', 'Continue monitored care with serial chest-tube output and oxygenation reassessment before step-down', 1, 'Reasonable transitional plan but less protective than explicit ICU escalation-readiness.' from _case17_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Hemothorax pattern recognition is strong and supports rapid treatment.',
  '{"spo2": 1, "hr": -2, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _case17_steps s1 cross join _case17_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed hemothorax clues delay drainage and worsen risk.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3, "etco2": 3}'::jsonb
from _case17_steps s1 cross join _case17_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Drainage-first treatment is appropriate and stabilizes trajectory.',
  '{"spo2": 6, "hr": -5, "rr": -4, "bp_sys": -2, "bp_dia": -1, "etco2": -4}'::jsonb
from _case17_steps s2 cross join _case17_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Delayed or incomplete treatment leads to worsening instability.',
  '{"spo2": -6, "hr": 7, "rr": 4, "bp_sys": 5, "bp_dia": 3, "etco2": 5}'::jsonb
from _case17_steps s2 cross join _case17_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.id,
  'Post-drainage reassessment is complete and safety-focused.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _case17_steps s3 cross join _case17_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Monitoring gaps increase risk of recurrent hypoxemia and failure.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 3}'::jsonb
from _case17_steps s3 cross join _case17_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: hemothorax is managed with drainage, oxygenation support, and ICU continuity.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _case17_steps s4
where s4.step_order = 4
union all
select s4.id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed treatment and weak monitoring lead to avoidable deterioration.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _case17_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE17_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case17_target);

commit;
