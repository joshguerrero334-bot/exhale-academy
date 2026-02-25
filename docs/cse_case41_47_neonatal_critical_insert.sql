-- Exhale Academy CSE Branching Seed (Cases 41-47)
-- Neonatal critical cases from lesson set
-- Requires docs/cse_branching_engine_migration.sql,
-- docs/cse_case_taxonomy_migration.sql, and docs/cse_outcomes_vitals_migration.sql

begin;

create temporary table _neo_seed (
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

insert into _neo_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(41, 'delivery_room', 'neonatal-critical-delivery-room', 'delivery-room-management', 'neonatal-critical-delivery-room-apgar-resuscitation',
 'Neonatal Critical (Delivery Room Apgar Resuscitation)',
 'High-risk preterm delivery requiring immediate Apgar-based respiratory management.',
 'Neonatal delivery-room case focused on timed Apgar assessment and resuscitation thresholds.',
 'High-risk infant is born with variable effort and cyanosis; immediate transition assessment is required.',
 '{"hr":92,"rr":18,"spo2":74,"bp_sys":56,"bp_dia":34,"etco2":50}'::jsonb,
 'G', 'Neonatal', 'Resuscitation'),
(42, 'mas', 'neonatal-critical-aspiration', 'meconium-aspiration', 'neonatal-critical-meconium-aspiration-vigor-intubation-threshold',
 'Neonatal Critical (Meconium Aspiration Vigor/Intubation Threshold)',
 'Meconium-stained infant with distress where intubation depends on vigor and heart rate.',
 'Neonatal meconium aspiration case focused on correct airway decision timing.',
 'Meconium-stained infant shows respiratory distress with uncertain vigor profile.',
 '{"hr":108,"rr":44,"spo2":82,"bp_sys":64,"bp_dia":40,"etco2":47}'::jsonb,
 'G', 'Neonatal', 'Respiratory distress syndrome'),
(43, 'aop', 'neonatal-critical-prematurity', 'apnea-of-prematurity', 'neonatal-critical-apnea-of-prematurity-bradycardia-episodes',
 'Neonatal Critical (Apnea of Prematurity Bradycardia Episodes)',
 'Premature infant with central apnea events and intermittent bradycardia/hypoxemia.',
 'Neonatal apnea case focused on monitoring strategy, caffeine therapy, and escalation thresholds.',
 'Very preterm infant has recurrent apnea spells with desaturation and heart-rate drops.',
 '{"hr":96,"rr":22,"spo2":80,"bp_sys":58,"bp_dia":36,"etco2":52}'::jsonb,
 'G', 'Neonatal', 'Respiratory distress syndrome'),
(44, 'irds', 'neonatal-critical-prematurity', 'infant-respiratory-distress-syndrome', 'neonatal-critical-irds-surfactant-deficiency-ground-glass',
 'Neonatal Critical (IRDS Surfactant Deficiency Ground Glass)',
 'Premature infant with surfactant-deficiency respiratory failure and classic imaging pattern.',
 'Neonatal IRDS case focused on CPAP/surfactant sequence and ventilation escalation.',
 'Premature low-birth-weight infant has severe distress, low Apgar history, and worsening oxygenation.',
 '{"hr":154,"rr":58,"spo2":78,"bp_sys":60,"bp_dia":38,"etco2":55}'::jsonb,
 'G', 'Neonatal', 'Respiratory distress syndrome'),
(45, 'chd', 'neonatal-critical-cardiac', 'congenital-heart-defect', 'neonatal-critical-congenital-heart-defect-cyanotic-shunt',
 'Neonatal Critical (Congenital Heart Defect Cyanotic Shunt)',
 'Cyanotic congenital cardiac defect pattern requiring urgent confirmatory imaging and surgical planning.',
 'Neonatal congenital-heart case focused on shunt recognition and stabilization pathway.',
 'Neonate has persistent cyanosis, murmur, and abnormal hemodynamics suggesting structural cardiac defect.',
 '{"hr":166,"rr":52,"spo2":76,"bp_sys":62,"bp_dia":40,"etco2":42}'::jsonb,
 'G', 'Neonatal', 'Respiratory distress syndrome'),
(46, 'bpd', 'neonatal-critical-chronic-lung', 'bronchopulmonary-dysplasia', 'neonatal-critical-bpd-chronic-oxygen-dependence',
 'Neonatal Critical (BPD Chronic Oxygen Dependence)',
 'Premature infant with chronic lung disease and prolonged oxygen/ventilation needs.',
 'Neonatal BPD case focused on low-effective oxygen strategy and ventilatory weaning trajectory.',
 'Infant with prolonged oxygen dependence has retractions, wheeze/crackles, and worsening gas exchange.',
 '{"hr":162,"rr":60,"spo2":81,"bp_sys":66,"bp_dia":42,"etco2":53}'::jsonb,
 'G', 'Neonatal', 'Respiratory distress syndrome'),
(47, 'cdh', 'neonatal-critical-surgical', 'congenital-diaphragmatic-hernia', 'neonatal-critical-cdh-surgical-emergency-mediastinal-shift',
 'Neonatal Critical (CDH Surgical Emergency Mediastinal Shift)',
 'Congenital diaphragmatic hernia with severe distress requiring immediate surgical-airway strategy.',
 'Neonatal CDH case focused on emergency recognition, OG decompression, and no bag-mask ventilation.',
 'Neonate with severe distress and unilateral absent breath sounds has imaging suspicious for diaphragmatic hernia.',
 '{"hr":170,"rr":64,"spo2":74,"bp_sys":58,"bp_dia":34,"etco2":58}'::jsonb,
 'G', 'Neonatal', 'Respiratory distress syndrome');

create temporary table _neo_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _neo_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _neo_seed s
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
  from _neo_seed s
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
  from _neo_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _neo_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _neo_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _neo_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _neo_target)
);

