-- Exhale Academy CSE Branching Seed (COPD Non-Critical - Chronic Bronchitis Pattern)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case12_target (id uuid primary key) on commit drop;
create temporary table _case12_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-12-copd-conservative-chronic-bronchitis-phenotype',
    'copd-conservative-chronic-bronchitis-phenotype',
    'case-12-copd-non-critical-chronic-bronchitis-phenotype',
    'copd-non-critical-chronic-bronchitis-phenotype'
  )
  order by created_at asc
  limit 1
),
updated as (
  update public.cse_cases c
  set
    source = 'copd-non-critical',
    disease_slug = 'copd',
    disease_track = 'non_critical',
    case_number = coalesce(c.case_number, 12),
    slug = 'copd-non-critical-chronic-bronchitis-phenotype',
    title = 'COPD Non-Critical (Chronic Bronchitis-Predominant Flare)',
    intro_text = 'Productive-cough dominant COPD flare with cyanotic features requiring prioritized therapy and safe transition planning.',
    description = 'Non-critical COPD branching case emphasizing secretion-heavy phenotype recognition and best-available treatment decisions.',
    stem = 'Stocky patient with chronic productive cough, wheeze/rhonchi pattern, and moderate hypoxemia.',
    difficulty = 'medium',
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
    'copd-non-critical',
    'copd',
    'non_critical',
    12,
    'copd-non-critical-chronic-bronchitis-phenotype',
    'COPD Non-Critical (Chronic Bronchitis-Predominant Flare)',
    'Productive-cough dominant COPD flare with cyanotic features requiring prioritized therapy and safe transition planning.',
    'Non-critical COPD branching case emphasizing secretion-heavy phenotype recognition and best-available treatment decisions.',
    'Stocky patient with chronic productive cough, wheeze/rhonchi pattern, and moderate hypoxemia.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case12_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":106,"rr":28,"spo2":86,"bp_sys":152,"bp_dia":94,"temp_c":38.1}'::jsonb
where id in (select id from _case12_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case12_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case12_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case12_target)
);

delete from public.cse_attempts where case_id in (select id from _case12_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case12_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case12_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case12_target));
delete from public.cse_steps where case_id in (select id from _case12_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 61-year-old male with chronic productive cough who now has increased yellow-green sputum, wheeze, and dyspnea. Initial appearance is concerning for secretion burden. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "cyanotic, stocky body habitus with frequent productive cough and visible secretion burden",
      "appearance_keys_any": ["B", "C", "I"],
      "show_vitals_after_submit": true,
      "vitals_keys_any": ["A", "D", "E", "J"],
      "vitals_fields": ["temp_c", "spo2", "hr"],
      "extra_reveals": [
        { "text": "ABG trend: pH 7.35, PaCO2 54 torr, PaO2 60 torr, HCO3 29 mEq/L.", "keys_any": ["E"] }
      ]
    }'::jsonb from _case12_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is your FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _case12_target
  union all
  select id, 3, 3, 'IG',
    '30 minutes after first treatment, cough remains productive and distress is improved but persistent. SELECT AS MANY AS INDICATED (MAX 8). What additional assessment is most useful now?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "work of breathing is improving but cough remains productive with ongoing secretion burden",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "temp_c"]
    }'::jsonb from _case12_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is your NEXT management decision?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "respiratory effort improves with therapy alignment and secretion-focused management",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "bp"]
    }'::jsonb from _case12_target
  union all
  select id, 5, 5, 'IG',
    'The patient is improving. SELECT AS MANY AS INDICATED (MAX 8). What transition planning elements are indicated before disposition?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "symptoms continue to stabilize with reduced distress and improved tolerance",
      "show_vitals_after_submit": true,
      "vitals_fields": ["temp_c", "spo2", "rr"]
    }'::jsonb from _case12_target
  union all
  select id, 6, 6, 'DM',
    'CHOOSE ONLY ONE. What is the most appropriate disposition now?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "final appearance supports safe transition only with complete readiness planning",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "bp"]
    }'::jsonb from _case12_target
  returning id, step_order
)
insert into _case12_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Start controlled low-flow oxygen with close SpO2 reassessment', 3, 'Best available oxygen strategy for non-critical COPD exacerbation.' from _case12_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess sputum character/volume and infection features', 2, 'Crucial in chronic bronchitis-predominant flare.' from _case12_steps s where s.step_order = 1
union all select s.id, 'C', 'Auscultate for rhonchi/wheeze/crackles and airflow symmetry', 2, 'Defines large-airway secretion burden and obstruction pattern.' from _case12_steps s where s.step_order = 1
union all select s.id, 'D', 'Trend heart rate, blood pressure, and work of breathing', 1, 'Supports severity assessment and response tracking.' from _case12_steps s where s.step_order = 1
union all select s.id, 'E', 'Order ABG if ventilation concern persists', 1, 'Useful when gas exchange or ventilatory failure concern exists.' from _case12_steps s where s.step_order = 1
union all select s.id, 'F', 'Delay treatment until complete lab panel is finalized', -3, 'Detrimental delay in symptomatic exacerbation.' from _case12_steps s where s.step_order = 1
union all select s.id, 'G', 'Use high-flow oxygen without controlled titration', -3, 'Unsafe in non-critical COPD pathway.' from _case12_steps s where s.step_order = 1
union all select s.id, 'H', 'Send for immediate CT before bedside stabilization', -3, 'Unsafe transfer and delay.' from _case12_steps s where s.step_order = 1
union all select s.id, 'I', 'Document cyanosis and edema/JVD trend if present', 1, 'Supports phenotype and acuity interpretation.' from _case12_steps s where s.step_order = 1
union all select s.id, 'J', 'Check temperature for potential infective trigger context', 1, 'Helpful context for targeted treatment planning.' from _case12_steps s where s.step_order = 1

