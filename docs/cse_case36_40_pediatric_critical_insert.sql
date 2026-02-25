-- Exhale Academy CSE Branching Seed (Cases 36-40)
-- Pediatric critical cases: Croup, Epiglottitis, Bronchiolitis, Cystic Fibrosis, Foreign Body Aspiration
-- Requires docs/cse_branching_engine_migration.sql,
-- docs/cse_case_taxonomy_migration.sql, and docs/cse_outcomes_vitals_migration.sql

begin;

create temporary table _ped_seed (
  case_number int4 primary key,
  disease_key text not null,
  source text not null,
  disease_slug text not null,
  slug text not null,
  title text not null,
  intro_text text not null,
  description text not null,
  stem text not null,
  baseline_vitals jsonb not null,
  nbrc_category_code text not null,
  nbrc_category_name text not null,
  nbrc_subcategory text
) on commit drop;

insert into _ped_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(36, 'croup', 'pediatric-critical-airway', 'croup', 'pediatric-critical-croup-gradual-barking-stridor',
 'Pediatric Critical (Croup Gradual Barking Stridor)',
 'Gradual viral upper-airway process with barking cough and inspiratory stridor.',
 'Pediatric croup case focused on distinguishing features and escalation thresholds.',
 'Child presents after 2-3 day URI progression with hoarse barking cough, stridor, and increasing work of breathing.',
 '{"hr":148,"rr":42,"spo2":86,"bp_sys":104,"bp_dia":64,"etco2":40}'::jsonb,
 'F', 'Pediatric', 'Other'),
(37, 'epiglottitis', 'pediatric-critical-airway', 'epiglottitis', 'pediatric-critical-epiglottitis-sudden-thumb-sign-emergency',
 'Pediatric Critical (Epiglottitis Sudden Thumb-Sign Emergency)',
 'Sudden bacterial supraglottic emergency requiring immediate airway control.',
 'Pediatric epiglottitis case focused on immediate intubation decisions and rescue planning.',
 'Child presents with sudden severe distress, muffled voice/cough, fever, and rapidly worsening airway risk.',
 '{"hr":156,"rr":44,"spo2":82,"bp_sys":100,"bp_dia":60,"etco2":46}'::jsonb,
 'F', 'Pediatric', 'Other'),
(38, 'bronchiolitis', 'pediatric-critical-lower-airway', 'bronchiolitis', 'pediatric-critical-bronchiolitis-rsv-edema-apnea-risk',
 'Pediatric Critical (Bronchiolitis RSV Edema/Apnea Risk)',
 'Infant RSV bronchiolitis with edema-driven wheeze and escalating distress.',
 'Pediatric bronchiolitis case focused on supportive care priorities and do-not-recommend traps.',
 'Infant with URI progression now has tachypnea, retractions, wheeze/crackles, and intermittent apnea concern.',
 '{"hr":162,"rr":48,"spo2":84,"bp_sys":92,"bp_dia":54,"etco2":44}'::jsonb,
 'F', 'Pediatric', 'Other'),
(39, 'cf', 'pediatric-critical-chronic', 'cystic-fibrosis', 'pediatric-critical-cystic-fibrosis-secretion-burden',
 'Pediatric Critical (Cystic Fibrosis Secretion Burden)',
 'Chronic CF child with thick secretions, infection risk, and obstructive decline.',
 'Pediatric CF case focused on airway-clearance sequencing and targeted therapy decisions.',
 'Child with recurrent infections, purulent secretions, clubbing, and worsening oxygenation/work of breathing.',
 '{"hr":146,"rr":38,"spo2":85,"bp_sys":106,"bp_dia":66,"etco2":43}'::jsonb,
 'F', 'Pediatric', 'Other'),
(40, 'fba', 'pediatric-critical-airway', 'foreign-body-aspiration', 'pediatric-critical-foreign-body-aspiration-unilateral-wheeze',
 'Pediatric Critical (Foreign Body Aspiration Unilateral Wheeze)',
 'Toddler aspiration emergency with sudden unilateral wheeze and airway-obstruction risk.',
 'Pediatric aspiration case focused on immediate removal pathway and imaging limitations.',
 'Toddler develops sudden respiratory distress with unilateral wheeze after possible choking event.',
 '{"hr":158,"rr":46,"spo2":81,"bp_sys":98,"bp_dia":58,"etco2":39}'::jsonb,
 'F', 'Pediatric', 'Other');