delete from public.cse_attempts where case_id in (select case_id from _neo_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _neo_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _neo_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _neo_target));
delete from public.cse_steps where case_id in (select case_id from _neo_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'delivery_room' then 'You are called to the warmer for a term male newborn minutes after delivery who is limp with weak respiratory effort. Full neonatal assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'mas' then 'You are called to the warmer for a term female newborn delivered through thick meconium with worsening respiratory distress. Full neonatal assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'aop' then 'You are called to bedside for a 31-week male preterm neonate in the NICU with recurrent apnea episodes associated with bradycardia and desaturation. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'irds' then 'You are called to bedside for a 30-week female preterm neonate with grunting, nasal flaring, and increasing oxygen requirement. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'chd' then 'You are called to bedside for a 2-day-old male neonate with persistent cyanosis and poor response to supplemental oxygen. Focused cardiopulmonary assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      when 'bpd' then 'You are called to bedside for a 4-month-old female former preterm infant with chronic oxygen dependence who now has worsening tachypnea and increased work of breathing. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
      else 'You are called to the delivery room for a term male newborn with severe respiratory distress and asymmetric chest findings immediately after birth. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
    end,
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _neo_target t
  join _neo_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is the best FIRST treatment plan now?',
    null, 'STOP', '{}'::jsonb
  from _neo_target t
  union all
  select t.case_id, 3, 3, 'IG',
    'Fifteen minutes after initial intervention, SELECT AS MANY AS INDICATED (MAX 8). What reassessment should guide NEXT decisions?',
    8, 'STOP',
    '{"show_appearance_after_submit":true,"show_vitals_after_submit":true,"vitals_fields":["spo2","rr","hr","bp","etco2"]}'::jsonb
  from _neo_target t
  union all
  select t.case_id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is the safest NEXT ongoing management/disposition plan?',
    null, 'STOP', '{}'::jsonb
  from _neo_target t
  returning case_id, step_order, id
)
insert into _neo_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _neo_target t on t.case_id = i.case_id;

