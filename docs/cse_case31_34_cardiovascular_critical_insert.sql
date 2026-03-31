-- Exhale Academy CSE Branching Seed (Cases 31-34)
-- Adult cardiovascular critical batch rewritten with reveal-based assessment.

begin;

create temporary table _cv_seed (
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

insert into _cv_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(31, 'chf', 'adult-cardiovascular-critical', 'chf', 'cardiovascular-critical-chf-cardiogenic-pulmonary-edema',
 'Cardiovascular Critical (CHF Cardiogenic Pulmonary Edema)',
 'Sudden cardiogenic pulmonary edema with severe hypoxemia, fluid-overload findings, and early failure of spontaneous compensation.',
 'Critical CHF case focused on bedside pulmonary-edema recognition, pressure support, and escalation to invasive support when noninvasive care fails.',
 'Patient develops severe orthopnea and hypoxemia from acute cardiogenic pulmonary edema.',
 '{"hr":128,"rr":34,"spo2":80,"bp_sys":172,"bp_dia":102,"etco2":42}'::jsonb,
 'C', 'Adult Cardiovascular', 'Heart failure'),
(32, 'mi', 'adult-cardiovascular-critical', 'myocardial-infarction', 'cardiovascular-critical-myocardial-infarction-ischemic-crisis',
 'Cardiovascular Critical (Myocardial Infarction Ischemic Crisis)',
 'Acute ischemic presentation with chest pain, dyspnea, and rhythm instability risk requiring immediate ECG-based recognition and reperfusion planning.',
 'Critical MI case focused on ischemic recognition, rhythm surveillance, pulmonary edema risk, and urgent transfer for definitive care.',
 'Patient presents with acute ischemic chest pain and worsening respiratory distress.',
 '{"hr":122,"rr":30,"spo2":84,"bp_sys":164,"bp_dia":98,"etco2":38}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other'),
(33, 'shock', 'adult-cardiovascular-critical', 'shock', 'cardiovascular-critical-shock-perfusion-failure',
 'Cardiovascular Critical (Shock Perfusion Failure)',
 'Severe perfusion failure with hypotension, oliguria, and worsening metabolic acidosis requiring aggressive hemodynamic support.',
 'Critical shock case focused on bedside perfusion assessment, blood gas and laboratory interpretation, and escalation to vasoactive support.',
 'Patient has severe hypotension and poor systemic perfusion with worsening oxygen delivery.',
 '{"hr":136,"rr":32,"spo2":82,"bp_sys":82,"bp_dia":48,"etco2":35}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other'),
(34, 'cor_pulm', 'adult-cardiovascular-critical', 'cor-pulmonale', 'cardiovascular-critical-cor-pulmonale-right-heart-strain',
 'Cardiovascular Critical (Cor Pulmonale Right-Heart Strain)',
 'Chronic lung-disease patient with right-heart strain, volume overload, and acute-on-chronic gas-exchange failure.',
 'Critical cor pulmonale case focused on controlled oxygen, hypercapnia monitoring, and escalation to ventilatory support when fatigue progresses.',
 'Patient with chronic lung disease develops worsening dyspnea, edema, and right-heart strain.',
 '{"hr":116,"rr":29,"spo2":83,"bp_sys":154,"bp_dia":92,"etco2":45}'::jsonb,
 'C', 'Adult Cardiovascular', 'Other');

create temporary table _cv_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _cv_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _cv_seed s
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
  from _cv_seed s
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
  from _cv_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _cv_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _cv_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _cv_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _cv_target)
);