union all select s.id, 'A', 'Start SABA + anticholinergic aerosol and continue controlled oxygen', 3, 'Best immediate bronchodilator strategy for acute non-critical COPD flare.' from _case12_steps s where s.step_order = 2
union all select s.id, 'B', 'Use mucolytics as the primary acute treatment', -3, 'Incorrect primary treatment choice for this COPD decision item.' from _case12_steps s where s.step_order = 2
union all select s.id, 'C', 'Use antibiotics as routine primary treatment without infection evidence review', -3, 'Incorrect routine primary choice without targeted infection assessment.' from _case12_steps s where s.step_order = 2
union all select s.id, 'D', 'Observe only because oxygen saturation improved slightly', -2, 'Insufficient treatment for active exacerbation.' from _case12_steps s where s.step_order = 2
union all select s.id, 'E', 'Give sedative-first therapy before bronchodilator treatment', -3, 'Dangerous sequence in respiratory compromise.' from _case12_steps s where s.step_order = 2
union all select s.id, 'F', 'Repeat short-interval bronchodilator treatments and reassess sputum/work-of-breathing trend before further escalation', 1, 'Reasonable bridge step, but less complete than broader escalation plus targeted infection strategy when indicated.' from _case12_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend sputum burden and color change alongside symptom response', 2, 'Tracks infection and secretion trajectory.' from _case12_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat breath sounds for secretion burden and airflow quality', 2, 'Guides bronchial hygiene and bronchodilator adjustments.' from _case12_steps s where s.step_order = 3
union all select s.id, 'C', 'Track SpO2/work of breathing and speaking tolerance', 2, 'Core response indicators.' from _case12_steps s where s.step_order = 3
union all select s.id, 'D', 'Obtain CBC/chemistry and ABG if persistent concern remains', 1, 'Appropriate targeted objective reassessment.' from _case12_steps s where s.step_order = 3
union all select s.id, 'E', 'Evaluate need for bronchopulmonary hygiene or suction support', 2, 'Matches secretion-heavy presentation.' from _case12_steps s where s.step_order = 3
union all select s.id, 'F', 'Remove monitoring after brief symptomatic improvement', -2, 'Unsafe de-monitoring during active care phase.' from _case12_steps s where s.step_order = 3
union all select s.id, 'G', 'Ignore sputum trend because wheeze has improved', -2, 'Misses key chronic bronchitis marker.' from _case12_steps s where s.step_order = 3
union all select s.id, 'H', 'Delay all changes until next shift handoff', -3, 'Detrimental delay.' from _case12_steps s where s.step_order = 3
union all select s.id, 'I', 'Screen for ventilatory failure trajectory (rising PaCO2/falling pH)', 1, 'Important safety check for escalation readiness.' from _case12_steps s where s.step_order = 3
union all select s.id, 'J', 'Reinforce likely trigger education as symptoms improve', 1, 'Supports early prevention planning.' from _case12_steps s where s.step_order = 3

union all select s.id, 'A', 'Continue bronchodilator therapy, add systemic steroid, and target infection workup/treatment when indicated', 3, 'Best available escalation in persistent but non-crash non-critical exacerbation.' from _case12_steps s where s.step_order = 4
union all select s.id, 'B', 'Start routine antibiotics regardless of assessment findings', -3, 'Incorrect routine treatment in decision framework.' from _case12_steps s where s.step_order = 4
union all select s.id, 'C', 'Escalate directly to intubation despite no ventilatory-failure markers', -2, 'Too aggressive without failure criteria.' from _case12_steps s where s.step_order = 4
union all select s.id, 'D', 'Stop bronchodilator therapy once initial wheeze decreases', -2, 'Premature de-escalation.' from _case12_steps s where s.step_order = 4
union all select s.id, 'E', 'Delay treatment changes and recheck tomorrow', -3, 'Unsafe delay.' from _case12_steps s where s.step_order = 4
union all select s.id, 'F', 'Continue current regimen with short-interval reassessment before major escalation', 1, 'Reasonable interim option, but typically weaker than active escalation in persistent symptoms.' from _case12_steps s where s.step_order = 4