-- Step 1 IG options
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Assess immediate airway, breathing, circulation, and transition stability', 3, 'Top neonatal priority.' from _neo_steps st where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'delivery_room' then 'Obtain complete Apgar components at 1 and 5 minutes and continue reassessment protocol if needed'
    when 'mas' then 'Determine vigor profile (cry, tone, respiratory effort, HR threshold) and meconium distress pattern'
    when 'aop' then 'Characterize apnea frequency/duration with bradycardia/cyanosis association'
    when 'irds' then 'Confirm prematurity/low birth weight with IRDS distress signs and surfactant-deficiency context'
    when 'chd' then 'Assess cyanosis/murmur pattern and likely shunt physiology'
    when 'bpd' then 'Assess chronic oxygen dependence, extreme tachypnea, and distress pattern'
    else 'Assess unilateral findings and severe distress pattern consistent with CDH'
  end,
  3,
  'Core syndrome-defining data.'
from _neo_steps st join _neo_seed s on s.case_number = st.case_number
where st.step_order = 1
union all
select st.step_id, 'C', 'Obtain ABG and oxygenation/ventilation trend metrics', 2, 'Objective severity guidance.' from _neo_steps st where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'delivery_room' then 'Apply Silverman-Anderson respiratory-distress assessment if available'
    when 'mas' then 'Order CXR for atelectasis/consolidation and monitor for metabolic acidosis context'
    when 'aop' then 'Use continuous apnea/HR/SpO2 monitoring to define treatment needs'
    when 'irds' then 'Use CXR ground-glass/air-bronchogram pattern and L:S context when provided'
    when 'chd' then 'Order echocardiogram and pre/post-ductal gas studies with congenital-shape clues on CXR'
    when 'bpd' then 'Use CXR/ABG trend to distinguish worsening chronic neonatal lung disease'
    else 'Use CXR evidence of bowel-in-thorax/mediastinal shift and surgical emergency features'
  end,
  2,
  'Correct targeted diagnostic strategy.'
from _neo_steps st join _neo_seed s on s.case_number = st.case_number
where st.step_order = 1
union all select st.step_id, 'E', 'Delay stabilization while all diagnostics are pending', -3, 'Unsafe delay.' from _neo_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Assume meconium stain alone always requires intubation', -2, 'Incorrect decision rule.' from _neo_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Ignore repeated low Apgar protocol and reassessment timing', -3, 'Dangerous process error.' from _neo_steps st where st.step_order = 1
union all select st.step_id, 'H', 'Use routine bag-mask ventilation in suspected CDH', -3, 'Unsafe in CDH context.' from _neo_steps st where st.step_order = 1;

-- Step 2 DM options
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'delivery_room' then 'Treat by Apgar threshold: resuscitate severe scores, support intermediate scores, routine care when stable'
    when 'mas' then 'Suction airway and intubate/tracheal suction only when poor effort/tone with HR < 100'
    when 'aop' then 'Use continuous monitoring, oxygen, caffeine, and escalate support by episode burden'
    when 'irds' then 'Use oxygen/CPAP with surfactant therapy and escalate to invasive ventilation if failing'
    when 'chd' then 'Stabilize oxygenation/hemodynamics and begin congenital-defect surgical pathway'
    when 'bpd' then 'Use lowest effective oxygen, pulmonary hygiene, and ventilatory support/wean strategy as needed'
    else 'Treat CDH as surgical emergency: OG decompression, intubation strategy, no bag-mask ventilation'
  end,
  3,
  'Best immediate disease-specific treatment.'
from _neo_steps st join _neo_seed s on s.case_number = st.case_number
where st.step_order = 2
union all select st.step_id, 'B', 'Provide oxygen only and delay syndrome-specific management', -3, 'Incomplete and unsafe.' from _neo_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Delay intubation decisions until prolonged deterioration occurs', -3, 'Dangerous delay.' from _neo_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Transfer to low-acuity care before stabilization', -3, 'Unsafe disposition.' from _neo_steps st where st.step_order = 2
union all select st.step_id, 'E', 'Provide immediate oxygen and close cardiorespiratory monitoring while preparing definitive syndrome-specific intervention', 1, 'Reasonable bridge action, but incomplete if definitive neonatal therapy is delayed.' from _neo_steps st where st.step_order = 2;

