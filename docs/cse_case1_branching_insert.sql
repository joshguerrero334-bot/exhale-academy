-- Exhale Academy CSE Case #1 Branching Seed (Practice Layout Audit)
-- Requires docs/cse_branching_engine_migration.sql

begin;

create temporary table _case1_target (id uuid primary key) on commit drop;
create temporary table _case1_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug = 'case-1-practice-layout-audit'
     or lower(coalesce(title, '')) like '%case 1%'
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'practice-layout-audit',
    case_number = 1,
    slug = 'case-1-practice-layout-audit',
    title = 'Case 1 -- Practice Layout Audit (Upper Airway)',
    intro_text = 'Practice scenario to audit Exhale CSE layout and flow while using realistic airway decision logic.',
    description = 'NBRC-style branching practice case for validating 3-window UX, section progression, and simulation history behavior.',
    stem = 'Practice scenario for layout and workflow QA in a time-sensitive airway presentation.',
    difficulty = 'medium',
    is_active = true,
    is_published = true
  where c.id in (select id from existing)
  returning c.id
),
created as (
  insert into public.cse_cases (
    source, case_number, slug, title, intro_text, description, stem, difficulty, is_active, is_published
  )
  select
    'practice-layout-audit',
    1,
    'case-1-practice-layout-audit',
    'Case 1 -- Practice Layout Audit (Upper Airway)',
    'Practice scenario to audit Exhale CSE layout and flow while using realistic airway decision logic.',
    'NBRC-style branching practice case for validating 3-window UX, section progression, and simulation history behavior.',
    'Practice scenario for layout and workflow QA in a time-sensitive airway presentation.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case1_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":100,"rr":30,"spo2":87,"bp_sys":140,"bp_dia":98}'::jsonb
where id in (select id from _case1_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id
  from public.cse_attempts a
  where a.case_id in (select id from _case1_target)
)
or step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case1_target)
)
or outcome_id in (
  select o.id
  from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case1_target)
);

delete from public.cse_attempts
where case_id in (select id from _case1_target);

delete from public.cse_rules
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case1_target)
);

delete from public.cse_outcomes
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case1_target)
);

delete from public.cse_options
where step_id in (
  select s.id
  from public.cse_steps s
  where s.case_id in (select id from _case1_target)
);

delete from public.cse_steps
where case_id in (select id from _case1_target);

