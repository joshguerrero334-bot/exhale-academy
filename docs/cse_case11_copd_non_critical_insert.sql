-- Exhale Academy CSE Branching Seed (COPD Non-Critical - Emphysema Pattern)
-- Requires docs/cse_branching_engine_migration.sql and docs/cse_case_taxonomy_migration.sql

begin;

create temporary table _case11_target (id uuid primary key) on commit drop;
create temporary table _case11_steps (step_order int4 primary key, id uuid not null) on commit drop;

with existing as (
  select id
  from public.cse_cases
  where slug in (
    'case-11-copd-conservative-emphysema-phenotype',
    'copd-conservative-emphysema-phenotype',
    'case-11-copd-non-critical-emphysema-phenotype',
    'copd-non-critical-emphysema-phenotype'
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
    case_number = coalesce(c.case_number, 11),
    slug = 'copd-non-critical-emphysema-phenotype',
    title = 'COPD Non-Critical (Emphysema-Predominant Flare)',
    intro_text = 'Outpatient-to-ED COPD flare with emphysema-predominant findings requiring controlled oxygen, targeted bronchodilator escalation, and safe disposition.',
    description = 'Non-critical COPD branching case emphasizing best-available decisions, reversibility trend checks, and decompensation prevention.',
    stem = 'Dyspneic COPD patient with hyperinflation pattern and worsening hypoxemia but no immediate crash criteria.',
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
    11,
    'copd-non-critical-emphysema-phenotype',
    'COPD Non-Critical (Emphysema-Predominant Flare)',
    'Outpatient-to-ED COPD flare with emphysema-predominant findings requiring controlled oxygen, targeted bronchodilator escalation, and safe disposition.',
    'Non-critical COPD branching case emphasizing best-available decisions, reversibility trend checks, and decompensation prevention.',
    'Dyspneic COPD patient with hyperinflation pattern and worsening hypoxemia but no immediate crash criteria.',
    'medium',
    true,
    true
  where not exists (select 1 from existing)
  returning id
)
insert into _case11_target (id)
select id from updated
union all
select id from created;

update public.cse_cases
set baseline_vitals = '{"hr":112,"rr":30,"spo2":84,"bp_sys":148,"bp_dia":92,"etco2":48}'::jsonb
where id in (select id from _case11_target);

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select id from _case11_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select id from _case11_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select id from _case11_target)
);