-- Step 3 IG reassessment options
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Repeat ABG (pH/PaCO2/PaO2/HCO3) and cardiorespiratory response; if intubated, document neonatal mode and PIP/PEEP/rate/FiO2 and adjust support', 2, 'Core reassessment.' from _neo_steps st where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'delivery_room' then 'Continue timed reassessment and confirm post-resuscitation transition stability'
    when 'mas' then 'Track oxygenation targets and reassess need for ventilation escalation/HFOV pathway'
    when 'aop' then 'Track apnea/bradycardia event burden and response to caffeine/noninvasive support'
    when 'irds' then 'Track CPAP/surfactant response and pH threshold for intubation escalation'
    when 'chd' then 'Track perfusion/cyanosis and definitive surgical planning readiness'
    when 'bpd' then 'Track oxygen requirement, secretion burden, and slow ventilator weaning progress'
    else 'Track post-intubation stability and surgical readiness with decompression effectiveness'
  end,
  3,
  'Disease-specific reassessment priority.'
from _neo_steps st join _neo_seed s on s.case_number = st.case_number
where st.step_order = 3
union all select st.step_id, 'C', 'Maintain escalation readiness for mechanical ventilation/HFOV/ECMO when criteria appear', 2, 'Appropriate escalation readiness.' from _neo_steps st where st.step_order = 3
union all select st.step_id, 'D', 'Stop close monitoring after one modest improvement', -3, 'Unsafe de-escalation.' from _neo_steps st where st.step_order = 3
union all select st.step_id, 'E', 'Delay reassessment for several hours in unstable neonate', -3, 'High-risk delay.' from _neo_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Ignore pH decline while on CPAP in IRDS context', -2, 'Misses escalation trigger.' from _neo_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Ignore apnea frequency trend in preterm infant', -2, 'Misses impending failure.' from _neo_steps st where st.step_order = 3
union all select st.step_id, 'H', 'Continue bag-mask support despite confirmed CDH pattern', -3, 'Unsafe in CDH.' from _neo_steps st where st.step_order = 3;

-- Step 4 DM/disposition options
insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A', 'Continue NICU/PICU-level care with structured reassessment and escalation triggers', 3, 'Safest disposition.' from _neo_steps st where st.step_order = 4
union all select st.step_id, 'B', 'Transfer to low-acuity nursery now', -3, 'Unsafe premature transfer.' from _neo_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discharge after transient stabilization', -3, 'Unsafe disposition.' from _neo_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Observe without explicit ventilatory/escalation thresholds', -2, 'Inadequate plan.' from _neo_steps st where st.step_order = 4
union all select st.step_id, 'E', 'Continue monitored NICU-level care with explicit escalation triggers before transfer decisions', 1, 'Reasonable pathway but less protective than full high-acuity neonatal continuity plan.' from _neo_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s2.step_id,
  'Initial neonatal assessment captures key severity and syndrome cues.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _neo_steps s1 join _neo_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment gaps increase risk of rapid neonatal deterioration.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -2, "bp_dia": -2, "etco2": 3}'::jsonb
from _neo_steps s1 join _neo_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1

union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  'Immediate treatment aligns with neonatal critical-care priorities.',
  '{"spo2": 4, "hr": -3, "rr": -2, "bp_sys": 1, "bp_dia": 1, "etco2": -2}'::jsonb
from _neo_steps s2 join _neo_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Suboptimal treatment leaves persistent instability and escalation risk.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -3, "bp_dia": -2, "etco2": 4}'::jsonb
from _neo_steps s2 join _neo_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2

union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s4.step_id,
  'Reassessment is complete and supports safe neonatal continuation.',
  '{"spo2": 2, "hr": -1, "rr": -1, "bp_sys": 1, "bp_dia": 1, "etco2": -1}'::jsonb
from _neo_steps s3 join _neo_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Monitoring gaps leave high risk for recurrent neonatal deterioration.',
  '{"spo2": -3, "hr": 3, "rr": 2, "bp_sys": -2, "bp_dia": -1, "etco2": 2}'::jsonb
from _neo_steps s3 join _neo_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3

union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: infant is stabilized with appropriate high-acuity neonatal management.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": 0, "bp_dia": 0, "etco2": -1}'::jsonb
from _neo_steps s4
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation causes avoidable neonatal instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4, "etco2": 6}'::jsonb
from _neo_steps s4
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
join _neo_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _neo_target);

commit;