create temporary table _ped_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _ped_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _ped_seed s
  join public.cse_cases c on c.slug = s.slug
),
updated as (
  update public.cse_cases c
  set
    source = s.source,
    disease_slug = s.disease_slug,
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
    baseline_vitals = s.baseline_vitals,
    nbrc_category_code = s.nbrc_category_code,
    nbrc_category_name = s.nbrc_category_name,
    nbrc_subcategory = s.nbrc_subcategory
  from _ped_seed s
  where c.id in (select id from existing where case_number = s.case_number)
  returning s.case_number, c.id
),
created as (
  insert into public.cse_cases (
    source, disease_slug, disease_track, case_number, slug, title, intro_text, description, stem, difficulty,
    is_active, is_published, baseline_vitals, nbrc_category_code, nbrc_category_name, nbrc_subcategory
  )
  select
    s.source, s.disease_slug, 'critical', s.case_number, s.slug, s.title, s.intro_text, s.description, s.stem, 'hard',
    true, true, s.baseline_vitals, s.nbrc_category_code, s.nbrc_category_name, s.nbrc_subcategory
  from _ped_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _ped_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _ped_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _ped_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _ped_target)
);

delete from public.cse_attempts where case_id in (select case_id from _ped_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _ped_target));
delete from public.cse_steps where case_id in (select case_id from _ped_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'croup' then 'You are called to bedside for a 3-year-old male with barking cough, inspiratory noise, and increasing nighttime work of breathing. Focused airway assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'epiglottitis' then 'You are called to bedside for a 6-year-old female with high fever, drooling, muffled voice, and tripod positioning. Focused airway assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'bronchiolitis' then 'You are called to bedside for a 7-month-old male with URI progression, feeding intolerance, tachypnea, and retractions. Focused respiratory assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'cf' then 'You are called to bedside for a 12-year-old female with chronic cough and thick secretions who now has worsening dyspnea and fatigue. Focused respiratory assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      else 'You are called to bedside for a 2-year-old female with sudden coughing spell, unilateral reduced breath sounds, and acute respiratory distress after eating. Focused airway assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _ped_target t
  join _ped_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment plan now?',
    null, 'STOP', '{}'::jsonb
  from _ped_target t
  union all
  select t.case_id, 3, 3, 'IG',
    'Fifteen minutes after initial treatment, SELECT AS MANY AS INDICATED (MAX 8). What reassessment data should drive escalation NEXT?',
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _ped_target t
  union all
  select t.case_id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the safest NEXT ongoing management/disposition decision?',
    null, 'STOP', '{}'::jsonb
  from _ped_target t
  returning case_id, step_order, id
)
insert into _ped_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _ped_target t on t.case_id = i.case_id;

-- Step 1 options (IG)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Assess immediate airway threat, work of breathing, and oxygenation severity', 3, 'Top pediatric priority.' from _ped_steps st where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'croup' then 'Identify gradual onset, barking cough with inspiratory stridor, and steeple-sign context'
    when 'epiglottitis' then 'Identify sudden onset, muffled cough/voice, high fever, and thumb-sign context'
    when 'bronchiolitis' then 'Identify RSV-like URI progression, wheeze/crackles, retractions, and apnea risk signs'
    when 'cf' then 'Identify chronic secretion burden, recurrent infection pattern, clubbing/barrel chest, and growth issues'
    else 'Identify sudden unilateral wheeze/absent unilateral breath sounds and choking-event context'
  end,
  3,
  'Core syndrome-differentiation cue.'
from _ped_steps st join _ped_seed s on s.case_number = st.case_number
where st.step_order = 1
union all
select st.step_id, 'C', 'Obtain ABG and trend hypoxemia/ventilatory status', 2, 'Objective severity monitoring.' from _ped_steps st where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'croup' then 'Use targeted diagnostics including lateral neck imaging for airway pattern support'
    when 'epiglottitis' then 'Prioritize airway control first; use targeted diagnostics without delaying intervention'
    when 'bronchiolitis' then 'Use CXR/clinical severity criteria to determine outpatient vs hospital need'
    when 'cf' then 'Use sputum profile, obstructive PFT trend, and sweat chloride context when diagnosis is uncertain'
    else 'Use imaging as adjunct only; do not exclude aspiration if object is radiolucent'
  end,
  2,
  'Appropriate targeted evaluation.'
from _ped_steps st join _ped_seed s on s.case_number = st.case_number
where st.step_order = 1
union all select st.step_id, 'E', 'Delay stabilization while waiting for complete diagnostics', -3, 'Unsafe delay.' from _ped_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Assume all pediatric stridor/wheeze syndromes are treated the same', -3, 'Misses key disease differences.' from _ped_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Ignore cyanosis/apnea signs if child is intermittently calm', -3, 'Dangerous false reassurance.' from _ped_steps st where st.step_order = 1
union all select st.step_id, 'H', 'Skip close vital monitoring in high-work-of-breathing child', -2, 'Inadequate monitoring.' from _ped_steps st where st.step_order = 1;

