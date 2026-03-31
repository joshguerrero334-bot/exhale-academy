-- Exhale Academy CSE Branching Seed (Cases 48, 49, 50, 51, 56)
-- Adult medical critical batch rewritten with reveal-based assessment.

begin;

create temporary table _amx_seed (
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

insert into _amx_seed (
  case_number, disease_key, source, disease_slug, slug, title, intro_text, description, stem, baseline_vitals,
  nbrc_category_code, nbrc_category_name, nbrc_subcategory
) values
(48, 'sleep', 'adult-med-surg-critical', 'sleep-disorders', 'adult-medical-critical-sleep-apnea-polysomnography-pathway',
 'Adult Medical Critical (Sleep Apnea Polysomnography Pathway)',
 'Severe sleep-disordered breathing with daytime hypercapnia requiring diagnostic confirmation and positive-pressure selection.',
 'Adult sleep-disorder case focused on polysomnography, nocturnal desaturation, and choosing the correct positive-pressure therapy.',
 'Patient with obesity, loud snoring, and daytime somnolence has severe sleep-disordered breathing.',
 '{"hr":96,"rr":20,"spo2":88,"bp_sys":154,"bp_dia":92,"etco2":52}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(49, 'hypothermia', 'adult-med-surg-critical', 'hypothermia', 'adult-medical-critical-hypothermia-rewarming-resuscitation',
 'Adult Medical Critical (Hypothermia Rewarming/Resuscitation)',
 'Severe cold exposure with depressed respirations and bradycardia requiring gentle handling, core rewarming, and close rhythm surveillance.',
 'Hypothermia case focused on core-temperature assessment, rhythm monitoring, ABG interpretation, and active rewarming.',
 'Patient is found after prolonged cold exposure with depressed respirations and altered mental status.',
 '{"hr":42,"rr":8,"spo2":79,"bp_sys":84,"bp_dia":46,"etco2":56}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other'),
(50, 'pneumonia', 'adult-med-surg-critical', 'pneumonia', 'adult-medical-critical-pneumonia-consolidation-hypoxemia',
 'Adult Medical Critical (Pneumonia Consolidation Hypoxemia)',
 'Lower-respiratory infection with worsening hypoxemia, consolidation, and sepsis risk requiring targeted evaluation and escalation.',
 'Pneumonia case focused on bedside assessment, laboratory and imaging review, and deciding when high-acuity support is needed.',
 'Patient presents with fever, productive cough, pleuritic discomfort, and worsening dyspnea.',
 '{"hr":124,"rr":34,"spo2":84,"bp_sys":148,"bp_dia":88,"etco2":36}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Infectious disease'),
(51, 'aids', 'adult-med-surg-critical', 'aids', 'adult-medical-critical-aids-opportunistic-pcp-pathway',
 'Adult Medical Critical (AIDS Opportunistic PCP Pathway)',
 'Immunocompromised respiratory failure with diffuse infiltrates and severe hypoxemia requiring targeted opportunistic-infection management.',
 'AIDS case focused on PCP recognition, blood-gas severity, and escalation while definitive therapy is started.',
 'Immunocompromised patient has progressive dyspnea, fever, and worsening hypoxemia.',
 '{"hr":118,"rr":30,"spo2":86,"bp_sys":136,"bp_dia":82,"etco2":40}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Infectious disease'),
(56, 'sleep_obstructive', 'adult-med-surg-critical', 'sleep-disorders', 'adult-medical-critical-obstructive-sleep-apnea-interface-optimization',
 'Adult Medical Critical (Obstructive Sleep Apnea Interface Optimization)',
 'Severe obstructive sleep apnea with poor mask tolerance and persistent nocturnal events requiring interface troubleshooting.',
 'OSA-focused case for adherence barriers, device download review, and deciding when CPAP optimization is enough.',
 'Patient with severe OSA has persistent nocturnal symptoms and poor mask tolerance.',
 '{"hr":98,"rr":20,"spo2":90,"bp_sys":148,"bp_dia":90,"etco2":46}'::jsonb,
 'E', 'Adult Medical or Surgical', 'Other');

create temporary table _amx_target (case_number int4 primary key, case_id uuid not null) on commit drop;
create temporary table _amx_steps (case_number int4 not null, step_order int4 not null, step_id uuid not null, primary key(case_number, step_order)) on commit drop;

with existing as (
  select s.case_number, c.id
  from _amx_seed s
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
  from _amx_seed s
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
  from _amx_seed s
  where not exists (select 1 from existing e where e.case_number = s.case_number)
  returning case_number, id
)
insert into _amx_target(case_number, case_id)
select case_number, id from updated
union all
select case_number, id from created;

delete from public.cse_attempt_events
where attempt_id in (
  select a.id from public.cse_attempts a where a.case_id in (select case_id from _amx_target)
)
or step_id in (
  select s.id from public.cse_steps s where s.case_id in (select case_id from _amx_target)
)
or outcome_id in (
  select o.id from public.cse_outcomes o
  join public.cse_steps s on s.id = o.step_id
  where s.case_id in (select case_id from _amx_target)
);

delete from public.cse_attempts where case_id in (select case_id from _amx_target);
delete from public.cse_rules where step_id in (select id from public.cse_steps where case_id in (select case_id from _amx_target));
delete from public.cse_outcomes where step_id in (select id from public.cse_steps where case_id in (select case_id from _amx_target));
delete from public.cse_options where step_id in (select id from public.cse_steps where case_id in (select case_id from _amx_target));
delete from public.cse_steps where case_id in (select case_id from _amx_target);

with inserted_steps as (
  insert into public.cse_steps (case_id, step_number, step_order, step_type, prompt, max_select, stop_label, metadata)
  select t.case_id, 1, 1, 'IG',
    case s.disease_key
      when 'sleep' then 'A 49-year-old man is referred because of loud snoring, daytime hypersomnolence, and witnessed nocturnal apneas.

While breathing room air, the following are noted:
HR 96/min
RR 20/min
BP 154/92 mm Hg
SpO2 88%
EtCO2 52 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'hypothermia' then 'A 61-year-old man is brought to the emergency department after prolonged cold exposure.

While receiving O2 by nonrebreathing mask, the following are noted:
HR 42/min
RR 8/min
BP 84/46 mm Hg
SpO2 79%
EtCO2 56 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'pneumonia' then 'A 73-year-old woman is brought to the emergency department because of fever, productive cough, and increasing shortness of breath.

While receiving O2 by nasal cannula at 4 L/min, the following are noted:
HR 124/min
RR 34/min
BP 148/88 mm Hg
SpO2 84%
EtCO2 36 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'aids' then 'A 41-year-old man with advanced immunocompromise is brought to the emergency department because of progressive dyspnea and fever.

While receiving O2 by nasal cannula at 6 L/min, the following are noted:
HR 118/min
RR 30/min
BP 136/82 mm Hg
SpO2 86%
EtCO2 40 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'A 56-year-old woman with severe obstructive sleep apnea reports persistent nocturnal events and poor mask tolerance.

While breathing room air, the following are noted:
HR 98/min
RR 20/min
BP 148/90 mm Hg
SpO2 90%
EtCO2 46 mm Hg

Which of the following should be evaluated initially? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'sleep' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is obese and sleepy but arouses easily",
        "extra_reveals": [
          { "text": "The bed partner reports loud snoring, witnessed apneas, and morning headaches.", "keys_any": ["A"] },
          { "text": "ABG: pH 7.36, PaCO2 54 torr, PaO2 58 torr, HCO3 30 mEq/L.", "keys_any": ["B"] },
          { "text": "Overnight oximetry reveals recurrent desaturations to 78%.", "keys_any": ["C"] },
          { "text": "There is no history of opioid or sedative use.", "keys_any": ["D"] },
          { "text": "CBC reveals hemoglobin 17.8 g/dL and hematocrit 54%.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'hypothermia' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is cold, confused, and responds slowly",
        "extra_reveals": [
          { "text": "Core temperature is 29 C (84.2 F).", "keys_any": ["A"] },
          { "text": "Cardiac rhythm reveals sinus bradycardia with prominent J waves.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.21, PaCO2 58 torr, PaO2 52 torr, HCO3 23 mEq/L.", "keys_any": ["C"] },
          { "text": "Potassium is 4.8 mEq/L. CBC shows hemoglobin 14.2 g/dL.", "keys_any": ["D"] },
          { "text": "Mental status remains depressed, but a gag reflex is present.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'pneumonia' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is febrile, using accessory muscles, and coughing thick sputum",
        "extra_reveals": [
          { "text": "Breath sounds reveal coarse crackles and bronchial breath sounds at the right base.", "keys_any": ["A"] },
          { "text": "The sputum is thick, yellow-green, and difficult to clear.", "keys_any": ["B"] },
          { "text": "Chest radiograph reveals right lower lobe consolidation with a small pleural effusion.", "keys_any": ["C"] },
          { "text": "ABG: pH 7.32, PaCO2 46 torr, PaO2 54 torr, HCO3 23 mEq/L.", "keys_any": ["D"] },
          { "text": "CBC shows WBC 19,400/mm3, and lactate is 2.8 mmol/L.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'aids' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is thin, tachypneic, and visibly fatigued",
        "extra_reveals": [
          { "text": "Breath sounds are mildly diminished with fine crackles bilaterally.", "keys_any": ["A"] },
          { "text": "Chest radiograph reveals diffuse bilateral interstitial infiltrates.", "keys_any": ["B"] },
          { "text": "ABG: pH 7.44, PaCO2 34 torr, PaO2 48 torr, HCO3 22 mEq/L.", "keys_any": ["C"] },
          { "text": "LDH is elevated, and the CD4 count is 62/mm3.", "keys_any": ["D"] },
          { "text": "CBC reveals hemoglobin 11.0 g/dL and WBC 4,100/mm3.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is tired and frustrated with sleep therapy",
        "extra_reveals": [
          { "text": "Device download shows usage less than 3 hours per night with a large mask leak.", "keys_any": ["A"] },
          { "text": "Overnight oximetry reveals recurrent desaturations to 84% during mask leak periods.", "keys_any": ["B"] },
          { "text": "Mask fit is poor, and the patient reports severe nasal dryness.", "keys_any": ["C"] },
          { "text": "Residual AHI on the current setup is 18 events/hr.", "keys_any": ["D"] },
          { "text": "ABG: pH 7.38, PaCO2 47 torr, PaO2 62 torr, HCO3 27 mEq/L.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _amx_target t
  join _amx_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 2, 2, 'DM',
    'Which of the following should be recommended FIRST?',
    null, 'STOP', '{}'::jsonb
  from _amx_target t
  union all
  select t.case_id, 3, 3, 'IG',
    case s.disease_key
      when 'sleep' then 'After the initial recommendation is completed, the patient returns with diagnostic results.

While breathing room air, the following are noted:
HR 92/min
RR 18/min
BP 148/88 mm Hg
SpO2 89%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'hypothermia' then 'After active rewarming is started, the patient remains critically ill but is more responsive.

While receiving warmed humidified O2 by face mask, the following are noted:
HR 54/min
RR 10/min
BP 92/54 mm Hg
SpO2 88%
EtCO2 50 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'pneumonia' then 'After initial treatment is started, oxygenation improves only slightly and dyspnea persists.

While receiving high-flow nasal oxygen at an FiO2 of 0.60, the following are noted:
HR 118/min
RR 32/min
BP 142/84 mm Hg
SpO2 88%
EtCO2 38 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      when 'aids' then 'After initial treatment is started, severe hypoxemia persists.

While receiving high-flow nasal oxygen at an FiO2 of 0.80, the following are noted:
HR 116/min
RR 32/min
BP 132/78 mm Hg
SpO2 86%
EtCO2 38 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
      else 'After interface changes are made, the patient returns for reassessment.

While breathing room air, the following are noted:
HR 92/min
RR 18/min
BP 142/86 mm Hg
SpO2 92%
EtCO2 44 mm Hg

Which of the following should be evaluated now? SELECT AS MANY AS INDICATED (MAX 4).'
    end,
    4,
    'STOP',
    case s.disease_key
      when 'sleep' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains sleepy during the day but is motivated to start therapy",
        "extra_reveals": [
          { "text": "Polysomnography reveals an AHI of 48/hr with sustained nocturnal hypoventilation.", "keys_any": ["A"] },
          { "text": "Obstructive events predominate, and central apneas are not significant.", "keys_any": ["B"] },
          { "text": "Repeat ABG remains abnormal: pH 7.37, PaCO2 53 torr, PaO2 60 torr, HCO3 30 mEq/L.", "keys_any": ["C"] },
          { "text": "Mask fit and pressure tolerance should be assessed before home setup.", "keys_any": ["D"] },
          { "text": "CBC remains consistent with secondary polycythemia.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'hypothermia' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is warmer and follows simple commands",
        "extra_reveals": [
          { "text": "Core temperature has increased to 32 C (89.6 F).", "keys_any": ["A"] },
          { "text": "Repeat ABG: pH 7.28, PaCO2 50 torr, PaO2 66 torr, HCO3 23 mEq/L.", "keys_any": ["B"] },
          { "text": "Cardiac rhythm remains sinus bradycardia without ventricular ectopy.", "keys_any": ["C"] },
          { "text": "Potassium is 4.4 mEq/L, and blood pressure is improving with rewarming.", "keys_any": ["D"] },
          { "text": "The patient is protecting the airway but still requires close monitoring.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'pneumonia' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient remains tachypneic and fatigued",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.30, PaCO2 50 torr, PaO2 58 torr, HCO3 24 mEq/L.", "keys_any": ["A"] },
          { "text": "Chest radiograph reveals persistent right lower lobe consolidation and a slightly larger pleural effusion.", "keys_any": ["B"] },
          { "text": "Blood and sputum cultures have been obtained, and broad-spectrum antibiotics are being continued.", "keys_any": ["C"] },
          { "text": "Work of breathing remains high, and intubation may be required if fatigue worsens.", "keys_any": ["D"] },
          { "text": "CBC remains elevated, and lactate is unchanged at 2.7 mmol/L.", "keys_any": ["E"] }
        ]
      }'::jsonb
      when 'aids' then '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient is exhausted and can speak only a few words at a time",
        "extra_reveals": [
          { "text": "Repeat ABG: pH 7.43, PaCO2 33 torr, PaO2 50 torr, HCO3 22 mEq/L.", "keys_any": ["A"] },
          { "text": "Induced sputum is positive for Pneumocystis jirovecii.", "keys_any": ["B"] },
          { "text": "Diffuse bilateral interstitial infiltrates persist on chest radiograph.", "keys_any": ["C"] },
          { "text": "Work of breathing is increasing, and ICU-level monitoring is required.", "keys_any": ["D"] },
          { "text": "CBC remains unchanged, and hemoglobin is stable.", "keys_any": ["E"] }
        ]
      }'::jsonb
      else '{
        "show_appearance_after_submit": true,
        "appearance_text": "the patient reports better comfort and less dryness",
        "extra_reveals": [
          { "text": "Device download now shows a large reduction in mask leak.", "keys_any": ["A"] },
          { "text": "Residual AHI has fallen to 6 events/hr.", "keys_any": ["B"] },
          { "text": "Overnight oximetry remains between 90% and 92% for most of the night.", "keys_any": ["C"] },
          { "text": "The patient is using the device more than 6 hours each night.", "keys_any": ["D"] },
          { "text": "Daytime ABG is stable and does not suggest worsening hypoventilation.", "keys_any": ["E"] }
        ]
      }'::jsonb
    end
  from _amx_target t
  join _amx_seed s on s.case_number = t.case_number
  union all
  select t.case_id, 4, 4, 'DM',
    'Which of the following should be recommended now?',
    null, 'STOP', '{}'::jsonb
  from _amx_target t
  returning case_id, step_order, id
)
insert into _amx_steps(case_number, step_order, step_id)
select t.case_number, i.step_order, i.id
from inserted_steps i
join _amx_target t on t.case_id = i.case_id;

insert into public.cse_options (step_id, option_key, option_text, score, rationale)
select st.step_id, 'A',
  case s.disease_key
    when 'sleep' then 'Obtain a detailed sleep history'
    when 'hypothermia' then 'Measure the core temperature'
    when 'pneumonia' then 'Auscultate breath sounds'
    when 'aids' then 'Auscultate breath sounds'
    else 'Review the device adherence and leak report'
  end,
  2,
  'This is indicated in the initial assessment.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'B',
  case s.disease_key
    when 'sleep' then 'Obtain an ABG'
    when 'hypothermia' then 'Assess the cardiac rhythm'
    when 'pneumonia' then 'Inspect the sputum'
    when 'aids' then 'Review the chest radiograph'
    else 'Review overnight oximetry'
  end,
  2,
  'This is indicated in the initial assessment.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'C',
  case s.disease_key
    when 'sleep' then 'Review overnight oximetry'
    when 'hypothermia' then 'Obtain an ABG'
    when 'pneumonia' then 'Review the chest radiograph'
    when 'aids' then 'Obtain an ABG'
    else 'Inspect the mask fit and the upper airway interface'
  end,
  2,
  'This is indicated in the initial assessment.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'D',
  case s.disease_key
    when 'sleep' then 'Review sedative and opioid use'
    when 'hypothermia' then 'Review electrolytes and the CBC'
    when 'pneumonia' then 'Obtain an ABG'
    when 'aids' then 'Review LDH and the CD4 count'
    else 'Review the residual AHI on the device download'
  end,
  2,
  'This is indicated in the initial assessment.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 1
union all
select st.step_id, 'E',
  case s.disease_key
    when 'sleep' then 'Review the CBC'
    when 'hypothermia' then 'Assess responsiveness and airway protection'
    when 'pneumonia' then 'Review the CBC and lactate'
    when 'aids' then 'Review the CBC'
    else 'Obtain an ABG'
  end,
  1,
  'This provides supporting information.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 1
union all select st.step_id, 'F', 'Delay treatment until the entire diagnostic panel is completed', -3, 'This delays indicated care.' from _amx_steps st where st.step_order = 1
union all select st.step_id, 'G', 'Transfer to a low-acuity area before the evaluation is complete', -3, 'This is unsafe.' from _amx_steps st where st.step_order = 1

union all
select st.step_id, 'A',
  case s.disease_key
    when 'sleep' then 'Arrange attended polysomnography with positive-pressure titration'
    when 'hypothermia' then 'Handle gently, provide warmed humidified oxygen, begin active core rewarming, and infuse warmed IV fluids'
    when 'pneumonia' then 'Provide high-concentration oxygen, obtain cultures, begin antibiotics, and start aggressive pulmonary hygiene'
    when 'aids' then 'Provide oxygen, begin trimethoprim-sulfamethoxazole and corticosteroids, and admit to monitored care'
    else 'Refit the interface, add heated humidification, correct mask leak, and repeat CPAP titration if needed'
  end,
  3,
  'This is the best first recommendation.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 2
union all select st.step_id, 'B', 'Use oxygen alone and defer the disease-specific plan', -3, 'This is inadequate.' from _amx_steps st where st.step_order = 2
union all select st.step_id, 'C', 'Delay all therapy until the patient becomes more unstable', -3, 'This is unsafe.' from _amx_steps st where st.step_order = 2
union all select st.step_id, 'D', 'Move the patient to an unmonitored setting after brief improvement', -3, 'This is not appropriate.' from _amx_steps st where st.step_order = 2

union all
select st.step_id, 'A',
  case s.disease_key
    when 'sleep' then 'Review the polysomnography report'
    when 'hypothermia' then 'Repeat the core temperature'
    when 'pneumonia' then 'Repeat the ABG'
    when 'aids' then 'Repeat the ABG'
    else 'Review the updated leak report'
  end,
  2,
  'This is indicated in reassessment.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'B',
  case s.disease_key
    when 'sleep' then 'Determine whether the events are primarily obstructive or central'
    when 'hypothermia' then 'Repeat the ABG'
    when 'pneumonia' then 'Review the repeat chest radiograph'
    when 'aids' then 'Review the induced sputum result'
    else 'Review the residual AHI'
  end,
  2,
  'This is indicated in reassessment.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'C',
  case s.disease_key
    when 'sleep' then 'Repeat the daytime ABG'
    when 'hypothermia' then 'Assess the cardiac rhythm again'
    when 'pneumonia' then 'Review culture and antibiotic data'
    when 'aids' then 'Review the repeat chest radiograph'
    else 'Review overnight oximetry after the interface change'
  end,
  2,
  'This helps guide the next decision.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'D',
  case s.disease_key
    when 'sleep' then 'Assess mask fit and pressure tolerance'
    when 'hypothermia' then 'Review perfusion and electrolyte response'
    when 'pneumonia' then 'Determine whether ventilatory support will be needed if fatigue worsens'
    when 'aids' then 'Determine whether ICU-level support is now required'
    else 'Review nightly usage time and patient comfort'
  end,
  2,
  'This is the key progression check.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 3
union all
select st.step_id, 'E',
  case s.disease_key
    when 'sleep' then 'Review the CBC again'
    when 'hypothermia' then 'Assess airway protection'
    when 'pneumonia' then 'Review the CBC and lactate trend'
    when 'aids' then 'Review the CBC'
    else 'Review the daytime ABG'
  end,
  1,
  'This adds supporting information.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 3
union all select st.step_id, 'F', 'Stop close monitoring after the first response to treatment', -3, 'This is unsafe.' from _amx_steps st where st.step_order = 3
union all select st.step_id, 'G', 'Plan discharge or de-escalation before the reassessment is complete', -3, 'This is premature.' from _amx_steps st where st.step_order = 3

union all
select st.step_id, 'A',
  case s.disease_key
    when 'sleep' then 'Begin bilevel positive airway pressure and arrange close follow-up for adherence and weight management'
    when 'hypothermia' then 'Continue active core rewarming and ICU-level monitoring until temperature and ventilation stabilize'
    when 'pneumonia' then 'Continue ICU or step-down care with high-flow support and prepare for intubation if fatigue worsens'
    when 'aids' then 'Continue ICU-level care while PCP therapy is maintained and escalate ventilatory support as needed'
    else 'Continue CPAP with the new interface and humidification and arrange close sleep follow-up'
  end,
  3,
  'This is the best next recommendation.'
from _amx_steps st join _amx_seed s on s.case_number = st.case_number where st.step_order = 4
union all select st.step_id, 'B', 'Keep the current approach unchanged and reassess much later', -3, 'This delays needed follow-up or escalation.' from _amx_steps st where st.step_order = 4
union all select st.step_id, 'C', 'Discontinue therapy after brief improvement', -3, 'This is unsafe.' from _amx_steps st where st.step_order = 4
union all select st.step_id, 'D', 'Transfer or discharge without a clear follow-up plan', -3, 'This is not appropriate.' from _amx_steps st where st.step_order = 4;

insert into public.cse_rules (step_id, rule_priority, rule_type, rule_value, next_step_id, outcome_text, vitals_delta)
select s1.step_id, 1, 'SCORE_AT_LEAST', '7'::jsonb, s2.step_id,
  case s.disease_key
    when 'sleep' then 'Initial evaluation identifies severe sleep-disordered breathing and chronic hypoventilation risk.'
    when 'hypothermia' then 'Severe hypothermia with ventilatory depression is identified early.'
    when 'pneumonia' then 'Consolidation, hypoxemia, and infection severity are identified.'
    when 'aids' then 'Diffuse opportunistic pulmonary infection is recognized with severe hypoxemia.'
    else 'The source of CPAP failure is identified as leak and interface intolerance.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _amx_steps s1 join _amx_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
join _amx_seed s on s.case_number = s1.case_number
where s1.step_order = 1
union all
select s1.step_id, 99, 'DEFAULT', null, s2.step_id,
  'Assessment is incomplete, and the patient remains at risk of deterioration.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _amx_steps s1 join _amx_steps s2 on s2.case_number = s1.case_number and s2.step_order = 2
where s1.step_order = 1
union all
select s2.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, s3.step_id,
  case s.disease_key
    when 'sleep' then 'Diagnostic testing is arranged, and the patient remains stable enough to continue the workup.'
    when 'hypothermia' then 'Active rewarming is underway, and perfusion begins to improve.'
    when 'pneumonia' then 'Initial treatment is started, but significant hypoxemia persists.'
    when 'aids' then 'Targeted PCP therapy is started, but severe hypoxemia persists.'
    else 'Interface optimization is started, and comfort begins to improve.'
  end,
  case s.disease_key
    when 'sleep' then '{"spo2":1,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0,"etco2":-1}'::jsonb
    when 'hypothermia' then '{"spo2":4,"hr":12,"rr":2,"bp_sys":8,"bp_dia":6,"etco2":-6}'::jsonb
    when 'pneumonia' then '{"spo2":2,"hr":-4,"rr":-2,"bp_sys":-2,"bp_dia":-2,"etco2":2}'::jsonb
    when 'aids' then '{"spo2":0,"hr":-2,"rr":2,"bp_sys":-4,"bp_dia":-4,"etco2":-2}'::jsonb
    else '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":-2,"bp_dia":-2,"etco2":-2}'::jsonb
  end
from _amx_steps s2 join _amx_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
join _amx_seed s on s.case_number = s2.case_number
where s2.step_order = 2
union all
select s2.step_id, 99, 'DEFAULT', null, s3.step_id,
  'Initial management is inadequate, and instability persists.',
  '{"spo2":-5,"hr":5,"rr":4,"bp_sys":-4,"bp_dia":-3,"etco2":4}'::jsonb
from _amx_steps s2 join _amx_steps s3 on s3.case_number = s2.case_number and s3.step_order = 3
where s2.step_order = 2
union all
select s3.step_id, 1, 'SCORE_AT_LEAST', '6'::jsonb, s4.step_id,
  case s.disease_key
    when 'sleep' then 'Diagnostic results support long-term positive-pressure therapy.'
    when 'hypothermia' then 'Rewarming and rhythm reassessment support continued critical monitoring.'
    when 'pneumonia' then 'Reassessment confirms ongoing high-acuity respiratory risk.'
    when 'aids' then 'Reassessment confirms persistent PCP-related respiratory failure.'
    else 'Interface changes improve adherence and reduce residual obstructive events.'
  end,
  '{"spo2":0,"hr":0,"rr":0,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
from _amx_steps s3 join _amx_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
join _amx_seed s on s.case_number = s3.case_number
where s3.step_order = 3
union all
select s3.step_id, 99, 'DEFAULT', null, s4.step_id,
  'Reassessment is incomplete, and the patient remains at risk of worsening disease.',
  '{"spo2":-4,"hr":4,"rr":3,"bp_sys":-4,"bp_dia":-3,"etco2":3}'::jsonb
from _amx_steps s3 join _amx_steps s4 on s4.case_number = s3.case_number and s4.step_order = 4
where s3.step_order = 3
union all
select s4.step_id, 1, 'INCLUDES_ALL', '["A"]'::jsonb, null,
  case s.disease_key
    when 'sleep' then 'Final outcome: bilevel therapy is started with close follow-up for chronic sleep-related hypoventilation.'
    when 'hypothermia' then 'Final outcome: rewarming continues in the ICU, and cardiopulmonary stability improves.'
    when 'pneumonia' then 'Final outcome: the patient remains in monitored care with readiness for ventilatory escalation.'
    when 'aids' then 'Final outcome: ICU-level care continues while PCP therapy and respiratory support are maintained.'
    else 'Final outcome: CPAP adherence improves with the new interface and structured follow-up.'
  end,
  case s.disease_key
    when 'sleep' then '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0,"etco2":-2}'::jsonb
    when 'hypothermia' then '{"spo2":6,"hr":18,"rr":4,"bp_sys":12,"bp_dia":8,"etco2":-8}'::jsonb
    when 'pneumonia' then '{"spo2":2,"hr":-2,"rr":-2,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
    when 'aids' then '{"spo2":1,"hr":-2,"rr":-1,"bp_sys":0,"bp_dia":0,"etco2":0}'::jsonb
    else '{"spo2":2,"hr":-2,"rr":-1,"bp_sys":-2,"bp_dia":-2,"etco2":-2}'::jsonb
  end
from _amx_steps s4 join _amx_seed s on s.case_number = s4.case_number where s4.step_order = 4
union all
select s4.step_id, 99, 'DEFAULT', null, null,
  'Final outcome: delayed escalation or poor follow-up leads to recurrent instability.',
  '{"spo2":-6,"hr":6,"rr":4,"bp_sys":-6,"bp_dia":-4,"etco2":4}'::jsonb
from _amx_steps s4 where s4.step_order = 4;

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
join _amx_target t on t.case_id = s.case_id
where s.case_id in (select case_id from _amx_target);

commit;