with inserted_steps as (
  insert into public.cse_steps (
    case_id, step_number, step_order, step_type, scenario_setting, scenario_patient_summary, scenario_history, prompt, max_select, stop_label
  )
  select id, 1, 1, 'IG',
    'Emergency Department resuscitation bay during evening shift with airway cart immediately available.',
    '43-year-old male, anxious, diaphoretic, drooling, tripod positioning, speaking in one-word phrases with audible stridor.',
    'Worsening throat pain for 24 hours with rapidly progressive breathing distress over the last hour; no prior airway intervention completed.',
    'A 43-year-old male arrives with rapidly worsening noisy breathing after a day of severe throat pain. He is drooling, anxious, and speaking in one-word phrases. SpO2 is 86% on room air. SELECT AS MANY AS INDICATED. What immediate priorities do you initiate at bedside?', 8, 'STOP' from _case1_target
  union all
  select id, 2, 2, 'DM',
    'Emergency Department resuscitation bay during evening shift with airway cart immediately available.',
    '43-year-old male with ongoing severe upper-airway distress and limited speech.',
    'Symptoms continue to worsen despite initial bedside stabilization attempts.',
    'CHOOSE ONLY ONE. What is your FIRST airway strategy now?', null, 'STOP' from _case1_target
  union all
  select id, 3, 3, 'IG',
    'Emergency Department resuscitation bay with multidisciplinary airway team assembling.',
    '43-year-old male remains high risk for abrupt airway collapse.',
    'Initial airway strategy is underway; rapid reassessment and rescue readiness are required.',
    'SELECT AS MANY AS INDICATED. What reassessment and preparation actions are needed next?', 8, 'STOP' from _case1_target
  union all
  select id, 4, 4, 'DM',
    'Emergency Department critical care bay with advanced airway resources at bedside.',
    '43-year-old male now showing worsening oxygenation and visible fatigue.',
    'Progressive upper-airway failure is suspected despite prior interventions.',
    'CHOOSE ONLY ONE. Oxygenation is dropping again. What is your NEXT action?', null, 'STOP' from _case1_target
  union all
  select id, 5, 5, 'IG',
    'Emergency Department post-intubation stabilization phase before transfer.',
    '43-year-old male with secured airway requiring ongoing ventilatory and safety checks.',
    'Current ventilator settings are AC/VC, VT 480 mL, RR 16/min, FiO2 0.50, PEEP 5 cmH2O. ABG after intubation: pH 7.31, PaCO2 50 torr, PaO2 78 torr, HCO3 25 mEq/L. Immediate post-airway period carries risk of tube, ventilation, and relapse complications.',
    'SELECT AS MANY AS INDICATED. After airway control, what ongoing management and ventilator adjustments are indicated?', 8, 'STOP' from _case1_target
  union all
  select id, 6, 6, 'DM',
    'Emergency Department handoff phase to inpatient service.',
    '43-year-old male recently stabilized after critical upper-airway event.',
    'Requires disposition matching recurrence risk and monitoring intensity.',
    'CHOOSE ONLY ONE. What is the most appropriate disposition now?', null, 'STOP' from _case1_target
  returning id, step_order
)
insert into _case1_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Assess color and general appearance immediately', 2, 'Rapid visual assessment identifies distress severity within seconds.' from _case1_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess respiratory rate and work-of-breathing pattern', 2, 'Visible tachypnea and increased effort support immediate escalation.' from _case1_steps s where s.step_order = 1
union all select s.id, 'C', 'Apply continuous pulse oximetry', 2, 'SpO2 trend is critical for hypoxemia recognition and response.' from _case1_steps s where s.step_order = 1
union all select s.id, 'D', 'Obtain heart rate and blood pressure now', 2, 'Hemodynamic context helps risk-stratify impending decompensation.' from _case1_steps s where s.step_order = 1
union all select s.id, 'E', 'Assess level of consciousness and ability to protect airway', 2, 'Mental-status decline is a high-risk airway sign.' from _case1_steps s where s.step_order = 1
union all select s.id, 'F', 'Auscultate for stridor and bilateral air movement', 2, 'Confirms upper-airway noise and severity of airflow limitation.' from _case1_steps s where s.step_order = 1
union all select s.id, 'G', 'Obtain focused history of rapid symptom progression and triggers', 1, 'Useful if brief and does not delay stabilization.' from _case1_steps s where s.step_order = 1
union all select s.id, 'H', 'Apply continuous capnography if available', 1, 'EtCO2 trend can support early ventilation assessment.' from _case1_steps s where s.step_order = 1
union all select s.id, 'I', 'Obtain ABG once immediate stabilization is underway', 1, 'ABG helps quantify gas exchange after first-line stabilization begins.' from _case1_steps s where s.step_order = 1
union all select s.id, 'J', 'Order CBC and basic chemistry panel', 1, 'Helpful for downstream management but secondary to stabilization.' from _case1_steps s where s.step_order = 1
union all select s.id, 'K', 'Prepare portable neck/chest imaging after airway risk is controlled', 1, 'Can aid diagnosis when ordered after immediate priorities.' from _case1_steps s where s.step_order = 1
union all select s.id, 'L', 'Prepare difficult-airway and surgical-airway equipment now', 3, 'Critical time-sensitive preparation in severe upper-airway compromise.' from _case1_steps s where s.step_order = 1
union all select s.id, 'M', 'Call anesthesia and ENT urgently for shared airway planning', 3, 'Immediate expert coordination is essential and delays increase harm risk.' from _case1_steps s where s.step_order = 1
union all select s.id, 'N', 'Send patient to CT before bedside stabilization', -3, 'Dangerous delay and unsafe transport in unstable airway distress.' from _case1_steps s where s.step_order = 1
union all select s.id, 'O', 'Lay patient supine for complete oral exam', -3, 'Supine positioning and provocation can precipitate complete obstruction.' from _case1_steps s where s.step_order = 1

