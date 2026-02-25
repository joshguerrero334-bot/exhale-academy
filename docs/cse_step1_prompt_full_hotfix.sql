-- Exhale Academy CSE Step-1 narrative prompt full hotfix
-- Rewrites Step 1 prompts across current cases to scenario-first bedside narratives.

begin;

with prompt_map as (
  select *
  from (
    values
      ('case-1-practice-layout-audit', 'You are called to bedside for a 42-year-old male with sudden noisy breathing after a difficult extubation in PACU. He is anxious, using accessory muscles, and speaking only short phrases. What are your next steps?'),
      ('case-2-term-infant-meconium-transition-failure', 'You are called to the warmer for a term female newborn minutes after delivery through meconium-stained fluid, now with weak respirations and poor tone. What are your next steps?'),
      ('case-3-pacu-sudden-postop-respiratory-collapse', 'You are called to bedside for a 67-year-old male in PACU with abrupt desaturation, shallow respirations, and declining mental status after surgery. What are your next steps?'),
      ('case-4-nocturnal-dyspnea-fluid-overload-crisis', 'You are called to bedside for a 71-year-old female who awoke at night with severe dyspnea, orthopnea, frothy sputum, and escalating work of breathing. What are your next steps?'),
      ('case-5-copd-hypercapnic-respiratory-fatigue', 'You are called to bedside for a 64-year-old male with chronic smoker history, worsening dyspnea, fatigue, and progressive CO2 retention signs. What are your next steps?'),
      ('case-6-acute-severe-bronchospasm-fatigue', 'You are called to bedside for a 28-year-old female with abrupt wheeze, tachypnea, and increasing fatigue after allergen exposure. What are your next steps?'),
      ('case-7-sudden-hypoxemia-hemodynamic-strain-pattern', 'You are called to bedside for a 59-year-old male with sudden hypoxemia, pleuritic chest pain, tachycardia, and new hemodynamic strain. What are your next steps?'),
      ('case-8-post-extubation-stridor-respiratory-risk', 'You are called to bedside for a 54-year-old female shortly after extubation with inspiratory stridor, hoarseness, and rising respiratory effort. What are your next steps?'),
      ('case-9-mechanically-ventilated-sudden-desaturation', 'You are called to bedside for a 66-year-old male on mechanical ventilation with sudden desaturation and worsening ventilator alarms. What are your next steps?'),
      ('case-10-neuromuscular-ventilatory-failure-pattern', 'You are called to bedside for a 47-year-old female with progressive generalized weakness, shallow breathing, and signs of ventilatory muscle fatigue. What are your next steps?'),
      ('copd-non-critical-emphysema-phenotype', 'You are called to bedside for a 63-year-old male with chronic dyspnea, barrel chest pattern, and worsening exertional breathlessness over several days. What are your next steps?'),
      ('copd-non-critical-chronic-bronchitis-phenotype', 'You are called to bedside for a 61-year-old female with chronic productive cough, wheeze, and increased sputum volume with new hypoxemia. What are your next steps?'),
      ('copd-critical-nppv-failure-escalation', 'You are called to bedside for a 68-year-old male with severe dyspnea despite recent noninvasive support, now showing fatigue and worsening gas exchange. What are your next steps?'),
      ('copd-critical-nppv-contraindication-pathway', 'You are called to bedside for a 72-year-old female in severe respiratory distress with confusion, poor secretion clearance, and worsening instability. What are your next steps?'),
      ('trauma-critical-tension-pneumothorax', 'You are called to bedside for a 34-year-old male after blunt chest trauma with acute distress, unilateral chest movement changes, and rapidly worsening perfusion. What are your next steps?'),
      ('trauma-critical-hemothorax', 'You are called to bedside for a 41-year-old female after chest trauma with severe pleuritic pain, dyspnea, and unilateral breath-sound reduction. What are your next steps?'),
      ('trauma-critical-flail-chest-contusion', 'You are called to bedside for a 57-year-old male after motor vehicle crash with paradoxical chest wall motion, severe pain, and rising oxygen need. What are your next steps?'),
      ('trauma-critical-ventilator-pneumothorax', 'You are called to bedside for a 49-year-old female trauma patient on a ventilator with sudden high-pressure alarms and falling delivered volumes. What are your next steps?'),
      ('ards-critical-pneumonia-refractory-hypoxemia', 'You are called to bedside for a 58-year-old male with rapidly worsening respiratory failure after severe pneumonia and escalating oxygen requirements. What are your next steps?'),
      ('ards-critical-sepsis-lung-protective-ventilation', 'You are called to bedside for a 62-year-old female with sepsis, diffuse respiratory distress, and refractory hypoxemia despite current support. What are your next steps?'),
      ('ards-critical-aspiration-acute-whiteout-pattern', 'You are called to bedside for a 45-year-old male after aspiration event with acute tachypnea, hypoxemia, and rapid decline in gas exchange. What are your next steps?'),
      ('ards-critical-pancreatitis-prone-position-pathway', 'You are called to bedside for a 53-year-old female with severe pancreatitis and worsening bilateral oxygenation failure despite mechanical ventilation. What are your next steps?'),
      ('ards-critical-shock-inhalational-injury-mixed-trigger', 'You are called to bedside for a 39-year-old male with shock physiology and inhalational exposure, now with severe hypoxemia and diffuse respiratory distress. What are your next steps?'),
      ('neuromuscular-critical-myasthenia-gravis-crisis', 'You are called to bedside for a 36-year-old female with fluctuating weakness, ptosis, dysphagia, and increasing shallow breathing. What are your next steps?'),
      ('neuromuscular-critical-guillain-barre-ascending-paralysis', 'You are called to bedside for a 44-year-old male with recent viral illness followed by ascending weakness and progressive ventilatory compromise. What are your next steps?'),
      ('adult-med-surg-critical-drug-overdose-airway-protection', 'You are called to bedside for a 29-year-old male with altered mental status, slow shallow respirations, and high aspiration risk after suspected ingestion. What are your next steps?'),
      ('neuromuscular-critical-muscular-dystrophy-hypoventilation', 'You are called to bedside for a 22-year-old female with chronic neuromuscular disease, worsening nocturnal symptoms, and progressive daytime hypoventilation signs. What are your next steps?'),
      ('neuromuscular-critical-stroke-neuro-respiratory-failure', 'You are called to bedside for a 69-year-old male with sudden neurologic deficits, reduced consciousness, and irregular breathing pattern. What are your next steps?'),
      ('neuromuscular-critical-tetanus-airway-risk', 'You are called to bedside for a 52-year-old female with recent puncture wound, jaw stiffness, dysphagia, and worsening respiratory muscle involvement. What are your next steps?'),
      ('cardiovascular-critical-chf-cardiogenic-pulmonary-edema', 'You are called to bedside for a 74-year-old male with severe orthopnea, crackles, and pink frothy sputum with rapidly worsening oxygenation. What are your next steps?'),
      ('cardiovascular-critical-myocardial-infarction-ischemic-crisis', 'You are called to bedside for a 61-year-old female with crushing chest pain, diaphoresis, and acute respiratory distress. What are your next steps?'),
      ('cardiovascular-critical-shock-perfusion-failure', 'You are called to bedside for a 56-year-old male with hypotension, cool clammy skin, altered mentation, and signs of poor perfusion. What are your next steps?'),
      ('cardiovascular-critical-cor-pulmonale-right-heart-strain', 'You are called to bedside for a 65-year-old female with chronic lung disease history, worsening edema, JVD, and progressive dyspnea. What are your next steps?'),
      ('cardiovascular-critical-pulmonary-embolism-postop-sudden-deadspace', 'You are called to bedside for a 58-year-old postoperative male with sudden dyspnea, pleuritic chest pain, hemoptysis, and tachycardia. What are your next steps?'),
      ('pediatric-critical-croup-gradual-barking-stridor', 'You are called to bedside for a 3-year-old male with barking cough, inspiratory noise, and increasing nighttime work of breathing. What are your next steps?'),
      ('pediatric-critical-epiglottitis-sudden-thumb-sign-emergency', 'You are called to bedside for a 6-year-old female with high fever, drooling, muffled voice, and tripod positioning. What are your next steps?'),
      ('pediatric-critical-bronchiolitis-rsv-edema-apnea-risk', 'You are called to bedside for a 7-month-old male with URI progression, feeding intolerance, tachypnea, and retractions. What are your next steps?'),
      ('pediatric-critical-cystic-fibrosis-secretion-burden', 'You are called to bedside for a 12-year-old female with thick secretions, increased cough burden, and worsening dyspnea. What are your next steps?'),
      ('pediatric-critical-foreign-body-aspiration-unilateral-wheeze', 'You are called to bedside for a 2-year-old female with sudden coughing episode, unilateral breath-sound change, and acute respiratory distress. What are your next steps?'),
      ('neonatal-critical-delivery-room-apgar-resuscitation', 'You are called to the warmer for a term male newborn minutes after delivery with poor tone and weak respiratory effort. What are your next steps?'),
      ('neonatal-critical-meconium-aspiration-vigor-intubation-threshold', 'You are called to the warmer for a term female newborn delivered through thick meconium with worsening respiratory distress. What are your next steps?'),
      ('neonatal-critical-apnea-of-prematurity-bradycardia-episodes', 'You are called to bedside for a 31-week male preterm neonate in NICU with recurrent apnea episodes, bradycardia, and desaturation. What are your next steps?'),
      ('neonatal-critical-irds-surfactant-deficiency-ground-glass', 'You are called to bedside for a 30-week female preterm neonate with grunting, nasal flaring, and rising oxygen requirement. What are your next steps?'),
      ('neonatal-critical-congenital-heart-defect-cyanotic-shunt', 'You are called to bedside for a 2-day-old male neonate with persistent cyanosis and limited response to supplemental oxygen. What are your next steps?'),
      ('neonatal-critical-bpd-chronic-oxygen-dependence', 'You are called to bedside for a 4-month-old female former preterm infant with chronic oxygen dependence and worsening tachypnea. What are your next steps?'),
      ('neonatal-critical-cdh-surgical-emergency-mediastinal-shift', 'You are called to delivery room for a term male newborn with severe respiratory distress and asymmetric chest findings immediately after birth. What are your next steps?'),
      ('adult-medical-critical-sleep-apnea-polysomnography-pathway', 'You are called to bedside for a 51-year-old male with obesity, loud snoring history, daytime somnolence, and worsening nocturnal desaturation. What are your next steps?'),
      ('adult-medical-critical-hypothermia-rewarming-resuscitation', 'You are called to bedside for a 47-year-old female after prolonged cold exposure with bradypnea, altered mentation, and hemodynamic instability. What are your next steps?'),
      ('adult-medical-critical-pneumonia-consolidation-hypoxemia', 'You are called to bedside for a 63-year-old male with fever, productive cough, pleuritic discomfort, and escalating hypoxemia. What are your next steps?'),
      ('adult-medical-critical-aids-opportunistic-pcp-pathway', 'You are called to bedside for a 39-year-old female with immunocompromised history, progressive dyspnea, dry cough, and severe exertional desaturation. What are your next steps?'),
      ('adult-medical-critical-renal-diabetes-kussmaul-acidosis', 'You are called to bedside for a 46-year-old male with renal-metabolic disease, deep rapid respirations, dehydration signs, and altered sensorium. What are your next steps?'),
      ('adult-medical-critical-thoracic-surgery-postop-complications', 'You are called to bedside for a 68-year-old female after thoracic surgery with sudden dyspnea, chest discomfort, and worsening oxygenation. What are your next steps?'),
      ('adult-neuro-critical-head-trauma-cheyne-stokes-icp', 'You are called to bedside for a 33-year-old male with severe head injury, declining consciousness, and abnormal breathing rhythm. What are your next steps?'),
      ('adult-neuro-critical-spinal-injury-airway-stability', 'You are called to bedside for a 27-year-old female with cervical trauma, weak cough, and progressive ventilatory muscle compromise. What are your next steps?'),
      ('adult-medical-critical-obstructive-sleep-apnea-interface-optimization', 'You are called to bedside for a 57-year-old male with obesity hypoventilation pattern, persistent daytime hypercapnia, and poor nighttime mask tolerance. What are your next steps?')
  ) as t(slug, prompt_base)
),
updated as (
  update public.cse_steps s
  set prompt = trim(pm.prompt_base) ||
    case
      when s.max_select is not null then ' SELECT AS MANY AS INDICATED (MAX ' || s.max_select::text || ').'
      else ' SELECT AS MANY AS INDICATED.'
    end
  from public.cse_cases c
  join prompt_map pm on pm.slug = c.slug
  where s.case_id = c.id
    and s.step_order = 1
  returning c.slug
)
select count(*) as updated_step1_prompts from updated;

-- Cleanup any stale phrase that should never be shown.
update public.cse_steps
set prompt = regexp_replace(prompt, '\s*Opening monitor data is available now\.\s*', ' ', 'gi')
where prompt ~* 'Opening monitor data is available now\.';

update public.cse_steps
set prompt = regexp_replace(prompt, '\s+', ' ', 'g')
where prompt ~ '\s{2,}';

commit;

-- Verification query
select c.slug, s.step_order, s.prompt
from public.cse_steps s
join public.cse_cases c on c.id = s.case_id
where s.step_order = 1
order by c.case_number nulls last, c.slug;