delete from public.cse_attempts where case_id in (select id from _case11_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select id from _case11_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select id from _case11_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select id from _case11_target));
delete from public.cse_steps where case_id in (select id from _case11_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select id, 1, 1, 'IG',
    'You are called to bedside for a 67-year-old male with worsening dyspnea and wheeze after heavy smoke/dust exposure. Appearance and focused exam findings require assessment. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "thin body habitus, pursed-lip breathing, prolonged expiratory phase, accessory-muscle use",
      "appearance_keys_any": ["B", "C", "D", "I"],
      "show_vitals_after_submit": true,
      "vitals_keys_any": ["A", "D", "E"],
      "vitals_fields": ["spo2", "rr", "hr", "etco2"],
      "extra_reveals": [
        { "text": "ABG trend: pH 7.33, PaCO2 56 torr, PaO2 58 torr, HCO3 29 mEq/L.", "keys_any": ["E"] }
      ]
    }'::jsonb from _case11_target
  union all
  select id, 2, 2, 'DM',
    'CHOOSE ONLY ONE. What is your FIRST treatment decision now?',
    null, 'STOP', '{}'::jsonb from _case11_target
  union all
  select id, 3, 3, 'IG',
    '30 minutes after initial treatment, oxygenation improves modestly but work of breathing remains elevated. SELECT AS MANY AS INDICATED (MAX 8). What reassessment data are most useful now?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "dyspnea is easing, but expiratory prolongation persists and fatigue risk remains",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "bp"]
    }'::jsonb from _case11_target
  union all
  select id, 4, 4, 'DM',
    'CHOOSE ONLY ONE. What is your NEXT decision if dyspnea persists but the patient is still protecting the airway?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "respiratory effort improves after therapy alignment with less accessory-muscle strain",
      "show_vitals_after_submit": true,
      "vitals_fields": ["hr", "rr", "spo2"]
    }'::jsonb from _case11_target
  union all
  select id, 5, 5, 'IG',
    'Symptoms begin stabilizing. SELECT AS MANY AS INDICATED (MAX 8). What discharge-readiness checks and prevention planning are indicated?',
    8, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "patient appears more comfortable with improved speaking tolerance and reduced distress",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "hr", "bp"]
    }'::jsonb from _case11_target
  union all
  select id, 6, 6, 'DM',
    'CHOOSE ONLY ONE. What is the most appropriate disposition now?',
    null, 'STOP',
    '{
      "show_appearance_after_submit": true,
      "appearance_text": "clinical status supports transition only when stability is sustained",
      "show_vitals_after_submit": true,
      "vitals_fields": ["spo2", "rr", "hr"]
    }'::jsonb from _case11_target
  returning id, step_order
)
insert into _case11_steps (step_order, id)
select step_order, id from inserted_steps;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select s.id, 'A', 'Apply controlled low-flow oxygen (NC 1-2 L/min) with continuous SpO2 monitoring', 3, 'Best available initial oxygen strategy in non-critical COPD management.' from _case11_steps s where s.step_order = 1
union all select s.id, 'B', 'Assess trigger exposure history and immediate symptom timeline', 1, 'Useful context that guides prevention and acute management.' from _case11_steps s where s.step_order = 1
union all select s.id, 'C', 'Auscultate for wheeze versus diminished airflow and prolonged expiration', 2, 'Directly informs severity and response to bronchodilator treatment.' from _case11_steps s where s.step_order = 1
union all select s.id, 'D', 'Obtain heart rate, blood pressure, and work-of-breathing trend', 2, 'Essential bedside severity tracking.' from _case11_steps s where s.step_order = 1
union all select s.id, 'E', 'Order ABG if ventilation concern is present', 1, 'Appropriate to define gas-exchange severity and trajectory.' from _case11_steps s where s.step_order = 1
union all select s.id, 'F', 'Send routine urinalysis as an immediate priority', -2, 'Not pertinent to immediate COPD stabilization.' from _case11_steps s where s.step_order = 1
union all select s.id, 'G', 'Start high-flow oxygen without titration or reassessment', -3, 'Unsafe in non-critical COPD where controlled oxygen is preferred.' from _case11_steps s where s.step_order = 1
union all select s.id, 'H', 'Delay treatment until all diagnostics return', -3, 'Detrimental delay during active respiratory distress.' from _case11_steps s where s.step_order = 1
union all select s.id, 'I', 'Document phenotype clues (thin habitus, pursed-lip breathing, hyperinflation pattern)', 1, 'Supports emphysema-predominant interpretation and targeted teaching.' from _case11_steps s where s.step_order = 1
union all select s.id, 'J', 'Plan pre/post bronchodilator response assessment when stable enough', 1, 'Useful for objective response tracking.' from _case11_steps s where s.step_order = 1

union all select s.id, 'A', 'Give short-acting bronchodilator + anticholinergic aerosol and continue controlled oxygen', 3, 'Best immediate regimen for acute non-critical COPD flare.' from _case11_steps s where s.step_order = 2
union all select s.id, 'B', 'Observe only because oxygen has partially improved', -2, 'Very counterproductive; active treatment is still required.' from _case11_steps s where s.step_order = 2
union all select s.id, 'C', 'Choose mucolytics as primary treatment', -3, 'Incorrect treatment-method choice for this COPD scenario.' from _case11_steps s where s.step_order = 2
union all select s.id, 'D', 'Choose antibiotics as routine treatment without infection evidence', -3, 'Incorrect routine choice without infection indicators in this scenario.' from _case11_steps s where s.step_order = 2
union all select s.id, 'E', 'Use sedative-first treatment to reduce anxiety before bronchodilators', -3, 'Dangerous sequence that can worsen ventilatory risk.' from _case11_steps s where s.step_order = 2
union all select s.id, 'F', 'Deliver repeated short-interval bronchodilator treatments and reassess response before deciding on escalation', 1, 'Reasonable bridge step, but less complete than adding broader anti-inflammatory escalation when needed.' from _case11_steps s where s.step_order = 2