union all select s.id, 'A', 'Proceed with controlled advanced-airway setup with full backup plan', 3, 'Best available immediate strategy for unstable upper-airway failure risk.' from _case1_steps s where s.step_order = 2
union all select s.id, 'B', 'Maintain high-flow oxygen while preparing definitive airway team arrival', 1, 'Reasonable bridge only if it does not delay definitive airway control.' from _case1_steps s where s.step_order = 2
union all select s.id, 'C', 'Give large sedative dose before airway plan is ready', -3, 'Can cause loss of airway tone and catastrophic decompensation.' from _case1_steps s where s.step_order = 2
union all select s.id, 'D', 'Perform aggressive tongue-depressor exam first', -3, 'Airway provocation may trigger abrupt complete obstruction.' from _case1_steps s where s.step_order = 2
union all select s.id, 'E', 'Continue oxygen and observe without definitive plan', -2, 'Very counterproductive delay during active deterioration.' from _case1_steps s where s.step_order = 2

union all select s.id, 'A', 'Reassess color, posture, and visible work of breathing', 2, 'Visual trend confirms stabilization versus deterioration.' from _case1_steps s where s.step_order = 3
union all select s.id, 'B', 'Trend continuous SpO2 response', 2, 'Pulse-ox trend provides immediate oxygenation trajectory.' from _case1_steps s where s.step_order = 3
union all select s.id, 'C', 'Trend continuous EtCO2 response', 2, 'Capnography helps detect ventilation decline early.' from _case1_steps s where s.step_order = 3
union all select s.id, 'D', 'Repeat heart rate and blood pressure', 1, 'Bedside hemodynamic reassessment supports urgency decisions.' from _case1_steps s where s.step_order = 3
union all select s.id, 'E', 'Reassess breath sounds and chest movement symmetry', 2, 'Identifies worsening airflow asymmetry or fatigue pattern.' from _case1_steps s where s.step_order = 3
union all select s.id, 'F', 'Check tracheal position at bedside', 1, 'Helpful targeted bedside check if deterioration pattern changes.' from _case1_steps s where s.step_order = 3
union all select s.id, 'G', 'Establish reliable IV access', 1, 'Supports medications and escalation workflow.' from _case1_steps s where s.step_order = 3
union all select s.id, 'H', 'Obtain follow-up ABG for oxygenation/ventilation status', 2, 'ABG clarifies severity against pH/PaCO2/PaO2/HCO3 values.' from _case1_steps s where s.step_order = 3
union all select s.id, 'I', 'Review CBC with WBC count', 1, 'May support infectious cause without replacing urgent care.' from _case1_steps s where s.step_order = 3
union all select s.id, 'J', 'Review electrolytes including bicarbonate and potassium', 1, 'Supports acid-base and treatment planning.' from _case1_steps s where s.step_order = 3
union all select s.id, 'K', 'Obtain portable chest imaging when clinically stable for transport-free imaging', 1, 'Useful for complications while preserving bedside safety.' from _case1_steps s where s.step_order = 3
union all select s.id, 'L', 'Assign and rehearse failed-airway rescue and surgical-airway roles', 3, 'Critical team-readiness step that reduces rescue delay risk.' from _case1_steps s where s.step_order = 3
union all select s.id, 'M', 'Prepare suction and bronchial hygiene support equipment', 1, 'Reasonable adjunct for secretion and airway safety planning.' from _case1_steps s where s.step_order = 3
union all select s.id, 'N', 'Transport patient for CT before airway is secured', -3, 'Dangerous delay and transport risk in unstable airway phase.' from _case1_steps s where s.step_order = 3
union all select s.id, 'O', 'Delay all actions until complete diagnostics return', -3, 'Detrimental delay during time-sensitive deterioration.' from _case1_steps s where s.step_order = 3

