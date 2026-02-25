-- Combined runner for cases 20-24 (ARDS critical series)
-- Generated: 2026-02-24

-- Requires docs/cse_branching_engine_migration.sql,
-- docs/cse_case_taxonomy_migration.sql, and docs/cse_outcomes_vitals_migration.sql

begin;

create temporary table _ards_case_seed (
  case_number int4 primary key,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null
) on commit drop;

insert into _ards_case_seed (case_number, slug, title, intro_text, description, stem, baseline_vitals)
values
(20, 'ards-critical-pneumonia-refractory-hypoxemia', 'ARDS Critical (Pneumonia -> Refractory Hypoxemia)',
 'Pneumonia progression with acute bilateral infiltrates and refractory hypoxemia.',
 'ARDS critical case focused on cause-directed treatment and ARDSNet escalation.',
 'Patient with worsening pneumonia now has severe hypoxemia despite oxygen escalation.',
 '{"hr":128,"rr":36,"spo2":80,"bp_sys":158,"bp_dia":92,"etco2":46}'::jsonb),
(21, 'ards-critical-sepsis-lung-protective-ventilation', 'ARDS Critical (Sepsis-Associated Lung Injury)',
 'Sepsis-associated ARDS requiring strict lung-protective ventilation strategy.',
 'ARDS critical case focused on ARDSNet settings and hemodynamic-aware monitoring.',
 'Septic patient develops bilateral opacities, low compliance, and severe oxygenation failure.',
 '{"hr":132,"rr":34,"spo2":82,"bp_sys":146,"bp_dia":84,"etco2":44}'::jsonb),
(22, 'ards-critical-aspiration-acute-whiteout-pattern', 'ARDS Critical (Aspiration -> Acute Whiteout Pattern)',
 'Aspiration event followed by diffuse infiltrates and escalating oxygen requirement.',
 'ARDS critical case focused on early recognition and cause-targeted management.',
 'Post-aspiration deterioration with bilateral radiopacity and refractory hypoxemia.',
 '{"hr":124,"rr":35,"spo2":81,"bp_sys":152,"bp_dia":88,"etco2":47}'::jsonb),
(23, 'ards-critical-pancreatitis-prone-position-pathway', 'ARDS Critical (Pancreatitis Pathway + Prone Strategy)',
 'Pancreatitis-triggered ARDS requiring oxygenation rescue planning including prone positioning.',
 'ARDS critical case focused on severe oxygenation rescue sequence and monitoring.',
 'Pancreatitis patient rapidly progresses to ARDS with poor oxygenation and rising ventilatory stress.',
 '{"hr":126,"rr":33,"spo2":83,"bp_sys":148,"bp_dia":86,"etco2":45}'::jsonb),
(24, 'ards-critical-shock-inhalational-injury-mixed-trigger', 'ARDS Critical (Shock/Inhalational Mixed Trigger)',
 'Mixed-trigger ARDS (shock/toxin inhalation context) with severe gas exchange failure.',
 'ARDS critical case focused on identifying noncardiogenic edema and rejecting ineffective therapies.',
 'Critically ill patient with shock history and inhalational exposure develops diffuse ARDS pattern.',
 '{"hr":136,"rr":37,"spo2":79,"bp_sys":140,"bp_dia":82,"etco2":48}'::jsonb);

create temporary table _ards_target (case_number int4 primary key, case_id uuid not null) on commit drop;

with existing as (
  select s.case_number, c.id
  from _ards_case_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = 'ards-critical',
    disease_slug = 'ards',
    disease_track = 'critical',
    case_number = coalesce(c.case_number, s.case_number),
    slug = s.slug,
    title = s.title,
    intro_text = s.intro_text,
    description = s.description,
    stem = s.stem,
    difficulty = 'hard',
    is_active = true,
    is_published = true,
    baseline_vitals = s.baseline_vitals
  from _ards_case_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty, is_active, is_published, baseline_vitals
  )
  select
    'ards-critical',
    'ards',
    'critical',
    s.case_number,
    s.slug,
    s.title,
    s.intro_text,
    s.description,
    s.stem,
    'hard',
    true,
    true,
    s.baseline_vitals
  from _ards_case_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _ards_target (case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

-- Clear prior branching content for these cases.
delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _ards_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _ards_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _ards_target)
);