union all select s.id, 'A', 'Trend SpO2 and work-of-breathing response after aerosol therapy', 2, 'Core response tracking for escalation decisions.' from _case11_steps s where s.step_order = 3
union all select s.id, 'B', 'Repeat focused breath sounds for wheeze versus diminished airflow', 2, 'Detects persistent obstruction or fatigue pattern.' from _case11_steps s where s.step_order = 3
union all select s.id, 'C', 'Reassess tachycardia and blood-pressure trend', 1, 'Useful physiologic stability marker.' from _case11_steps s where s.step_order = 3
union all select s.id, 'D', 'Obtain ABG to evaluate PaCO2/pH trend if distress persists', 2, 'Critical to identify ventilatory failure progression.' from _case11_steps s where s.step_order = 3
union all select s.id, 'E', 'Consider chest x-ray for alternate process if response is atypical', 1, 'Reasonable targeted diagnostic check.' from _case11_steps s where s.step_order = 3
union all select s.id, 'F', 'Monitor for anxiety/diaphoresis and speaking ability changes', 1, 'Functional respiratory effort markers help track deterioration.' from _case11_steps s where s.step_order = 3
union all select s.id, 'G', 'Remove monitoring once SpO2 briefly rises above baseline', -2, 'Premature de-monitoring misses relapse.' from _case11_steps s where s.step_order = 3
union all select s.id, 'H', 'Send patient to CT before stabilization due to persistent dyspnea', -3, 'Unsafe transfer and delay in unstable phase.' from _case11_steps s where s.step_order = 3
union all select s.id, 'I', 'Ignore symptom trajectory if saturation has improved by a few points', -2, 'Underestimates persistent clinical risk.' from _case11_steps s where s.step_order = 3
union all select s.id, 'J', 'Assess pre/post bronchodilator improvement trend', 1, 'Supports reversible component assessment.' from _case11_steps s where s.step_order = 3

union all select s.id, 'A', 'Escalate bronchodilator frequency and add systemic corticosteroid while monitoring closely', 3, 'Best available next step when distress persists without crash features.' from _case11_steps s where s.step_order = 4
union all select s.id, 'B', 'Proceed directly to immediate intubation despite stable mentation and no failure markers', -2, 'Escalation too aggressive for current presentation.' from _case11_steps s where s.step_order = 4
union all select s.id, 'C', 'Stop bronchodilator treatment and continue oxygen only', -2, 'Removes key therapeutic intervention.' from _case11_steps s where s.step_order = 4
union all select s.id, 'D', 'Start routine antibiotics because COPD is present', -3, 'Routine antibiotics are incorrect without infection evidence.' from _case11_steps s where s.step_order = 4
union all select s.id, 'E', 'Delay further action and reassess after one hour', -2, 'Inappropriate delay during ongoing respiratory distress.' from _case11_steps s where s.step_order = 4
union all select s.id, 'F', 'Continue current bronchodilator schedule with very close short-interval reassessment before major changes', 1, 'Reasonable interim path, but usually less effective than active escalation when symptoms persist.' from _case11_steps s where s.step_order = 4

union all select s.id, 'A', 'Confirm sustained improvement in dyspnea, SpO2 trend, and speaking tolerance', 2, 'Required stability check before disposition.' from _case11_steps s where s.step_order = 5
union all select s.id, 'B', 'Reinforce trigger avoidance plan specific to smoke/irritants', 2, 'Core prevention strategy in long-term COPD control.' from _case11_steps s where s.step_order = 5
union all select s.id, 'C', 'Review inhaler/aerosol technique and adherence plan', 2, 'Improves long-term control and reduces relapse.' from _case11_steps s where s.step_order = 5
union all select s.id, 'D', 'Provide smoking cessation counseling/resources', 2, 'High-impact intervention for COPD outcomes.' from _case11_steps s where s.step_order = 5
union all select s.id, 'E', 'Recommend pulmonary rehab and vaccination follow-up planning', 1, 'Strong preventive care bundle for exacerbation reduction.' from _case11_steps s where s.step_order = 5
union all select s.id, 'F', 'Stop discussing prevention because acute symptoms improved', -2, 'Missed opportunity for relapse prevention.' from _case11_steps s where s.step_order = 5
union all select s.id, 'G', 'Discharge without checking home oxygen strategy', -2, 'Unsafe transition planning gap.' from _case11_steps s where s.step_order = 5
union all select s.id, 'H', 'Choose routine mucolytics as a required discharge medication', -3, 'Incorrect routine treatment assumption for this COPD pathway.' from _case11_steps s where s.step_order = 5
union all select s.id, 'I', 'Choose routine antibiotics as required discharge medication', -3, 'Incorrect routine treatment assumption without infection evidence.' from _case11_steps s where s.step_order = 5
union all select s.id, 'J', 'Confirm return precautions for worsening dyspnea or rising fatigue', 1, 'Improves safety net and timely re-presentation.' from _case11_steps s where s.step_order = 5

union all select s.id, 'A', 'Discharge with structured COPD plan and close follow-up after sustained stability', 3, 'Best disposition when response is sustained and safety criteria are met.' from _case11_steps s where s.step_order = 6
union all select s.id, 'B', 'Admit to monitored bed for persistent instability or poor response', 1, 'Reasonable alternative when discharge criteria are not met.' from _case11_steps s where s.step_order = 6
union all select s.id, 'C', 'Discharge immediately without education or follow-up', -3, 'Unsafe transition with high relapse risk.' from _case11_steps s where s.step_order = 6
union all select s.id, 'D', 'Keep in hallway observation without treatment plan', -2, 'Inadequate care setting and plan.' from _case11_steps s where s.step_order = 6
union all select s.id, 'E', 'Recommend routine antibiotics at discharge despite no infection evidence', -3, 'Incorrect routine treatment and antimicrobial misuse.' from _case11_steps s where s.step_order = 6;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.id,
  'Initial bedside priorities are strong. Oxygenation begins to improve while distress persists.',
  '{"spo2": 4, "hr": -4, "rr": -2, "bp_sys": -2, "bp_dia": -2}'::jsonb
