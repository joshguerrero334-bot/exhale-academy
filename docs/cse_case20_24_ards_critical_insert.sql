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
 'Pneumonia progression with worsening hypoxemia requiring bedside ARDS recognition and early lung-protective management.',
 'ARDS critical case focused on pneumonia-triggered hypoxemia, bedside evaluation, and cause-directed escalation.',
 'Patient with worsening pneumonia has severe hypoxemia and increasing work of breathing despite oxygen escalation.',
 '{"hr":128,"rr":36,"spo2":80,"bp_sys":158,"bp_dia":92,"etco2":46}'::jsonb),
(21, 'ards-critical-sepsis-lung-protective-ventilation', 'ARDS Critical (Sepsis-Associated Lung Injury)',
 'Sepsis-associated lung injury with severe hypoxemia requiring lung-protective ventilation and hemodynamic-aware monitoring.',
 'ARDS critical case focused on sepsis-triggered lung injury, bedside recognition, and ARDSNet escalation.',
 'Septic patient develops severe oxygenation failure and diffuse lung injury.',
 '{"hr":132,"rr":34,"spo2":82,"bp_sys":146,"bp_dia":84,"etco2":44}'::jsonb),
(22, 'ards-critical-aspiration-acute-whiteout-pattern', 'ARDS Critical (Aspiration -> Acute Whiteout Pattern)',
 'Aspiration event followed by escalating oxygen requirement and bedside findings concerning for early ARDS.',
 'ARDS critical case focused on aspiration-triggered deterioration, early recognition, and cause-targeted management.',
 'Post-aspiration deterioration causes refractory hypoxemia and increasing respiratory distress.',
 '{"hr":124,"rr":35,"spo2":81,"bp_sys":152,"bp_dia":88,"etco2":47}'::jsonb),
(23, 'ards-critical-pancreatitis-prone-position-pathway', 'ARDS Critical (Pancreatitis Pathway + Prone Strategy)',
 'Pancreatitis-triggered lung injury requiring oxygenation rescue planning including prone-position consideration.',
 'ARDS critical case focused on severe oxygenation rescue sequence and monitoring.',
 'Pancreatitis patient rapidly progresses to severe hypoxemia and rising ventilatory stress.',
 '{"hr":126,"rr":33,"spo2":83,"bp_sys":148,"bp_dia":86,"etco2":45}'::jsonb),
(24, 'ards-critical-shock-inhalational-injury-mixed-trigger', 'ARDS Critical (Shock/Inhalational Mixed Trigger)',
 'Mixed-trigger lung injury in shock/inhalational exposure context with severe gas exchange failure.',
 'ARDS critical case focused on identifying noncardiogenic edema and rejecting ineffective therapies.',
 'Critically ill patient with shock history and inhalational exposure develops severe hypoxemia and diffuse lung injury.',
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
      when 20 then 'A 57-year-old man is in the ICU 2 days after severe pneumonia.

While receiving O2 by high-flow nasal cannula at an FiO2 of 0.80, the following are noted:
HR 128/min
RR 36/min
BP 158/92 mm Hg
SpO2 80%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 5).'
      when 21 then 'A 42-year-old woman with sepsis is in the ICU with worsening respiratory distress.

While receiving O2 by high-flow nasal cannula at an FiO2 of 0.75, the following are noted:
HR 132/min
RR 34/min
BP 146/84 mm Hg
SpO2 82%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 5).'
      when 22 then 'A 63-year-old man develops worsening respiratory distress after a witnessed aspiration event.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 124/min
RR 35/min
BP 152/88 mm Hg
SpO2 81%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 5).'
      when 23 then 'A 35-year-old woman with pancreatitis develops worsening respiratory distress.

While receiving O2 by high-flow nasal cannula at an FiO2 of 0.70, the following are noted:
HR 126/min
RR 33/min
BP 148/86 mm Hg
SpO2 83%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 5).'
      else 'A 49-year-old man with shock history and inhalational exposure develops rapidly worsening hypoxemia.