union all select s.id, 'A', 'Confirm sustained symptom improvement and stable oxygen requirement', 2, 'Core readiness requirement.' from _case12_steps s where s.step_order = 5
union all select s.id, 'B', 'Finalize trigger-avoidance counseling and infection-prevention planning', 2, 'Key relapse prevention element.' from _case12_steps s where s.step_order = 5
union all select s.id, 'C', 'Review inhaler/nebulizer technique and adherence plan', 2, 'Improves outpatient control and reduces exacerbations.' from _case12_steps s where s.step_order = 5
union all select s.id, 'D', 'Plan smoking cessation and pulmonary rehab follow-up', 2, 'Major long-term COPD outcome lever.' from _case12_steps s where s.step_order = 5
union all select s.id, 'E', 'Provide return precautions for worsening dyspnea, sputum change, or fatigue', 1, 'Safety-net planning improves early escalation.' from _case12_steps s where s.step_order = 5
union all select s.id, 'F', 'Require routine mucolytics at discharge as primary treatment', -3, 'Incorrect routine treatment-method choice in this framework.' from _case12_steps s where s.step_order = 5
union all select s.id, 'G', 'Require routine antibiotics at discharge without infection indication', -3, 'Incorrect routine treatment-method choice.' from _case12_steps s where s.step_order = 5
union all select s.id, 'H', 'Skip education because patient reports feeling better', -2, 'Unsafe prevention gap.' from _case12_steps s where s.step_order = 5
union all select s.id, 'I', 'Discharge without confirming home oxygen strategy', -2, 'Transition planning incomplete.' from _case12_steps s where s.step_order = 5
union all select s.id, 'J', 'Document objective trend improvement before final decision', 1, 'Supports defensible disposition.' from _case12_steps s where s.step_order = 5

union all select s.id, 'A', 'Discharge with structured non-critical COPD plan and close follow-up', 3, 'Best disposition when stability and education criteria are met.' from _case12_steps s where s.step_order = 6
union all select s.id, 'B', 'Admit for monitored care if instability or poor response persists', 1, 'Reasonable best-available alternative for unresolved risk.' from _case12_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge without follow-up or prevention plan', -3, 'High-risk unsafe transition.' from _case12_steps s where s.step_order = 6
union all select s.id, 'D', 'Place in unstructured hallway observation only', -2, 'Inadequate care plan.' from _case12_steps s where s.step_order = 6
union all select s.id, 'E', 'Discharge on routine antibiotics despite no infection findings', -3, 'Incorrect routine antimicrobial plan.' from _case12_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial prioritization is strong and oxygenation trend improves modestly.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -2, "bp_dia": -1}'::jsonb
from _case12_steps s1 cross join _case12_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Missed priorities worsen dyspnea and secretion burden.',
  '{"spo2": -5, "hr": 7, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case12_steps s1 cross join _case12_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Appropriate bronchodilator treatment improves airflow while cough remains productive.',
  '{"spo2": 3, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case12_steps s2 cross join _case12_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Suboptimal treatment leads to persistent obstruction and higher relapse risk.',
  '{"spo2": -6, "hr": 8, "rr": 5, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case12_steps s2 cross join _case12_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s4.id,
  'Focused reassessment supports safe and targeted management escalation.',
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case12_steps s3 cross join _case12_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Assessment gaps leave infection and ventilatory trend risks under-addressed.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case12_steps s3 cross join _case12_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Therapy alignment improves respiratory effort and sputum management trajectory.',
  '{"spo2": 4, "hr": -4, "rr": -3, "bp_sys": -2, "bp_dia": -2}'::jsonb
from _case12_steps s4 cross join _case12_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Treatment mismatch prolongs instability and increases return risk.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 5, "bp_dia": 3}'::jsonb
from _case12_steps s4 cross join _case12_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s6.id,
  'Readiness checks and prevention planning are complete and support safer transition.',
  '{"spo2": 2, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case12_steps s5 cross join _case12_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Transition planning gaps raise early relapse likelihood.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case12_steps s5 cross join _case12_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient transitions safely with non-critical COPD plan and follow-up.',
  '{"spo2": 1, "hr": -1, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case12_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: disposition plan was insufficient and symptoms recur.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case12_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE12_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case12_target);

commit;