from _case11_steps s1 cross join _case11_steps s2
where s1.step_order = 1 and s2.step_order = 2
union all
select s1.id, 99, 'DEFAULT', null, s2.id,
  'Key early priorities were missed and respiratory effort worsens.',
  '{"spo2": -5, "hr": 8, "rr": 4, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case11_steps s1 cross join _case11_steps s2
where s1.step_order = 1 and s2.step_order = 2

union all
select s2.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.id,
  'Bronchodilator/anticholinergic therapy improves airflow modestly; continued reassessment is needed.',
  '{"spo2": 3, "hr": -4, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case11_steps s2 cross join _case11_steps s3
where s2.step_order = 2 and s3.step_order = 3
union all
select s2.id, 99, 'DEFAULT', null, s3.id,
  'Inappropriate initial treatment leads to worsening fatigue and gas-exchange risk.',
  '{"spo2": -6, "hr": 8, "rr": 5, "bp_sys": 6, "bp_dia": 4}'::jsonb
from _case11_steps s2 cross join _case11_steps s3
where s2.step_order = 2 and s3.step_order = 3

union all
select s3.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s4.id,
  'Reassessment is comprehensive and supports a safe escalation decision.',
  '{"spo2": 2, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case11_steps s3 cross join _case11_steps s4
where s3.step_order = 3 and s4.step_order = 4
union all
select s3.id, 99, 'DEFAULT', null, s4.id,
  'Important reassessment gaps increase risk of delayed failure recognition.',
  '{"spo2": -4, "hr": 5, "rr": 3, "bp_sys": 4, "bp_dia": 3}'::jsonb
from _case11_steps s3 cross join _case11_steps s4
where s3.step_order = 3 and s4.step_order = 4

union all
select s4.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s5.id,
  'Escalated non-critical therapy improves symptoms and breathing pattern.',
  '{"spo2": 4, "hr": -5, "rr": -4, "bp_sys": -3, "bp_dia": -2}'::jsonb
from _case11_steps s4 cross join _case11_steps s5
where s4.step_order = 4 and s5.step_order = 5
union all
select s4.id, 99, 'DEFAULT', null, s5.id,
  'Suboptimal treatment decisions prolong instability and increase relapse risk.',
  '{"spo2": -5, "hr": 6, "rr": 4, "bp_sys": 5, "bp_dia": 3}'::jsonb
from _case11_steps s4 cross join _case11_steps s5
where s4.step_order = 4 and s5.step_order = 5

union all
select s5.id, 1, 'SCORE_AT_LEAST', '8'::jsonb, s6.id,
  'Transition planning is strong with improved readiness and prevention alignment.',
  '{"spo2": 2, "hr": -3, "rr": -2, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case11_steps s5 cross join _case11_steps s6
where s5.step_order = 5 and s6.step_order = 6
union all
select s5.id, 99, 'DEFAULT', null, s6.id,
  'Prevention and readiness gaps leave high short-term relapse risk.',
  '{"spo2": -3, "hr": 4, "rr": 3, "bp_sys": 3, "bp_dia": 2}'::jsonb
from _case11_steps s5 cross join _case11_steps s6
where s5.step_order = 5 and s6.step_order = 6

union all
select s6.id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  'Final outcome: patient is discharged safely with structured non-critical COPD plan.',
  '{"spo2": 1, "hr": -2, "rr": -1, "bp_sys": -1, "bp_dia": -1}'::jsonb
from _case11_steps s6
where s6.step_order = 6
union all
select s6.id, 99, 'DEFAULT', null, null,
  'Final outcome: disposition/treatment mismatch leads to recurrent instability.',
  '{"spo2": -6, "hr": 7, "rr": 5, "bp_sys": -6, "bp_dia": -4}'::jsonb
from _case11_steps s6
where s6.step_order = 6;

insert into public.cse_outcomes (
  step_id, label, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_override
)
select
  r.step_id,
  'CASE11_S' || s.step_order::text || '_P' || r.rule_priority::text || '_' || r.rule_type as label,
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
where s.case_id in (select id from _case11_target);

commit;