While receiving O2 by high-flow nasal cannula at an FiO2 of 0.80, the following are noted:
HR 136/min
RR 37/min
BP 140/82 mm Hg
SpO2 79%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 5).'
    end,
    5, 'STOP',
    case t.case_number
      when 20 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is tachypneic, anxious, and using accessory muscles",
        "extra_reveals": [
          { "text": "Chest radiograph reveals bilateral diffuse infiltrates.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.33, PaCO2 48 torr, PaO2 52 torr, HCO3 25 mEq/L. P/F ratio is severely reduced.", "keys_any": ["C"] },
          { "text": "CBC shows WBC 19,800/mm3. Sputum and blood cultures are pending.", "keys_any": ["D"] },
          { "text": "There is no evidence of cardiogenic pulmonary edema on the current assessment.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 21 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is febrile, tachypneic, and in severe respiratory distress",
        "extra_reveals": [
          { "text": "Chest radiograph reveals bilateral diffuse patchy opacities.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.31, PaCO2 46 torr, PaO2 54 torr, HCO3 23 mEq/L. P/F ratio is severely reduced.", "keys_any": ["C"] },
          { "text": "CBC shows WBC 22,400/mm3 and lactate is 4.1 mmol/L.", "keys_any": ["D"] },
          { "text": "The current hemodynamic pattern does not suggest cardiogenic pulmonary edema.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 22 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient has coarse secretions, tachypnea, and increasing distress",
        "extra_reveals": [
          { "text": "Chest radiograph reveals new bilateral patchy infiltrates.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.32, PaCO2 45 torr, PaO2 50 torr, HCO3 23 mEq/L. P/F ratio is severely reduced.", "keys_any": ["C"] },
          { "text": "Aspiration was witnessed shortly before the respiratory decline. CBC shows WBC 15,600/mm3.", "keys_any": ["D"] },
          { "text": "Cardiogenic pulmonary edema is not supported by the current findings.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 23 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is tachypneic with worsening work of breathing",
        "extra_reveals": [
          { "text": "Chest radiograph reveals bilateral diffuse infiltrates.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.34, PaCO2 44 torr, PaO2 56 torr, HCO3 24 mEq/L. P/F ratio is severely reduced.", "keys_any": ["C"] },
          { "text": "Lipase is markedly elevated, and CBC shows WBC 18,900/mm3.", "keys_any": ["D"] },
          { "text": "The current findings support noncardiogenic pulmonary edema.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is in marked respiratory distress with diffuse lung injury pattern",
        "extra_reveals": [
          { "text": "Chest radiograph reveals bilateral diffuse infiltrates.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.30, PaCO2 49 torr, PaO2 48 torr, HCO3 24 mEq/L. P/F ratio is severely reduced.", "keys_any": ["C"] },
          { "text": "CBC shows WBC 17,500/mm3 and lactate is elevated. Exposure history supports inhalational injury.", "keys_any": ["D"] },
          { "text": "The current findings support noncardiogenic pulmonary edema.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _ards_target t
  union all
  select t.case_id, 2, 2, 'DM',
    'Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb
  from _ards_target t
  union all
  select t.case_id, 3, 3, 'IG',
    'After initial management, the patient is intubated and receiving lung-protective ventilation.

Current settings are:
AC/VC
VT 6 mL/kg IBW
RR 24/min
FiO2 0.70
PEEP 10 cmH2O
Plateau pressure 28 cmH2O

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 5).',
    5, 'STOP',
    case t.case_number
      when 20 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "oxygenation improves slightly, but the patient remains critically ill",
        "extra_reveals": [
          { "text": "ABG: pH 7.29, PaCO2 52 torr, PaO2 70 torr, HCO3 24 mEq/L. P/F ratio remains below 150.", "keys_any": ["A"] },
          { "text": "Plateau pressure remains acceptable, but compliance is poor.", "keys_any": ["B"] },
          { "text": "FiO2/PEEP still require titration based on oxygenation response.", "keys_any": ["C"] },
          { "text": "Prone positioning should be considered if severe hypoxemia persists.", "keys_any": ["D"] },
          { "text": "The pneumonia source and culture results still require follow-up.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 21 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains critically ill with severe sepsis-associated lung injury",
        "extra_reveals": [
          { "text": "ABG: pH 7.28, PaCO2 50 torr, PaO2 68 torr, HCO3 23 mEq/L. P/F ratio remains below 150.", "keys_any": ["A"] },
          { "text": "Plateau pressure remains acceptable, but compliance is poor.", "keys_any": ["B"] },
          { "text": "FiO2/PEEP still require titration based on oxygenation response.", "keys_any": ["C"] },
          { "text": "Prone positioning should be considered if severe hypoxemia persists.", "keys_any": ["D"] },
          { "text": "Sepsis source control and hemodynamic support still require close follow-up.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 22 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "oxygenation remains poor after aspiration-triggered lung injury",
        "extra_reveals": [
          { "text": "ABG: pH 7.30, PaCO2 48 torr, PaO2 66 torr, HCO3 23 mEq/L. P/F ratio remains below 150.", "keys_any": ["A"] },
          { "text": "Plateau pressure remains acceptable, but compliance is poor.", "keys_any": ["B"] },
          { "text": "FiO2/PEEP still require titration based on oxygenation response.", "keys_any": ["C"] },
          { "text": "Prone positioning should be considered if severe hypoxemia persists.", "keys_any": ["D"] },
          { "text": "Aspiration-related airway clearance and infection follow-up still require attention.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 23 then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains critically ill with pancreatitis-triggered lung injury",
        "extra_reveals": [
          { "text": "ABG: pH 7.31, PaCO2 47 torr, PaO2 68 torr, HCO3 24 mEq/L. P/F ratio remains below 150.", "keys_any": ["A"] },
          { "text": "Plateau pressure remains acceptable, but compliance is poor.", "keys_any": ["B"] },
          { "text": "FiO2/PEEP still require titration based on oxygenation response.", "keys_any": ["C"] },
          { "text": "Prone positioning should be considered if severe hypoxemia persists.", "keys_any": ["D"] },
          { "text": "Pancreatitis management and hemodynamic support still require close follow-up.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains critically ill with mixed-trigger lung injury",
        "extra_reveals": [
          { "text": "ABG: pH 7.28, PaCO2 51 torr, PaO2 64 torr, HCO3 24 mEq/L. P/F ratio remains below 150.", "keys_any": ["A"] },
          { "text": "Plateau pressure remains acceptable, but compliance is poor.", "keys_any": ["B"] },
          { "text": "FiO2/PEEP still require titration based on oxygenation response.", "keys_any": ["C"] },
          { "text": "Prone positioning should be considered if severe hypoxemia persists.", "keys_any": ["D"] },
          { "text": "Shock management and inhalational-injury follow-up still require close attention.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _ards_target t
  union all
  select t.case_id, 4, 4, 'DM',
    'Which of the following should be recommended now?',
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
select s.step_id, 'A', 'Assess work of breathing and mental status', 2, 'This is indicated in the initial assessment.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'B', 'Review chest radiograph', 2, 'Essential imaging evidence.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'C', 'Obtain ABG and calculate the P/F ratio', 3, 'Critical oxygenation severity metric.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'D', 'Review likely trigger/source data, including appropriate labs', 2, 'This helps identify the ARDS trigger and guide treatment.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'E', 'Evaluate whether the pattern is more consistent with noncardiogenic than cardiogenic pulmonary edema', 2, 'Key ARDS diagnostic distinction.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'F', 'Delay oxygen escalation until all tests return', -3, 'Unsafe delay in severe hypoxemia.' from _ards_steps s where s.step_order = 1
union all select s.step_id, 'G', 'Assume this is not ARDS because wheezes are not prominent', -2, 'Incorrect physiologic reasoning.' from _ards_steps s where s.step_order = 1

union all select s.step_id, 'A', 'Treat the underlying cause and initiate lung-protective ventilation with appropriate PEEP', 3, 'Best immediate evidence-based ARDS strategy.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'B', 'Use larger tidal volumes to force CO2 clearance', -3, 'Increases ventilator-induced injury risk.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'C', 'Keep plateau pressure unconstrained if oxygenation is poor', -3, 'Unsafe; plateau should remain below 30 cmH2O.' from _ards_steps s where s.step_order = 2
union all select s.step_id, 'D', 'Treat hypoxemia only and ignore the trigger', -2, 'Incomplete management.' from _ards_steps s where s.step_order = 2

union all select s.step_id, 'A', 'Repeat ABG and reassess the P/F ratio', 2, 'Core ARDS reassessment metric.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'B', 'Trend plateau pressure and compliance', 2, 'This is indicated during lung-protective ventilation.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'C', 'Adjust FiO2 and PEEP based on oxygenation while keeping plateau pressure below 30 cmH2O', 2, 'Core ventilator titration.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'D', 'Determine whether prone positioning is indicated if severe hypoxemia persists', 2, 'Evidence-based rescue planning.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'E', 'Follow the trigger-specific source data and hemodynamic response', 1, 'This remains important for continuity of care.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'F', 'Stop close monitoring after one slight SpO2 improvement', -3, 'Unsafe de-escalation.' from _ards_steps s where s.step_order = 3
union all select s.step_id, 'G', 'Delay reassessment for several hours', -3, 'Dangerous in critical ARDS.' from _ards_steps s where s.step_order = 3

union all select s.step_id, 'A', 'Continue ICU-level ARDS management with lung-protective ventilation and rescue-escalation criteria', 3, 'Best disposition/continuity plan.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'B', 'Transfer to a low-acuity floor once oxygenation improves briefly', -3, 'Unsafe premature transfer.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'C', 'Discharge after temporary oxygenation improvement', -3, 'Unsafe disposition.' from _ards_steps s where s.step_order = 4
union all select s.step_id, 'D', 'Observe without a structured ARDS escalation plan', -2, 'Inadequate for a critical trajectory.' from _ards_steps s where s.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'The bedside evaluation supports severe noncardiogenic lung injury requiring urgent ARDS management.',
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
  'Cause-directed therapy and lung-protective ventilation are started.',
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
  'Reassessment supports continued ICU-level ARDS management and rescue planning.',
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