delete from public.cse_attempts where case_id in (select case_id from _cv_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _cv_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _cv_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _cv_target));
delete from public.cse_steps where case_id in (select case_id from _cv_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'chf' then 'A 69-year-old woman is brought to the emergency department because of sudden severe dyspnea.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 128/min
RR 34/min
BP 172/102 mm Hg
SpO2 80%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'mi' then 'A 58-year-old man is brought to the emergency department because of chest pressure and worsening shortness of breath.

While receiving O2 by nasal cannula at 4 L/min, the following are noted:
HR 122/min
RR 30/min
BP 164/98 mm Hg
SpO2 84%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'shock' then 'A 46-year-old woman is in the ICU with worsening hypotension and poor perfusion.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 136/min
RR 32/min
BP 82/48 mm Hg
SpO2 82%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'A 64-year-old man with chronic lung disease has worsening dyspnea and edema.

While receiving O2 by nasal cannula at 2 L/min, the following are noted:
HR 116/min
RR 29/min
BP 154/92 mm Hg
SpO2 83%

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'chf' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is diaphoretic and unable to lie flat",
        "extra_reveals": [
          { "text": "Breath sounds reveal diffuse crackles bilaterally.", "keys_any": ["A"] },
          { "text": "Pink frothy sputum is present.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.29, PaCO2 52 torr, PaO2 46 torr, HCO3 24 mEq/L.", "keys_any": ["C"] },
          { "text": "Chest radiograph reveals cardiomegaly with diffuse bilateral perihilar infiltrates.", "keys_any": ["D"] },
          { "text": "BNP is 1680 pg/mL, and ECG reveals sinus tachycardia.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'mi' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is pale, diaphoretic, and clutching the chest",
        "extra_reveals": [
          { "text": "12-lead ECG reveals acute ST-segment elevation in the anterior leads.", "keys_any": ["A"] },
          { "text": "Breath sounds reveal bibasilar crackles.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.34, PaCO2 44 torr, PaO2 58 torr, HCO3 23 mEq/L.", "keys_any": ["C"] },
          { "text": "Troponin is elevated, and serum potassium is 3.5 mEq/L.", "keys_any": ["D"] },
          { "text": "Telemetry shows sinus tachycardia with frequent PVCs.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'shock' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is confused, pale, and clammy",
        "extra_reveals": [
          { "text": "Capillary refill is delayed, and the extremities are cool.", "keys_any": ["A"] },
          { "text": "Urine output is 15 mL/hr.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.28, PaCO2 32 torr, PaO2 60 torr, HCO3 15 mEq/L.", "keys_any": ["C"] },
          { "text": "Lactate is 5.4 mmol/L. CBC shows hemoglobin 10.2 g/dL.", "keys_any": ["D"] },
          { "text": "Mean arterial pressure remains critically low.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is cyanotic, edematous, and increasingly fatigued",
        "extra_reveals": [
          { "text": "Neck veins are distended, and bilateral pitting edema is present.", "keys_any": ["A"] },
          { "text": "Breath sounds are diminished with scattered wheezes.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.32, PaCO2 58 torr, PaO2 50 torr, HCO3 29 mEq/L.", "keys_any": ["C"] },
          { "text": "ECG shows right-axis deviation, and chest radiograph reveals hyperinflation with enlarged central pulmonary arteries.", "keys_any": ["D"] },
          { "text": "Hematocrit is 58%.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _cv_target t
  join _cv_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb
  from _cv_target t
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'chf' then 'After initial treatment is started, oxygenation remains poor and fatigue increases.

While receiving NPPV with an FiO2 of 0.80, the following are noted:
HR 126/min
RR 32/min
BP 160/94 mm Hg
SpO2 84%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'mi' then 'After initial treatment is started, the patient remains dyspneic and chest pain persists.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 118/min
RR 28/min
BP 148/90 mm Hg
SpO2 88%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'shock' then 'After initial treatment is started, hypotension persists.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 134/min
RR 31/min
BP 86/50 mm Hg
SpO2 86%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'After initial treatment is started, dyspnea improves only slightly and fatigue increases.

While receiving O2 by Venturi mask at an FiO2 of 0.35, the following are noted:
HR 112/min
RR 28/min
BP 150/90 mm Hg
SpO2 86%

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'chf' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is tiring and can speak only in short phrases",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.27, PaCO2 56 torr, PaO2 52 torr, HCO3 24 mEq/L.", "keys_any": ["A"] },
          { "text": "Work of breathing is increasing, and mental status is beginning to decline.", "keys_any": ["B"] },
          { "text": "Urine output remains low despite therapy.", "keys_any": ["C"] },
          { "text": "Endotracheal intubation should be prepared because noninvasive support is failing.", "keys_any": ["D"] },
          { "text": "Serum potassium is 3.6 mEq/L and creatinine is 1.5 mg/dL.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'mi' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains diaphoretic and anxious",
        "extra_reveals": [
          { "text": "Repeat ECG continues to show ST-segment elevation with frequent ventricular ectopy.", "keys_any": ["A"] },
          { "text": "Breath sounds reveal persistent bibasilar crackles.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.35, PaCO2 42 torr, PaO2 60 torr, HCO3 23 mEq/L.", "keys_any": ["C"] },
          { "text": "Troponin continues to rise.", "keys_any": ["D"] },
          { "text": "Definitive reperfusion and ICU-level monitoring are still required.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'shock' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "perfusion remains poor despite initial support",
        "extra_reveals": [
          { "text": "Mean arterial pressure remains approximately 58 mm Hg, and mental status is still altered.", "keys_any": ["A"] },
          { "text": "Urine output remains low, and lactate is still elevated.", "keys_any": ["B"] },
          { "text": "Vasoactive support should be escalated.", "keys_any": ["C"] },
          { "text": "Repeat ABG: pH 7.26, PaCO2 31 torr, PaO2 64 torr, HCO3 14 mEq/L.", "keys_any": ["D"] },
          { "text": "Hemoglobin falls to 9.8 g/dL.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is more somnolent and appears to be tiring",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.28, PaCO2 64 torr, PaO2 54 torr, HCO3 30 mEq/L.", "keys_any": ["A"] },
          { "text": "Work of breathing remains increased, and mental status is worsening.", "keys_any": ["B"] },
          { "text": "Controlled oxygen has not corrected the hypercapnia.", "keys_any": ["C"] },
          { "text": "Noninvasive ventilation should be considered now.", "keys_any": ["D"] },
          { "text": "Edema and JVD remain present.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _cv_target t
  join _cv_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    'Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb
  from _cv_target t
  returning case_id, step_order, id
)
insert into _cv_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _cv_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'chf' then 'Auscultate breath sounds'
    when 'mi' then 'Obtain a 12-lead ECG'
    when 'shock' then 'Assess skin temperature and capillary refill'
    else 'Inspect the neck veins and peripheral edema'
  end,
  2,
  'This is indicated in the initial assessment.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'chf' then 'Inspect the sputum'
    when 'mi' then 'Auscultate breath sounds'
    when 'shock' then 'Measure urine output'
    else 'Auscultate breath sounds'
  end,
  2,
  'This is indicated in the initial assessment.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  'Obtain an ABG',
  2,
  'This helps define severity.'
from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'chf' then 'Review the chest radiograph'
    when 'mi' then 'Review troponin and serum potassium'
    when 'shock' then 'Review lactate and CBC'
    else 'Review the ECG and chest radiograph'
  end,
  2,
  'This is appropriate for the suspected pathology.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'E',
  case s.disease_key
    when 'chf' then 'Review the BNP and ECG'
    when 'mi' then 'Review telemetry and blood pressure trend'
    when 'shock' then 'Reassess mental status and mean arterial pressure'
    else 'Review the hematocrit'
  end,
  1,
  'This provides useful supporting data.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'F', 'Delay treatment until the full diagnostic panel is completed', -3, 'This delays indicated therapy.' from _cv_steps st where st.step_order = 1
union all
select st.step_id, 'G', 'Transfer to a low-acuity bed before stabilization', -3, 'This is unsafe.' from _cv_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case s.disease_key
    when 'chf' then 'Position upright, provide oxygen, begin NPPV, and support nitrate and diuretic therapy while monitoring hemodynamics'
    when 'mi' then 'Provide oxygen as indicated, begin continuous ECG monitoring, and support the emergency ischemia treatment pathway'
    when 'shock' then 'Provide oxygen, secure IV access, begin cause-directed perfusion support, and prepare vasoactive therapy'
    else 'Titrate controlled oxygen, begin bronchodilator therapy, and monitor closely for worsening hypercapnia and fatigue'
  end,
  3,
  'This is the best first treatment in this situation.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen only and wait for more data before beginning disease-specific therapy', -3, 'This is inadequate.' from _cv_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Move the patient to an unmonitored area after brief improvement', -3, 'This is unsafe.' from _cv_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Sedate first and reassess the patient later', -3, 'This is not the correct sequence.' from _cv_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case s.disease_key
    when 'chf' then 'Repeat the ABG'
    when 'mi' then 'Repeat the ECG and review the rhythm strip'
    when 'shock' then 'Reassess mean arterial pressure and mental status'
    else 'Repeat the ABG'
  end,
  2,
  'This is indicated in reassessment.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'chf' then 'Reassess work of breathing and mental status'
    when 'mi' then 'Reassess breath sounds and work of breathing'
    when 'shock' then 'Review urine output and lactate trend'
    else 'Reassess work of breathing and mental status'
  end,
  2,
  'This is indicated in reassessment.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case s.disease_key
    when 'chf' then 'Review urine output and blood pressure response'
    when 'mi' then 'Repeat the ABG'
    when 'shock' then 'Determine whether vasoactive support should be escalated'
    else 'Determine whether current oxygen therapy is failing'
  end,
  2,
  'This helps guide escalation.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case s.disease_key
    when 'chf' then 'Determine whether endotracheal intubation is now required'
    when 'mi' then 'Review troponin trend'
    when 'shock' then 'Repeat the ABG'
    else 'Determine whether noninvasive ventilation is indicated'
  end,
  2,
  'This helps determine the next management step.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'E',
  case s.disease_key
    when 'chf' then 'Review serum potassium and creatinine'
    when 'mi' then 'Determine whether definitive reperfusion and ICU-level monitoring are still required'
    when 'shock' then 'Review CBC and hemoglobin trend'
    else 'Reassess edema and neck-vein distention'
  end,
  1,
  'This provides useful supporting information.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'F', 'Stop close monitoring after the first response to treatment', -3, 'This is unsafe.' from _cv_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Plan discharge if oxygenation improves briefly', -3, 'This is premature.' from _cv_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case s.disease_key
    when 'chf' then 'Proceed with endotracheal intubation and ICU care'
    when 'mi' then 'Transfer for definitive reperfusion with continued ICU-level monitoring'
    when 'shock' then 'Continue ICU care with aggressive perfusion support and vasoactive therapy'
    else 'Begin noninvasive ventilation and continue high-acuity monitored care'
  end,
  3,
  'This is the best next step for the current condition.'
from _cv_steps st join _cv_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Keep the current therapy unchanged and reassess much later', -3, 'This delays indicated escalation.' from _cv_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Transfer to an unmonitored bed', -3, 'This is not an appropriate level of care.' from _cv_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Discharge after transient improvement', -3, 'This is unsafe.' from _cv_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  case s.disease_key
    when 'chf' then 'Cardiogenic pulmonary edema findings are identified, and severe hypoxemia persists.'
    when 'mi' then 'Acute ischemic findings are identified, and the patient remains unstable.'
    when 'shock' then 'Severe perfusion failure is confirmed, and hypotension persists.'
    else 'Right-heart strain and acute-on-chronic hypercapnic failure are identified.'
  end,
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0, "etco2": 0}'::jsonb
from _cv_steps s1
join _cv_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
join _cv_seed s on s.case_number = s1.case_number
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and instability worsens.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -4, "bp_dia": -3, "etco2": 3}'::jsonb
from _cv_steps s1
join _cv_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1

union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  case s.disease_key
    when 'chf' then 'Initial therapy improves oxygenation slightly, but pulmonary edema remains severe.'
    when 'mi' then 'Initial therapy supports oxygenation and rhythm surveillance while definitive care is arranged.'
    when 'shock' then 'Initial therapy improves oxygen delivery slightly, but perfusion remains poor.'
    else 'Controlled oxygen and bronchodilator therapy help, but hypercapnia and fatigue persist.'
  end,
  case s.disease_key
    when 'chf' then '{"spo2": 4, "hr": -2, "rr": -2, "bp_sys": -6, "bp_dia": -4, "etco2": -1}'::jsonb
    when 'mi' then '{"spo2": 3, "hr": -2, "rr": -1, "bp_sys": -4, "bp_dia": -2, "etco2": -1}'::jsonb
    when 'shock' then '{"spo2": 4, "hr": -2, "rr": -1, "bp_sys": 4, "bp_dia": 2, "etco2": -1}'::jsonb
    else '{"spo2": 3, "hr": -1, "rr": -1, "bp_sys": -2, "bp_dia": -1, "etco2": -1}'::jsonb
  end
from _cv_steps s2
join _cv_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
join _cv_seed s on s.case_number = s2.case_number
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Initial treatment is inadequate, and the patient deteriorates.',
  '{"spo2": -5, "hr": 5, "rr": 4, "bp_sys": -6, "bp_dia": -4, "etco2": 4}'::jsonb
from _cv_steps s2
join _cv_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2

union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.step_id,
  case s.disease_key
    when 'chf' then 'Reassessment confirms failure of noninvasive support and the need for intubation.'
    when 'mi' then 'Reassessment confirms ongoing ischemia and the need for urgent definitive care.'
    when 'shock' then 'Reassessment confirms persistent shock requiring escalating vasoactive support.'
    else 'Reassessment confirms worsening hypercapnic fatigue and the need for ventilatory escalation.'
  end,
  '{"spo2": 0, "hr": 0, "rr": 0, "bp_sys": 0, "bp_dia": 0, "etco2": 0}'::jsonb
from _cv_steps s3
join _cv_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
join _cv_seed s on s.case_number = s3.case_number
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Reassessment is incomplete, and instability progresses.',
  '{"spo2": -4, "hr": 4, "rr": 3, "bp_sys": -4, "bp_dia": -3, "etco2": 3}'::jsonb
from _cv_steps s3
join _cv_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3

union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  case s.disease_key
    when 'chf' then 'Final outcome: the patient is intubated and stabilized in the ICU for severe cardiogenic pulmonary edema.'
    when 'mi' then 'Final outcome: the patient is transferred for definitive reperfusion with continued ICU-level monitoring.'
    when 'shock' then 'Final outcome: the patient remains in the ICU for ongoing vasoactive and perfusion support.'
    else 'Final outcome: noninvasive ventilation and monitored critical care stabilize the patient with cor pulmonale.'
  end,
  '{"spo2": 2, "hr": -2, "rr": -2, "bp_sys": 2, "bp_dia": 1, "etco2": -1}'::jsonb
from _cv_steps s4
join _cv_seed s on s.case_number = s4.case_number
where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation leads to recurrent critical deterioration.',
  '{"spo2": -6, "hr": 6, "rr": 4, "bp_sys": -6, "bp_dia": -4, "etco2": 4}'::jsonb
from _cv_steps s4
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
join _cv_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _cv_target);

commit;