-- Step 2 options (DM)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'croup' then 'Provide oxygen and croup-directed therapy (cool mist/racemic epinephrine) with escalation if failing'
    when 'epiglottitis' then 'Treat as airway emergency: immediate intubation/mechanical ventilation plus antibiotics'
    when 'bronchiolitis' then 'Provide supportive bronchiolitis care (oxygen/suctioning), hospitalize only severe cases, and avoid routine bronchodilator/steroid/ribavirin use'
    when 'cf' then 'Start airway-clearance and sequenced aerosol therapy, oxygen, and infection-targeted CF support'
    else 'Arrange urgent foreign-body removal via rigid bronchoscopy and secure airway support as needed'
  end,
  3,
  'Best disease-specific immediate pathway.'
from _ped_steps st join _ped_seed s on s.case_number = st.case_number
where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and delay definitive syndrome-specific treatment', -3, 'Incomplete and unsafe.' from _ped_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Defer airway intervention until severe collapse occurs', -3, 'Dangerous delay.' from _ped_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Apply routine antibiotics for every pediatric airway/wheeze presentation', -2, 'Incorrect broad approach.' from _ped_steps st where st.step_order = 2
union all select st.step_id, 'E', 'Start oxygen and immediate monitoring while preparing definitive syndrome-specific intervention pathway', 1, 'Reasonable bridge action, but incomplete if definitive treatment is delayed.' from _ped_steps st where st.step_order = 2;

-- Step 3 options (IG reassessment)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Repeat ABG (pH/PaCO2/PaO2/HCO3) and clinical trend after intervention; if intubated, document mode/VT/RR/FiO2/PEEP and adjust RR/VT/FiO2/PEEP', 2, 'Confirms response trajectory.' from _ped_steps st where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'croup' then 'Track stridor/work-of-breathing response and escalate if racemic/cool therapy fails'
    when 'epiglottitis' then 'Track airway edema trajectory and readiness for safe extubation only after stabilization'
    when 'bronchiolitis' then 'Track apnea, cyanosis, fatigue, and hydration to confirm support level'
    when 'cf' then 'Track secretion clearance, oxygenation trend, and infection-response markers'
    else 'Track post-removal airway patency and persistent wheeze/cough requiring adjunct therapy'
  end,
  3,
  'Correct disease-specific reassessment.'
from _ped_steps st join _ped_seed s on s.case_number = st.case_number
where st.step_order = 3
union all select st.step_id, 'C', 'Maintain escalation readiness for intubation/mechanical ventilation if failing', 2, 'Safe escalation posture.' from _ped_steps st where st.step_order = 3
union all select st.step_id, 'D', 'Stop close monitoring after one minor improvement', -3, 'Unsafe de-escalation.' from _ped_steps st where st.step_order = 3
union all select st.step_id, 'E', 'Delay reassessment for several hours in unstable child', -3, 'High-risk delay.' from _ped_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Assume normal x-ray excludes foreign-body aspiration', -2, 'Radiolucent objects may be missed.' from _ped_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Ignore progression to lethargy or apnea signs', -3, 'Critical miss.' from _ped_steps st where st.step_order = 3
union all select st.step_id, 'H', 'Skip isolation planning in hospitalized bronchiolitis', -1, 'Infection-control gap.' from _ped_steps st where st.step_order = 3;

-- Step 4 options (final DM/disposition)
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Continue PICU/ICU-level care with structured reassessment until sustained stability', 3, 'Safest disposition.' from _ped_steps st where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to low-acuity care immediately', -3, 'Unsafe premature transfer.' from _ped_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after transient improvement', -3, 'Unsafe disposition.' from _ped_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit airway/escalation triggers', -2, 'Inadequate safety plan.' from _ped_steps st where st.step_order = 4
union all select st.step_id, 'E', 'Continue monitored high-acuity care with explicit escalation triggers before transfer decisions', 1, 'Reasonable pathway but less protective than full PICU/ICU continuity plan.' from _ped_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'Initial pediatric assessment captured critical airway and severity cues.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _ped_steps s1 join _ped_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Missed pediatric priorities increase acute deterioration risk.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -2, "bp_dia": -2, "etco2": 3}'::jsonb
from _ped_steps s1 join _ped_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1

union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Immediate treatment aligns with pediatric disease-specific best practice.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": 1, "bp_dia": 1, "etco2": -2}'::jsonb
from _ped_steps s2 join _ped_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Suboptimal treatment leaves airway and oxygenation instability.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -3, "bp_dia": -2, "etco2": 4}'::jsonb
from _ped_steps s2 join _ped_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2

union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is complete and supports safe pediatric continuation.',
  '{"spo2": 2, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _ped_steps s3 join _ped_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps leave high risk for recurrent pediatric deterioration.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _ped_steps s3 join _ped_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3

union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient is stabilized with appropriate high-acuity pediatric management.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _ped_steps s4
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: unsafe de-escalation leads to recurrent pediatric instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _ped_steps s4
where s4.step_order = 4;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE' || t.case_number::text || '_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
join _ped_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _ped_target);

commit;