union all select s.id, 'A', 'Proceed with definitive airway in controlled setting with full backup', 3, 'Best available action for worsening oxygenation with high airway-failure risk.' from _case1_steps s where s.step_order = 4
union all select s.id, 'B', 'Activate failed-airway pathway with immediate surgical-airway readiness while proceeding', 1, 'Reasonable backup-focused approach if integrated with definitive airway attempt.' from _case1_steps s where s.step_order = 4
union all select s.id, 'C', 'Trial prolonged nebulizer treatment before definitive airway control', -1, 'Low-yield delay in current unstable trajectory.' from _case1_steps s where s.step_order = 4
union all select s.id, 'D', 'Attempt rapid paralytic intubation in uncontrolled room setup', -3, 'High likelihood of failed airway without rescue-ready environment.' from _case1_steps s where s.step_order = 4
union all select s.id, 'E', 'Observe for spontaneous improvement only', -3, 'Detrimental non-action in progressive hypoxemic decline.' from _case1_steps s where s.step_order = 4

union all select s.id, 'A', 'Verify tube depth marking at teeth/lips', 2, 'Immediate placement verification reduces dislodgement risk.' from _case1_steps s where s.step_order = 5
union all select s.id, 'B', 'Confirm bilateral breath sounds and chest rise', 2, 'Core bedside confirmation of effective bilateral ventilation.' from _case1_steps s where s.step_order = 5
union all select s.id, 'C', 'Maintain continuous pulse-oximetry', 1, 'Continuous oxygenation trend remains essential post-intubation.' from _case1_steps s where s.step_order = 5
union all select s.id, 'D', 'Maintain continuous waveform capnography', 2, 'EtCO2 waveform confirms tube function and ventilation trend.' from _case1_steps s where s.step_order = 5
union all select s.id, 'E', 'Measure cuff pressure and keep in safe range', 1, 'Appropriate cuff pressure reduces aspiration and mucosal injury risk.' from _case1_steps s where s.step_order = 5
union all select s.id, 'F', 'Review ventilator pressures and exhaled tidal volume', 2, 'Detects unsafe pressure/volume patterns early.' from _case1_steps s where s.step_order = 5
union all select s.id, 'G', 'Obtain post-intubation ABG (pH/PaCO2/PaO2/HCO3)', 2, 'Confirms full ventilation and acid-base response.' from _case1_steps s where s.step_order = 5
union all select s.id, 'H', 'Adjust RR/VT for PaCO2-pH and FiO2/PEEP for PaO2 based on ABG response', 3, 'Critical ventilator optimization from objective data.' from _case1_steps s where s.step_order = 5
union all select s.id, 'I', 'Obtain portable chest x-ray to confirm depth and complications', 1, 'Appropriate confirmation after initial stabilization.' from _case1_steps s where s.step_order = 5
union all select s.id, 'J', 'Repeat heart rate and blood pressure trend checks', 1, 'Supports post-airway hemodynamic monitoring.' from _case1_steps s where s.step_order = 5
union all select s.id, 'K', 'Assess secretion burden and suction requirement', 1, 'Guides airway clearance and infection-risk management.' from _case1_steps s where s.step_order = 5
union all select s.id, 'L', 'Stop continuous monitoring once saturation normalizes briefly', -2, 'Very counterproductive; misses recurrent instability.' from _case1_steps s where s.step_order = 5
union all select s.id, 'M', 'Transport immediately for advanced imaging before stabilization', -3, 'Dangerous premature transport in early post-airway phase.' from _case1_steps s where s.step_order = 5
union all select s.id, 'N', 'Order routine urinalysis as immediate priority', -2, 'Not clinically pertinent to immediate airway stabilization.' from _case1_steps s where s.step_order = 5
union all select s.id, 'O', 'Disconnect ventilator for prolonged manual airway exam', -3, 'Creates direct risk of acute de-recruitment and hypoxemia.' from _case1_steps s where s.step_order = 5

