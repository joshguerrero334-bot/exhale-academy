-- Exhale Academy CSE Branching Seed (Cases 52-53)
-- Adult medical critical: Kussmaul acidosis and thoracic-surgery postop complications.

begin;

create temporary table _am_seed (
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

insert into _am_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(52, 'renal_diabetes', 'adult-med-surg-critical', 'renal-failure-diabetes', 'adult-medical-critical-renal-diabetes-kussmaul-acidosis',
 'Adult Medical Critical (Renal/Diabetes Kussmaul Acidosis)',
 'Metabolic crisis with Kussmaul respirations, dehydration, and progressive fatigue requiring rapid interpretation and treatment.',
 'Critical metabolic case focused on acid-base recognition, laboratory review, and escalation when compensation begins to fail.',
 'Patient with severe metabolic acidosis develops deep respirations and worsening fatigue.',
 '{"hr":116,"rr":32,"spo2":89,"bp_sys":144,"bp_dia":86,"etco2":30}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(53, 'thoracic_surgery', 'adult-med-surg-critical', 'thoracic-surgery', 'adult-medical-critical-thoracic-surgery-postop-complications',
 'Adult Medical Critical (Thoracic Surgery Post-Op Complications)',
 'Post-thoracic surgery patient with worsening dyspnea, retained secretions, and gas-exchange decline requiring targeted postoperative assessment.',
 'Critical thoracic-surgery case focused on chest-tube assessment, secretion burden, imaging, and escalation when airway clearance fails.',
 'Postoperative thoracic patient develops worsening dyspnea and retained-secretions physiology.',
 '{"hr":126,"rr":30,"spo2":85,"bp_sys":134,"bp_dia":78,"etco2":49}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other');

create temporary table _am_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _am_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _am_seed s
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
  from _am_seed s
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
  from _am_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _am_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _am_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _am_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _am_target)
);