delete from public.cse_attempts where case_id in (select case_id from _ards_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _ards_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _ards_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _ards_target));
delete from public.cse_steps where case_id in (select case_id from _ards_target);

create temporary table _ards_steps (
  case_number int4 not null,
  step_order int4 not null,
  step_id uuid not null,
  primary key (case_number, step_order)
) on commit drop;

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case t.case_number
      when 20 then 'You are called to bedside for a 57-year-old male in the ICU 2 days after severe pneumonia who now has rapidly worsening dyspnea and oxygenation despite supplemental oxygen. Focused exam and diagnostics require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 21 then 'You are called to bedside for a 42-year-old female after major trauma who has escalating tachypnea, increasing oxygen needs, and bilateral respiratory distress. Focused exam and diagnostics require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 22 then 'You are called to bedside for a 63-year-old male after aspiration event who now has severe hypoxemia and increased work of breathing that is not improving as expected. Focused exam and diagnostics require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 23 then 'You are called to bedside for a 35-year-old female with sepsis and worsening respiratory failure who is becoming increasingly tachypneic and hypoxemic. Focused exam and diagnostics require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      else 'You are called to bedside for a 49-year-old male with shock and rapidly worsening oxygenation despite escalating support. Focused exam and diagnostics require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"],"extra_reveals":[{"text":"CXR: bilateral infiltrates with ground-glass opacities.","keys_any":["A","B","E"]}]}'::jsonb
  from _ards_target t
  union all
  select t.case_id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is your FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb
  from _ards_target t
  union all
  select t.case_id, 3, 3, 'IG',
    'After initial management, ventilator data: AC/VC, VT 6 mL/kg IBW, RR 24/min, FiO2 0.70, PEEP 10 cmH2O, plateau pressure 28 cmH2O. ABG: pH 7.27, PaCO2 55 torr, PaO2 64 torr, HCO3 24 mEq/L. SELECT AS MANY AS INDICATED (MAX 8). Which reassessment data and ventilator adjustments drive next decisions?',
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"],"extra_reveals":[{"text":"ABG repeat: pH 7.29, PaCO2 52 torr, PaO2 70 torr, HCO3 24 mEq/L; PaO2/FiO2 remains below 150.","keys_any":["A","B","C"]}]}'::jsonb
  from _ards_target t
  union all
  select t.case_id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the best escalation/disposition plan now?',
    null, 'STOP', '{}'::jsonb
  from _ards_target t
  returning case_id, step_order, id
)
insert into _ards_steps (case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _ards_target t on t.case_id = i.case_id;

-- Options: same clinical structure across ARDS set for scoring consistency.
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.step_id, 'A', 'Confirm acute onset (<1 week), severe distress signs, and likely ARDS trajectory', 2, 'Core syndrome recognition.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'B', 'Review chest x-ray for bilateral infiltrates/ground-glass radiopacity pattern', 2, 'Essential imaging evidence.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'C', 'Get ABG with PaO2 and calculate P/F ratio on PEEP >= 5', 3, 'Critical oxygenation severity metric.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'D', 'Differentiate noncardiogenic edema profile from cardiogenic process', 2, 'Key ARDS diagnostic distinction.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'E', 'Use hemodynamic monitoring trend (elevated PAP with normal PCWP tendency)', 1, 'Supports noncardiogenic interpretation.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'F', 'Delay oxygen escalation until all tests return', -3, 'Unsafe delay in severe hypoxemia.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'G', 'Ignore infection workup despite possible pneumonia source', -2, 'Misses treatable trigger.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'H', 'Assume normal compliance if breath sounds are present', -2, 'Incorrect ARDS physiologic reasoning.' from _ards_steps s where s.step_order = 1

union all select s.step_id, 'A', 'Treat underlying cause + oxygen up to FiO2 60%, add PEEP, and apply ARDSNet lung-protective ventilation', 3, 'Best immediate evidence-based ARDS strategy.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'B', 'Use larger tidal volumes to force CO2 clearance', -3, 'Increases ventilator-induced injury risk.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'C', 'Keep plateau pressure unconstrained if oxygenation is poor', -3, 'Unsafe; plateau should remain <30 cmH2O.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'D', 'Start ineffective ARDS therapy bundle (beta-agonist, NAC, surfactant routine use)', -3, 'Not recommended ARDS treatment path.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'E', 'Treat hypoxemia only and ignore underlying trigger', -2, 'Incomplete management.' from _ards_steps s where s.step_order = 2

union all select s.step_id, 'A', 'Trend ABG, P/F ratio, plateau pressure, and ventilator response', 3, 'Core ARDS reassessment metrics.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'B', 'Apply permissive hypercapnia threshold (allow rising PaCO2 if pH >= 7.20)', 2, 'Appropriate ARDSNet principle.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'C', 'If persistent severe hypoxemia, consider prone positioning up to 16 hours', 2, 'Evidence-based oxygenation rescue approach.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'D', 'Adjust RR/VT for pH/PaCO2 and FiO2/PEEP for PaO2 while keeping plateau pressure < 30', 2, 'Core ventilator titration from ABG and oxygenation.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'E', 'Stop close monitoring after one slight SpO2 improvement', -3, 'Unsafe de-escalation.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'F', 'Delay reassessment for several hours', -3, 'Dangerous in critical ARDS.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'G', 'Use PA catheter as routine ARDS therapy target', -2, 'Not recommended routine therapy approach.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'H', 'Avoid prone/rescue options despite refractory hypoxemia', -2, 'May miss effective escalation.' from _ards_steps s where s.step_order = 3

union all select s.step_id, 'A', 'Continue ICU-level ARDS management with lung-protective ventilation and structured escalation plan', 3, 'Best disposition/continuity plan.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'B', 'Transfer to low-acuity floor once FiO2 briefly decreases', -3, 'Unsafe premature transfer.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'C', 'Discharge after temporary oxygenation improvement', -3, 'Unsafe disposition.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'D', 'Keep unstructured observation without ARDS escalation criteria', -2, 'Inadequate for critical trajectory.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'E', 'Continue ineffective ARDS therapies as primary plan', -3, 'Contradicts recommended management.' from _ards_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'ARDS diagnostic priorities were captured early, supporting timely management.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _ards_steps s1
join _ards_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Diagnostic gaps delay critical ARDS treatment timing.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 3}'::jsonb
from _ards_steps s1
join _ards_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1

union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Evidence-based ARDS treatment started with cause-directed and lung-protective strategy.',
  '{"spo2": 4, "hr": -3, "rr": -3, "bp_sys": -1, "bp_dia": -1, "etco2": -2}'::jsonb
from _ards_steps s2
join _ards_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Suboptimal treatment increases refractory hypoxemia and injury risk.',
  '{"spo2": -6, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 3, "etco2": 4}'::jsonb
from _ards_steps s2
join _ards_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2

union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment and rescue planning are strong for critical ARDS continuity.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1, "etco2": -1}'::jsonb
from _ards_steps s3
join _ards_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring and escalation gaps leave high risk for deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2, "etco2": 3}'::jsonb
from _ards_steps s3
join _ards_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3

union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: ARDS is managed with evidence-based critical care and safe ICU continuity.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _ards_steps s4
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: inadequate ARDS strategy causes avoidable progression and instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _ards_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'ARDS' || t.case_number::text || '_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
join _ards_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _ards_target);

commit;