union all select s.id, 'A', 'Admit to ICU for close airway and ventilatory monitoring', 3, 'Best available disposition for high relapse risk after critical airway event.' from _case1_steps s where s.step_order = 6
union all select s.id, 'B', 'Place in step-down with continuous monitoring and frequent RT reassessment', 1, 'Reasonable but less optimal than ICU given current risk profile.' from _case1_steps s where s.step_order = 6
union all select s.id, 'C', 'Transfer to regular floor with intermittent checks', -2, 'Monitoring intensity is inadequate for ongoing risk.' from _case1_steps s where s.step_order = 6
union all select s.id, 'D', 'Extubate and discharge from ED immediately', -3, 'Detrimental de-escalation with high probability of harm.' from _case1_steps s where s.step_order = 6
union all select s.id, 'E', 'Hold in hallway observation without structured plan', -2, 'Very counterproductive disposition mismatch.' from _case1_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '10'::jsonb, s2.id,
  'Oxygenation improves slightly and panic decreases, but stridor remains prominent and airway risk stays high.',
  '{"spo2": 5, "hr": -6, "rr": -3, "bp_sys": -4, "bp_dia": -2}'::jsonb
from _case1_steps s1 cross join _case1_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Respiratory effort worsens with clearer signs of impending airway failure.',
  '{"spo2": -4, "hr": 6, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case1_steps s1 cross join _case1_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'A controlled airway plan is in place and oxygen reserve is more stable.',
  '{"spo2": 3, "hr": -4, "rr": -3, "bp_sys": -2, "bp_dia": -2}'::jsonb
from _case1_steps s2 cross join _case1_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Upper-airway obstruction worsens with rapidly declining reserve.',
  '{"spo2": -6, "hr": 8, "rr": 5, "bp_sys": 8, "bp_dia": 6}'::jsonb
from _case1_steps s2 cross join _case1_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '9'::jsonb, s4.id,
  'Team readiness improves with continuous monitoring and rescue planning.',
  '{"spo2": 1, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case1_steps s3 cross join _case1_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Delayed reassessment and planning increase fatigue and instability.',
  '{"spo2": -4, "hr": 5, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case1_steps s3 cross join _case1_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Definitive airway control is achieved with improved gas exchange.',
  '{"spo2": 6, "hr": -8, "rr": -8, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case1_steps s4 cross join _case1_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Delay or unsafe technique leads to severe hypoxemic decompensation requiring rescue maneuvers.',
  '{"spo2": -10, "hr": 10, "rr": 6, "bp_sys": -20, "bp_dia": -12}'::jsonb
from _case1_steps s4 cross join _case1_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '10'::jsonb, s6.id,
  'Post-airway stabilization is steady with targeted ventilatory management.',
  '{"spo2": 2, "hr": -4, "rr": -2, "bp_sys": -2, "bp_dia": -2}'::jsonb
from _case1_steps s5 cross join _case1_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Monitoring gaps and premature de-escalation create recurrent instability.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 4, "bp_dia": 2}'::jsonb
from _case1_steps s5 cross join _case1_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: airway remains stable under ICU monitoring and structured reassessment.',
  '{"spo2": 1, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case1_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: disposition was too low-acuity for current risk, and recurrent instability developed.',
  '{"spo2": -6, "hr": 8, "rr": 5, "bp_sys": -8, "bp_dia": -6}'::jsonb
from _case1_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE1_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case1_target);

commit;