delete from public.cse_attempts where case_id in (select case_id from _am_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _am_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _am_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _am_target));
delete from public.cse_steps where case_id in (select case_id from _am_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'renal_diabetes' then 'A 38-year-old woman is brought to the emergency department because of lethargy and deep rapid breathing.

While breathing room air, the following are noted:
HR 116/min
RR 32/min
BP 144/86 mm Hg
SpO2 89%
EtCO2 30 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'A 67-year-old man is in the ICU the day after thoracic surgery and develops increasing dyspnea.

While receiving O2 by nasal cannula at 4 L/min, the following are noted:
HR 126/min
RR 30/min
BP 134/78 mm Hg
SpO2 85%
EtCO2 49 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4, 'STOP',
    case s.disease_key
      when 'renal_diabetes' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is dehydrated and lethargic",
        "extra_reveals": [
          { "text": "The breathing pattern is deep and labored.", "keys_any": ["A"] },
          { "text": "ABG: pH 7.19, PaCO2 22 torr, PaO2 78 torr, HCO3 8 mEq/L.", "keys_any": ["B"] },
          { "text": "BMP reveals glucose 612 mg/dL, potassium 5.8 mEq/L, bicarbonate 9 mEq/L, and BUN/creatinine are elevated.", "keys_any": ["C"] },
          { "text": "Urine output is low, and serum ketones are positive.", "keys_any": ["D"] },
          { "text": "CBC shows WBC 15,600/mm3.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is anxious and coughing weakly",
        "extra_reveals": [
          { "text": "Breath sounds are diminished at the operative base with coarse retained secretions.", "keys_any": ["A"] },
          { "text": "Chest-tube drainage is minimal, and tidaling is reduced.", "keys_any": ["B"] },
          { "text": "Chest radiograph reveals basilar atelectasis on the operative side.", "keys_any": ["C"] },
          { "text": "ABG: pH 7.30, PaCO2 52 torr, PaO2 56 torr, HCO3 25 mEq/L.", "keys_any": ["D"] },
          { "text": "CBC shows WBC 13,900/mm3 and hemoglobin 10.8 g/dL.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _am_target t
  join _am_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb
  from _am_target t
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'renal_diabetes' then 'After initial treatment is started, the patient remains tachypneic but more responsive.

While receiving O2 by nasal cannula at 2 L/min, the following are noted:
HR 108/min
RR 28/min
BP 132/80 mm Hg
SpO2 92%
EtCO2 27 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'After initial treatment is started, dyspnea improves only slightly.

While receiving O2 by aerosol mask, the following are noted:
HR 120/min
RR 28/min
BP 128/76 mm Hg
SpO2 88%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4, 'STOP',
    case s.disease_key
      when 'renal_diabetes' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains ill but is easier to arouse",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.26, PaCO2 24 torr, PaO2 82 torr, HCO3 11 mEq/L.", "keys_any": ["A"] },
          { "text": "Glucose falls to 420 mg/dL, and potassium is now 4.8 mEq/L.", "keys_any": ["B"] },
          { "text": "Urine output is improving with fluid therapy.", "keys_any": ["C"] },
          { "text": "Mental status and respiratory effort must continue to be watched for fatigue.", "keys_any": ["D"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains tachypneic and cough is still weak",
        "extra_reveals": [
          { "text": "Repeat chest radiograph reveals persistent postoperative atelectasis with retained secretions.", "keys_any": ["A"] },
          { "text": "Chest-tube system remains patent, but drainage is still low.", "keys_any": ["B"] },
          { "text": "Repeat ABG: pH 7.28, PaCO2 56 torr, PaO2 60 torr, HCO3 26 mEq/L.", "keys_any": ["C"] },
          { "text": "Bronchoscopy or reintubation should be considered if secretion clearance fails and fatigue worsens.", "keys_any": ["D"] }
        ]
      }'::jsonb
    end
  from _am_target t
  join _am_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    'Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb
  from _am_target t
  returning case_id, step_order, id
)
insert into _am_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _am_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'renal_diabetes' then 'Assess the breathing pattern'
    else 'Auscultate breath sounds'
  end,
  2,
  'This is indicated in the initial assessment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'renal_diabetes' then 'Obtain an ABG'
    else 'Inspect the chest-tube system'
  end,
  2,
  'This is indicated in the initial assessment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  case s.disease_key
    when 'renal_diabetes' then 'Review the chemistry panel and glucose'
    else 'Review the chest radiograph'
  end,
  2,
  'This is indicated in the initial assessment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'renal_diabetes' then 'Review urine output and ketones'
    else 'Obtain an ABG'
  end,
  2,
  'This is indicated in the initial assessment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'E', 'Review the CBC', 1, 'This provides supporting information.' from _am_steps st where st.step_order = 1
union all select st.step_id, 'F', 'Delay treatment until the full diagnostic panel is completed', -3, 'This delays indicated therapy.' from _am_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Transfer to a low-acuity bed before stabilization', -3, 'This is unsafe.' from _am_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case s.disease_key
    when 'renal_diabetes' then 'Begin fluid resuscitation, insulin therapy, electrolyte monitoring, and close observation for ventilatory fatigue'
    else 'Provide oxygen, optimize pain control, begin aggressive pulmonary hygiene, and monitor closely for ventilatory fatigue'
  end,
  3,
  'This is the best first treatment in this situation.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and wait for more data before beginning disease-specific therapy', -3, 'This is inadequate.' from _am_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Move the patient to an unmonitored area after brief improvement', -3, 'This is unsafe.' from _am_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Sedate first and reassess later', -3, 'This is not the correct sequence.' from _am_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case s.disease_key
    when 'renal_diabetes' then 'Repeat the ABG'
    else 'Review the repeat chest radiograph'
  end,
  2,
  'This is indicated in reassessment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'renal_diabetes' then 'Review glucose and potassium response'
    else 'Reassess the chest-tube function'
  end,
  2,
  'This is indicated in reassessment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case s.disease_key
    when 'renal_diabetes' then 'Review urine output and perfusion response'
    else 'Repeat the ABG'
  end,
  2,
  'This helps guide ongoing treatment.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case s.disease_key
    when 'renal_diabetes' then 'Reassess mental status and respiratory fatigue'
    else 'Determine whether bronchoscopy or reintubation is now required'
  end,
  2,
  'This is the key escalation decision.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'E', 'Stop close monitoring after the first response to treatment', -3, 'This is unsafe.' from _am_steps st where st.step_order = 3
union all select st.step_id, 'F', 'Plan discharge if oxygenation improves briefly', -3, 'This is premature.' from _am_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case s.disease_key
    when 'renal_diabetes' then 'Continue ICU or step-down monitoring with ongoing metabolic correction and reassessment for ventilatory failure'
    else 'Continue high-acuity care and escalate to bronchoscopy or ventilatory support if airway clearance fails'
  end,
  3,
  'This is the best next step.'
from _am_steps st join _am_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Continue the same therapy unchanged and reassess much later', -3, 'This delays indicated escalation.' from _am_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Transfer to an unmonitored bed', -3, 'This is not an appropriate level of care.' from _am_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Discharge after transient improvement', -3, 'This is unsafe.' from _am_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  case s.disease_key
    when 'renal_diabetes' then 'Severe metabolic acidosis is identified, and compensatory breathing remains pronounced.'
    else 'Postoperative secretion burden and gas-exchange decline are identified.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _am_steps s1 join _am_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
join _am_seed s on s.case_number = s1.case_number
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and the patient deteriorates.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _am_steps s1 join _am_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  case s.disease_key
    when 'renal_diabetes' then 'Initial metabolic treatment improves perfusion, but the patient remains critically ill.'
    else 'Initial postoperative treatment improves oxygenation slightly, but secretion burden persists.'
  end,
  '{"spo2":3,"hr":-2,"rr":-2,"bp_sys":-2,"bp_dia":-1,"etco2":-1}'::jsonb
from _am_steps s2 join _am_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
join _am_seed s on s.case_number = s2.case_number
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Initial treatment is inadequate, and instability worsens.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-4,"bp_dia":-3,"etco2":4}'::jsonb
from _am_steps s2 join _am_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.step_id,
  case s.disease_key
    when 'renal_diabetes' then 'Reassessment shows metabolic improvement but ongoing risk of ventilatory fatigue.'
    else 'Reassessment shows persistent postoperative respiratory risk and the need for continued high-acuity care.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _am_steps s3 join _am_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
join _am_seed s on s.case_number = s3.case_number
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Reassessment is incomplete, and the patient remains unstable.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _am_steps s3 join _am_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  case s.disease_key
    when 'renal_diabetes' then 'Final outcome: the patient remains in monitored care for ongoing metabolic correction and fatigue surveillance.'
    else 'Final outcome: the patient remains in high-acuity postoperative care with escalation readiness for bronchoscopy or ventilatory support.'
  end,
  '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":2,"bp_dia":1,"etco2":-1}'::jsonb
from _am_steps s4 join _am_seed s on s.case_number = s4.case_number where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to recurrent deterioration.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-6,"bp_dia":-4,"etco2":4}'::jsonb
from _am_steps s4 where s4.step_order = 4;

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
join _am_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _am_target);

commit;
