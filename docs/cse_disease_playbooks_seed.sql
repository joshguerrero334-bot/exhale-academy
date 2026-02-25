-- Exhale Academy CSE disease playbooks seed starter
-- Uses upsert so you can repeatedly refine disease teaching.

begin;

insert into public.cse_disease_playbooks (
  disease_slug,
  disease_name,
  track,
  summary,
  emergency_cues,
  scenario_setting_templates,
  scenario_patient_summary_templates,
  scenario_history_templates,
  ig_visual_priorities,
  ig_bedside_priorities,
  ig_basic_lab_priorities,
  ig_special_test_priorities,
  ig_avoid_or_penalize,
  dm_best_actions,
  dm_reasonable_alternatives,
  dm_unsafe_actions,
  abg_patterns,
  oxygenation_patterns,
  ventilator_patterns,
  disposition_guidance,
  scoring_guidance,
  author_notes,
  source_name,
  source_revision
) values
(
  'copd',
  'Chronic Obstructive Pulmonary Disease (COPD)',
  'non_critical',
  'COPD is a chronic progressive obstructive airway disease that is preventable and treatable but not fully reversible. Non-critical-track cases emphasize selective diagnostics, bronchodilator strategy, controlled oxygen titration, phenotype recognition, exacerbation prevention, and safe disposition.',
  array['new confusion', 'silent chest', 'worsening fatigue with rising CO2 signs'],
  array['ED observation unit', 'urgent care transfer to ED', 'med-surg bedside consult'],
  array[
    'Older adult with chronic tobacco history, prolonged expiratory phase, wheeze, and increased sputum',
    'Emphysema phenotype: dyspneic patient with air trapping and hyperinflation features (pink puffer pattern)',
    'Chronic bronchitis phenotype: productive-cough dominant patient with cyanotic/fluid-retention tendency (blue bloater pattern)'
  ],
  array[
    'Known COPD with baseline exertional dyspnea; current flare over 2-3 days with cough and sputum change',
    'Exposure history should include smoking/tobacco burden, air-pollution irritants, and family/genetic risk context',
    'Chronic bronchitis definition anchor: productive cough for at least 3 months in 2 successive years',
    'Emphysema anchor: irreversible alveolar-wall destruction with permanent distal air-space enlargement and small-airway collapse',
    'Differential recall cue: CBABE = Cystic Fibrosis, Bronchiectasis, Asthma, Bronchitis (Chronic), Emphysema'
  ],
  array[
    'general appearance/color',
    'respiratory rate/pattern',
    'work of breathing',
    'mental status',
    'phenotype cues that distinguish emphysema from chronic bronchitis',
    'appearance comparison: emphysema pink-puffer/thin/barrel-chest vs chronic-bronchitis blue-bloater/cyanotic-stocky with edema-JVD tendency'
  ],
  array[
    'SpO2',
    'heart rate',
    'blood pressure',
    'breath sounds',
    'temperature when infection suspected',
    'cough profile: emphysema later/scant sputum vs chronic bronchitis early/copious sputum',
    'breath-sound profile: emphysema diminished with prolonged expiration vs chronic bronchitis rhonchi/crackles/wheezes',
    'respiratory pattern: emphysema severe dyspnea with pursed-lip/accessory-muscle use vs chronic bronchitis milder dyspnea with less accessory use',
    'chest percussion: emphysema hyperresonant vs chronic bronchitis often normal'
  ],
  array[
    'ABG when ventilation concern present',
    'CBC with WBC if infection suspected',
    'electrolytes/bicarbonate',
    'chest x-ray if complication concern',
    'CXR phenotype comparison: emphysema hyperinflation/small heart/increased retrosternal airspace vs chronic bronchitis prominent vessels/larger heart',
    'ABG phenotype comparison: emphysema hyperventilation with hypoxemia early then hypercapnia late vs chronic bronchitis chronic respiratory acidosis with moderate hypoxemia',
    'lung volume comparison: emphysema increased RV and TLC vs chronic bronchitis increased RV',
    'lung compliance comparison: emphysema increased compliance vs chronic bronchitis near-normal compliance',
    'PFT comparison: both show decreased flow rates; DLCO decreased in emphysema and typically normal in chronic bronchitis',
    'spirometry comparison: both can show post-bronchodilator persistent obstruction with FEV1/FVC < 70%'
  ],
  array[
    'PFT not routine in acute flare',
    'advanced imaging only if alternate diagnosis suspected',
    'when reviewed, emphasize phenotype diagnostics: RV/TLC and compliance differences, DLCO difference, and persistent spirometric obstruction'
  ],
  array['routine urinalysis', 'non-indicated advanced imaging first', 'delayed treatment while broad tests pending'],
  array[
    'short-acting bronchodilator therapy',
    'controlled oxygen targeting safe range',
    'low-flow oxygen strategy: nasal cannula 1-2 L/min or air-entrainment mask 24-28%',
    'systemic steroid when indicated',
    'management choices should reflect emphysema-vs-chronic-bronchitis clinical pattern when relevant',
    'smoking-cessation intervention and referral',
    'disease-management/self-care education',
    'pulmonary-rehab referral when appropriate',
    'trigger and infection prevention planning (influenza/pneumococcal prevention and exposure avoidance)',
    'bronchodilator escalation by phase: SABA/SAMA for acute exacerbation, LABA + LAMA for maintenance, add inhaled steroid for frequent exacerbations',
    'home oxygen follow-up option: consider oxygen-conserving devices (reservoir cannula or transtracheal catheter) when appropriate'
  ],
  array[
    'escalate bronchodilator frequency with close reassessment',
    'noninvasive support if worsening ventilation without immediate crash signs',
    'BiPAP should be considered for acute ventilatory failure in non-critical COPD to avoid intubation when feasible',
    'preventive care counseling: healthy lifestyle and exercise plan'
  ],
  array[
    'high-flow oxygen without reassessment',
    'sedative-first management',
    'discharge despite persistent instability',
    'mucolytics as primary COPD treatment method',
    'antibiotics as routine COPD treatment method'
  ],
  '[
    {"pattern":"emphysema_early","findings":"relative alveolar hyperventilation with hypoxemia","action":"controlled oxygen + bronchodilator strategy and close trend reassessment"},
    {"pattern":"emphysema_late","findings":"progression to hypercapnia/respiratory acidosis in advanced disease","action":"escalate ventilatory support based on fatigue/ABG trajectory"},
    {"pattern":"chronic_bronchitis_typical","findings":"chronic respiratory acidosis (elevated PaCO2 with compensation) with moderate hypoxemia","action":"controlled oxygen and targeted exacerbation management"}
  ]'::jsonb,
  '[
    {"pattern":"moderate hypoxemia","findings":"PaO2 reduced with FiO2 below high-level support","action":"titrate oxygen and treat trigger"},
    {"pattern":"controlled_oxygen_copd","findings":"COPD patient requiring supplemental oxygen without immediate crash features","action":"use low-flow oxygen (NC 1-2 L/min or air-entrainment mask 24-28%) and titrate by reassessment"}
  ]'::jsonb,
  '[]'::jsonb,
  array[
    'discharge only with sustained improvement and safe follow-up',
    'admit when persistent hypoxemia/hypercapnia or high relapse risk',
    'at transition of care, include smoking cessation, disease education, pulmonary rehab, and infection-trigger prevention plan'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson piece 1-8 saved: COPD causes include smoking/tobacco, genetics, and air pollution; disease may present as emphysema, chronic bronchitis, or both. Emphysema = irreversible alveolar-wall destruction with distal air-space enlargement, airway collapse, air trapping, and hyperinflation (pink puffer). Chronic bronchitis = productive cough >=3 months in 2 successive years (blue bloater). Differentiation cues saved for appearance, cough timing/sputum amount, breath sounds, respiratory pattern, percussion, chest x-ray pattern, ABG trends, lung volumes/compliance, PFT-DLCO distinctions, spirometry persistence, and CBC polycythemia timing. Treatment guidance includes low-flow oxygen (NC 1-2 L/min or air-entrainment mask 24-28%), acute SABA/SAMA and maintenance LABA+LAMA with ICS for frequent exacerbations, BiPAP consideration to avoid intubation when feasible in non-critical COPD, home oxygen-conserving devices, and preventive lifestyle/vaccination/exercise counseling. For COPD treatment-method test items, mucolytics and antibiotics should be included as incorrect distractors. Differential memory cue saved: CBABE = Cystic Fibrosis, Bronchiectasis, Asthma, Bronchitis (Chronic), Emphysema.',
  'Exhale Faculty',
  '2026-02-23'
),
(
  'copd',
  'Chronic Obstructive Pulmonary Disease (COPD)',
  'critical',
  'COPD is a chronic progressive obstructive airway disease that is preventable and treatable but not fully reversible. Critical-track cases focus on impending/active respiratory failure, ABG-driven escalation, noninvasive/invasive support decisions, phenotype recognition, and ICU disposition, with post-stabilization prevention planning.',
  array[
    'increased dyspnea',
    'hypoxemia',
    'tachycardia',
    'tachypnea',
    'increased cough and sputum production',
    'change in sputum color or characteristics',
    'accessory-muscle use',
    'peripheral edema',
    'wheezing/chest tightness',
    'altered mental status',
    'exhaustion',
    'silent chest',
    'persistent severe hypoxemia despite escalating support'
  ],
  array['ED resuscitation bay', 'ICU admission handoff', 'rapid response deterioration'],
  array[
    'Known severe COPD with accessory muscle use, diaphoresis, inability to speak full sentences',
    'Critical emphysema pattern: severe dynamic hyperinflation/air trapping with respiratory fatigue risk',
    'Critical chronic-bronchitis pattern: secretion-heavy cyanotic presentation with high decompensation risk'
  ],
  array[
    'Acute deterioration after failed outpatient rescue regimen',
    'Background risk should include smoking/tobacco, pollution exposure, and possible genetic susceptibility',
    'Chronic bronchitis definition anchor remains productive cough >=3 months in 2 successive years',
    'Emphysema anchor remains irreversible alveolar-wall destruction with hyperinflation and airway collapse',
    'Differential recall cue: CBABE = Cystic Fibrosis, Bronchiectasis, Asthma, Bronchitis (Chronic), Emphysema'
  ],
  array[
    'increased dyspnea and tachypnea',
    'tachycardia',
    'increased cough and sputum production with possible sputum-character/color change',
    'accessory-muscle use',
    'peripheral edema',
    'wheezing/chest tightness',
    'cyanosis',
    'fatigue/exhaustion signs',
    'paradoxical breathing pattern',
    'mental status change',
    'critical phenotype cues distinguishing emphysema from chronic bronchitis when clinically relevant',
    'appearance comparison remains testable under decompensation (pink-puffer vs blue-bloater pattern)'
  ],
  array[
    'full vital-sign assessment',
    'continuous SpO2 monitoring with frequent trend reassessment',
    'continuous SpO2 and EtCO2',
    'frequent vital trend',
    'focused airway exam',
    'cough/sputum trajectory and secretion burden pattern',
    'breath-sound pattern including wheeze/rhonchi/crackles vs diffusely diminished prolonged expiration'
  ],
  array[
    'urgent ABG to assess for impending respiratory failure',
    'electrolytes and bicarbonate',
    'portable chest imaging',
    'sputum culture and sensitivity only when infection is suspected (e.g., fever or infectious sputum pattern)',
    'ABG phenotype comparison: chronic respiratory acidosis pattern vs acute deterioration progression',
    'CXR phenotype comparison: emphysema hyperinflation/small heart vs chronic bronchitis prominent vessels/larger heart',
    'lung volume/compliance phenotype comparison: emphysema increased RV and TLC with increased compliance vs chronic bronchitis increased RV with near-normal compliance',
    'PFT phenotype comparison: both decreased flow rates; DLCO reduced in emphysema and generally normal in chronic bronchitis',
    'spirometry comparison: persistent obstruction with post-bronchodilator FEV1/FVC < 70% in both phenotypes',
    'CBC phenotype comparison: RBC/Hb/Hct can rise late in emphysema and in early/late chronic bronchitis'
  ],
  array['advanced testing only after stabilization trajectory is established'],
  array[
    'transport before stabilization',
    'delayed ventilatory support',
    'non-indicated tests ahead of stabilization',
    'spirometry during severe critical exacerbation before stabilization (low immediate value)'
  ],
  array[
    'supplemental oxygen with target PaO2 60-65 torr and SpO2 88-92%',
    'give or increase beta-agonist dosing',
    'add inhaled anticholinergic if not already being given',
    'recommend systemic steroids in addition to inhaled steroids',
    'recommend antibiotics only when sputum is purulent/colored or infection is suspected',
    'if basic treatment is working, expect less wheeze/chest tightness, less work of breathing, normalizing HR/RR, and less accessory-muscle use',
    'if patient worsens (dropping pH, rising CO2, rising fatigue, lower level of consciousness), move to ventilatory support',
    'unless contraindicated, prefer NPPV first because COPD patients are often hard to wean from invasive ventilation',
    'skip NPPV and go straight to intubation/mechanical ventilation if contraindications are present: respiratory arrest, upper-airway obstruction, unable to protect airway, unable to clear secretions, high aspiration risk, cardiac arrest/hemodynamic instability, major mental-status change, active upper-GI bleeding, facial surgery/trauma preventing mask fit, or significant mask air leaks',
    'good starting NPPV settings: IPAP 10, EPAP 5, rate 10, I:E about 1:3, and FiO2 as needed to keep SpO2 at or above 90%',
    'adjust settings as needed to lower tachypnea and accessory-muscle use',
    'to increase ventilation and blow off more CO2, increase IPAP',
    'to increase oxygenation, increase EPAP or FiO2',
    'use ABGs to decide when to switch from NPPV to invasive ventilation',
    'if ABGs get worse within the first 2 hours on NPPV, recommend intubation and mechanical ventilation',
    'if there is no meaningful improvement after 4 hours on NPPV, switch to intubation and mechanical ventilation',
    'always intubate and mechanically ventilate in severe respiratory acidosis (pH < 7.25 with PaCO2 > 60 torr)',
    'look for severe hypoxemia (P/F ratio < 200) as an intubation trigger',
    'look for severe tachypnea (> 35 breaths/min) as an intubation trigger',
    'other major complications that push toward intubation/escalation: metabolic abnormalities, sepsis, severe pneumonia, pulmonary embolism, barotrauma, and pleural effusion',
    'if still getting worse on NPPV, recommend intubation and mechanical ventilation'
  ],
  array['short interval reassessment with escalation thresholds'],
  array[
    'observe-only while failing',
    'sedation before airway/ventilation plan',
    'premature de-escalation of monitoring',
    'using NPPV despite clear contraindications (respiratory arrest, airway compromise, aspiration risk, severe instability, major mental-status change, active upper-GI bleed, or inability to fit/seal mask)',
    'mucolytics as primary COPD treatment method',
    'antibiotics as routine COPD treatment when there is no sign of infection'
  ],
  '[
    {"pattern":"severe_respiratory_acidosis","findings":"pH < 7.25 with PaCO2 > 60 torr","action":"intubate and start mechanical ventilation"},
    {"pattern":"nppv_early_failure","findings":"ABGs worsen within first 2 hours on NPPV","action":"switch from NPPV to intubation/mechanical ventilation"},
    {"pattern":"nppv_no_improvement_4h","findings":"no meaningful improvement after 4 hours on NPPV","action":"switch from NPPV to intubation/mechanical ventilation"},
    {"pattern":"acute_ventilatory_failure","findings":"marked acidemia with high PaCO2","action":"immediate ventilatory support escalation"}
  ]'::jsonb,
  '[
    {"pattern":"severe_hypoxemia_pf","findings":"P/F ratio < 200","action":"recommend intubation/mechanical ventilation"},
    {"pattern":"refractory hypoxemia","findings":"persistent low oxygenation despite high FiO2","action":"PEEP/ventilation strategy escalation and ICU-level management"},
    {"pattern":"controlled_oxygen_before_escalation","findings":"critical-track COPD without immediate intubation criteria","action":"attempt tightly controlled oxygen strategy with rapid reassessment while preparing escalation"}
  ]'::jsonb,
  '[
    {"pattern":"nppv_contraindication_pathway","findings":"any major NPPV contraindication is present (respiratory arrest, airway compromise, aspiration risk, severe instability, major mental-status change, active upper-GI bleed, facial trauma/surgery, or major mask leak)","action":"skip NPPV and recommend intubation with mechanical ventilation"},
    {"pattern":"nppv_initial_setup","findings":"critical COPD not improving on basic treatment but no immediate contraindication to mask ventilation","action":"start with IPAP 10, EPAP 5, rate 10, I:E about 1:3, and set FiO2 to keep SpO2 >= 90%"},
    {"pattern":"nppv_adjustment","findings":"persistent tachypnea/accessory-muscle use and high CO2 trend","action":"increase IPAP to increase ventilation and improve CO2/pH trend; increase EPAP or FiO2 if oxygenation is still low"},
    {"pattern":"tachypnea_failure_threshold","findings":"respiratory rate remains > 35/min despite support","action":"recommend intubation and mechanical ventilation"},
    {"pattern":"complication_escalation","findings":"major complication present (metabolic abnormality, sepsis, severe pneumonia, pulmonary embolism, barotrauma, pleural effusion)","action":"escalate to intubation/mechanical ventilation pathway"},
    {"pattern":"post_intubation_optimization","findings":"still deteriorating on NPPV or unsafe gas exchange","action":"recommend intubation and mechanical ventilation, then titrate settings to stabilize gas exchange"}
  ]'::jsonb,
  array[
    'ICU-level monitoring for unstable or recently stabilized critical flare',
    'during disposition planning, include prevention bundle: smoking cessation, education, pulmonary rehab, and influenza/pneumococcal risk reduction'
  ],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Critical COPD DM guidance saved in plain language: oxygen targets PaO2 60-65 torr and SpO2 88-92%, increase beta-agonist and inhaled anticholinergic support, add systemic steroids, and only use antibiotics when purulent/colored sputum or infection concern is present. Improvement signs saved: less wheeze/chest tightness, less work of breathing, normalizing HR/RR, less accessory-muscle use. Ventilatory escalation triggers saved: dropping pH, rising CO2, increased fatigue, and lower level of consciousness. NPPV-first preference saved (unless contraindicated), with starter settings IPAP 10 / EPAP 5 / rate 10 / I:E about 1:3 and FiO2 to keep SpO2 >= 90%. NPPV-contraindication list saved: respiratory arrest, upper-airway obstruction, unable to protect airway, unable to clear secretions, high aspiration risk, cardiac arrest/hemodynamic instability, major mental-status change, active upper-GI bleed, facial surgery/trauma preventing mask fit, and significant mask leak. Intubation timing saved: if ABGs worsen within 2 hours on NPPV, or no meaningful improvement by 4 hours, switch to mechanical ventilation. Always intubate for severe respiratory acidosis (pH < 7.25 with PaCO2 > 60 torr). Also use P/F < 200, RR > 35, or major complications (metabolic abnormalities, sepsis, severe pneumonia, pulmonary embolism, barotrauma, pleural effusion) as escalation triggers. Adjustment cue saved: increase IPAP for ventilation (CO2/pH), increase EPAP or FiO2 for oxygenation.',
  'Exhale Faculty',
  '2026-02-23'
),
(
  'bronchiectasis',
  'Bronchiectasis',
  'conservative',
  'Bronchiectasis is an irreversible dilation and destruction of bronchial walls, often lower-lobe predominant, causing impaired mucociliary clearance and accumulation of copious secretions.',
  array['increasing sputum burden', 'worsening dyspnea', 'recurrent infective flares'],
  array['ED observation unit', 'outpatient-to-ED escalation', 'inpatient respiratory consult'],
  array[
    'Patient with chronic productive cough and frequent lower-respiratory infections',
    'History suggests copious bronchial secretions and mucus retention',
    'Recognition cue: chronic production of large quantities of purulent sputum strongly suggests bronchiectasis'
  ],
  array[
    'Core pathology: irreversible bronchial dilation and wall destruction',
    'Frequent lower-lobe involvement in one or both lungs',
    'Impaired mucociliary clearance driving secretion accumulation',
    'Etiology cue: approximately half of bronchiectasis cases are associated with cystic fibrosis'
  ],
  array[
    'general appearance/color',
    'respiratory rate/pattern',
    'work of breathing',
    'visible cough/sputum burden',
    'shortness of breath with possible pursed-lip breathing and accessory-muscle use',
    'cyanotic skin findings',
    'digital clubbing at nail beds',
    'barrel chest with increased A-P diameter'
  ],
  array[
    'SpO2',
    'heart rate',
    'blood pressure',
    'breath sounds',
    'sputum amount/character trend',
    'cough character: purulent foul-smelling sputum',
    'percussion note trend: hyperresonant/tympanic pattern',
    'breath sounds may be diminished with possible wheezing'
  ],
  array['CBC when infection concern present', 'basic chemistry/electrolytes', 'ABG if ventilation concern present'],
  array['chest imaging as clinically indicated for structural disease burden'],
  array['non-indicated tests before stabilization', 'delay in secretion-focused management'],
  array[
    'airway-clearance-focused care',
    'targeted treatment of acute exacerbation triggers',
    'oxygen titration based on severity and reassessment',
    'bronchopulmonary hygiene to mobilize retained secretions',
    'lung expansion therapy',
    'antibiotics when infection is present',
    'expectorants to assist secretion clearance',
    'aerosolized sympathomimetic and parasympatholytic bronchodilator agents'
  ],
  array[
    'escalate support with short-interval reassessment',
    'provide oxygen when hypoxemia is present',
    'prepare escalation to mechanical ventilation for acute ventilatory failure'
  ],
  array['observe-only while secretion burden worsens', 'premature discharge with unresolved instability'],
  '[]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb,
  array['discharge only with sustained stability and clear follow-up plan', 'admit for unresolved hypoxemia/instability or severe exacerbation risk'],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson piece 4 saved (Bronchiectasis): irreversible bronchial dilation and destruction, often lower-lobe predominant; impaired mucociliary clearance causes copious retained bronchial secretions. Recognition cues include chronic large-volume purulent foul-smelling sputum, dyspnea with possible pursed-lip/accessory-muscle breathing, barrel chest with increased A-P diameter, cyanosis, and digital clubbing. IG exam targets include hyperresonant/tympanic percussion and diminished breath sounds with possible wheezing. Treatment guidance now includes bronchopulmonary hygiene, lung expansion therapy, infection-directed antibiotics, expectorants, aerosolized sympathomimetic/parasympatholytic agents, oxygen for hypoxemia, and escalation to mechanical ventilation for acute ventilatory failure. Etiology cue retained: approximately half of bronchiectasis is associated with cystic fibrosis.',
  'Exhale Faculty',
  '2026-02-23'
),
(
  'bronchiectasis',
  'Bronchiectasis',
  'critical',
  'Critical bronchiectasis care prioritizes decompensation recognition in high-secretion disease with irreversible bronchial structural damage and impaired mucociliary clearance.',
  array['respiratory fatigue', 'worsening oxygenation', 'rapidly increasing secretion burden'],
  array['ED resuscitation bay', 'ICU transfer/handoff', 'rapid response deterioration'],
  array[
    'Patient with known bronchiectasis and heavy secretions in acute respiratory decline',
    'Recurrent infective history with current decompensation concern',
    'Recognition cue: chronic large-volume purulent sputum pattern supports bronchiectasis phenotype'
  ],
  array[
    'Core pathology: irreversible bronchial dilation and wall destruction',
    'Often lower-lobe predominant disease burden',
    'Impaired mucociliary clearance with copious secretion retention',
    'Etiology cue: approximately half of bronchiectasis cases are linked to cystic fibrosis'
  ],
  array[
    'cyanosis/work of breathing',
    'mental status change',
    'secretion burden trajectory',
    'dyspnea severity including pursed-lip pattern and accessory-muscle use',
    'digital clubbing and cyanotic pattern',
    'barrel chest with increased A-P diameter when present'
  ],
  array[
    'continuous SpO2',
    'frequent vitals',
    'focused breath-sound and secretion assessment',
    'cough/secretion quality: purulent foul-smelling sputum',
    'percussion note trend: hyperresonant/tympanic',
    'breath sounds may be diminished with possible wheeze'
  ],
  array['urgent ABG when indicated', 'CBC/chemistry for acute trend support'],
  array['portable imaging as clinically indicated after initial stabilization'],
  array['transport before stabilization', 'delay in escalation during respiratory decline'],
  array[
    'rapid reassessment with escalation thresholds',
    'secretion-directed support plus oxygen/ventilatory strategy as indicated',
    'bronchopulmonary hygiene with active secretion management',
    'lung expansion therapy',
    'aerosolized sympathomimetic and parasympatholytic bronchodilator agents',
    'infection-directed antibiotics when infection is present',
    'expectorant therapy for secretion mobilization',
    'oxygen therapy when hypoxemia is present'
  ],
  array['NIV/intubation pathway when failure criteria develop', 'mechanical ventilation for acute ventilatory failure'],
  array['observe-only while worsening', 'premature de-escalation of monitoring'],
  '[]'::jsonb,
  '[]'::jsonb,
  '[]'::jsonb,
  array['ICU-level monitoring for unstable or recently stabilized critical presentations'],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson piece 4 saved (Bronchiectasis critical): irreversible bronchial structural disease with lower-lobe tendency and impaired mucociliary clearance, producing copious retained secretions that increase decompensation risk. Recognition cues include chronic large-volume purulent foul-smelling sputum, dyspnea with possible pursed-lip/accessory-muscle breathing, barrel chest with increased A-P diameter, cyanosis, and digital clubbing. IG exam targets include hyperresonant/tympanic percussion and diminished breath sounds with possible wheezing. Treatment guidance now includes bronchopulmonary hygiene, lung expansion therapy, infection-directed antibiotics, expectorants, aerosolized sympathomimetic/parasympatholytic agents, oxygen for hypoxemia, and mechanical ventilation for acute ventilatory failure. Etiology cue retained: approximately half of bronchiectasis is associated with cystic fibrosis.',
  'Exhale Faculty',
  '2026-02-23'
),
(
  'asthma',
  'Asthma',
  'conservative',
  'Asthma is a chronic obstructive disease with episodic airway narrowing that causes wheezing and coughing. It is considered reversible because obstruction can improve with appropriate drugs or stimuli.',
  array['worsening wheeze', 'increasing cough after trigger exposure', 'rising work of breathing'],
  array['ED observation unit', 'urgent care escalation', 'outpatient flare assessment'],
  array[
    'Patient with episodic wheezing/coughing linked to exposure triggers',
    'Reversible obstructive pattern between episodes'
  ],
  array[
    'Core concept: chronic obstructive disease with reversible airway narrowing',
    'Episode triggers include cigarette smoke, pollen, dust, mold, exercise, infections, cold air, GERD, stress, and chemical exposure',
    'IG teaching point: identify likely trigger and counsel future trigger avoidance',
    'Symptoms/signs can include dyspnea, chest tightness, wheeze, pursed-lip breathing, tachypnea, accessory-muscle use, cyanosis, increased A-P diameter',
    'Severe episodes may include anxiety, diaphoresis, speaking difficulty, tachycardia, and pulsus paradoxus'
  ],
  array[
    'general appearance/color',
    'respiratory rate/pattern',
    'work of breathing',
    'wheeze/cough episode pattern',
    'anxious/diaphoretic appearance and ability to speak',
    'increased A-P chest diameter and cyanosis pattern'
  ],
  array[
    'SpO2',
    'heart rate',
    'blood pressure',
    'breath sounds with wheeze focus',
    'trigger-exposure history tied to current episode',
    'tachypnea and accessory-muscle use pattern',
    'tachycardia with pulsus paradoxus in severe episodes',
    'percussion note: hyperresonant',
    'breath-sound spectrum: wheeze, or diminished/near-silent airflow in very severe episodes'
  ],
  array[
    'ABG if ventilation concern present',
    'CBC/chemistry as clinically indicated',
    'ABG expectation: early acute hyperventilation with hypoxemia, shifting to respiratory acidosis with hypoxemia as severity worsens'
  ],
  array[
    'objective airflow testing when clinically stable enough',
    'recommend chest x-ray: may show increased A-P diameter and flattened diaphragms',
    'recommend pre/post bronchodilator testing: post-treatment improvement supports reversibility',
    'PFT expectation: decreased flow rates with normal DLCO'
  ],
  array['non-indicated broad testing before stabilization', 'ignoring trigger history during assessment'],
  array[
    'trigger avoidance/removal',
    'reversible-obstruction focused bronchodilator therapy',
    'anti-inflammatory escalation based on response',
    'acute attack: provide oxygen when hypoxemia is present',
    'acute attack: short-acting bronchodilator aerosol + anticholinergic (e.g., albuterol/DuoNeb with Atrovent)',
    'acute attack: if breath sounds fail to improve, consider continuous aerosol therapy',
    'acute attack: corticosteroids (oral or IV)',
    'acute attack: closely monitor vital signs',
    'acute ventilatory failure: intubation and mechanical ventilation when rising PaCO2 with decreasing pH is present',
    'long-term control: avoid patient-specific triggers',
    'long-term control: bronchodilator plan can include short-acting, long-acting, and anticholinergic agents',
    'long-term control: inhaled corticosteroids',
    'long-term control: bronchopulmonary hygiene therapy',
    'long-term control: monitor peak flow to track airway obstruction'
  ],
  array[
    'short-interval reassessment with response-based escalation',
    'emergency principle: in acute severe attack, stop additional nonessential information gathering and treat immediately'
  ],
  array[
    'observe-only despite worsening symptoms',
    'failure to address clear trigger exposure',
    'continuing information gathering without initiating emergency treatment in a severe acute attack'
  ],
  '[
    {"pattern":"asthma_early","findings":"acute hyperventilation with hypoxemia","action":"treat exacerbation and reassess closely"},
    {"pattern":"asthma_worsening","findings":"respiratory acidosis with hypoxemia in severe progression","action":"escalate ventilatory support urgently"}
  ]'::jsonb,
  '[
    {"pattern":"asthma_hypoxemia","findings":"hypoxemia during exacerbation","action":"provide oxygen and escalate therapy based on response"}
  ]'::jsonb,
  '[]'::jsonb,
  array['discharge only after sustained response and clear trigger-action plan', 'admit when instability or poor response persists'],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson piece 3 saved (Asthma): chronic obstructive disease with reversible airway narrowing causing episodes of wheezing and coughing. Trigger set saved: cigarette smoke, pollen, dust, mold, exercise, infections, cold air, GERD, stress, and chemical exposure. IG findings saved: dyspnea/chest tightness/wheeze, pursed-lip breathing, tachypnea, accessory-muscle use, cyanosis, increased A-P diameter, anxiety/diaphoresis, speaking difficulty, tachycardia, pulsus paradoxus, hyperresonant percussion, and severe diminished airflow pattern. Diagnostic expectations saved: CXR increased A-P diameter + flattened diaphragms, ABG early hyperventilation+hypoxemia then respiratory acidosis+hypoxemia, PFT decreased flow with normal DLCO, and pre/post bronchodilator improvement confirming reversibility. DM treatment split saved: acute emergency management (oxygen, SABA + anticholinergic, possible continuous aerosol, corticosteroids, close vitals, intubation/mechanical ventilation for rising PaCO2 + falling pH) versus long-term control (trigger avoidance, bronchodilators, inhaled corticosteroids, bronchopulmonary hygiene, peak-flow monitoring).',
  'Exhale Faculty',
  '2026-02-23'
),
(
  'asthma',
  'Asthma',
  'critical',
  'Critical asthma care focuses on severe reversible obstructive episodes with rapid deterioration risk requiring close reassessment and escalation.',
  array['severe wheeze or poor air movement', 'escalating respiratory distress', 'fatigue/mental-status change'],
  array['ED resuscitation bay', 'ICU handoff', 'rapid response deterioration'],
  array[
    'Patient in severe asthma episode after trigger exposure',
    'Known reversible obstructive history with current decompensation'
  ],
  array[
    'Core concept remains reversible airway obstruction',
    'Trigger list remains: cigarette smoke, pollen, dust, mold, exercise, infections, cold air, GERD, stress, and chemical exposure',
    'IG severe-episode profile includes dyspnea/chest tightness, tachypnea, accessory-muscle use, cyanosis, anxiety/diaphoresis, speaking difficulty, tachycardia, and pulsus paradoxus',
    'Exam profile includes hyperresonant percussion, wheeze that can progress to markedly diminished airflow in very severe episodes'
  ],
  array[
    'cyanosis/work of breathing',
    'mental status',
    'ability to speak',
    'severe wheeze vs diminished airflow',
    'anxious and diaphoretic appearance',
    'increased A-P chest diameter when present'
  ],
  array[
    'continuous SpO2',
    'frequent vitals',
    'focused breath-sound reassessment',
    'trigger timeline and deterioration trajectory',
    'tachycardia and pulsus paradoxus trend in severe episodes',
    'percussion note: hyperresonant'
  ],
  array[
    'urgent ABG when indicated',
    'basic labs for acute support',
    'ABG expectation: initial acute hyperventilation with hypoxemia, worsening to respiratory acidosis with hypoxemia'
  ],
  array[
    'additional testing after initial stabilization trajectory is established',
    'chest x-ray support: increased A-P diameter and flattened diaphragms',
    'pre/post bronchodilator response supports reversibility profile',
    'PFT expectation when obtainable: decreased flow rates with normal DLCO'
  ],
  array['delay in escalation while distress worsens', 'ongoing trigger exposure without mitigation'],
  array[
    'rapid bronchodilator/anti-inflammatory escalation with close reassessment',
    'oxygen and ventilatory escalation as indicated',
    'acute severe attack is a medical emergency: treat immediately rather than continue nonessential information gathering',
    'acute attack regimen: short-acting bronchodilator aerosol + anticholinergic; consider continuous aerosol if poor improvement',
    'acute attack regimen: corticosteroids (oral/IV) and close vital-sign monitoring',
    'intubation/mechanical ventilation when ventilatory failure pattern appears (rising PaCO2 + decreasing pH)',
    'long-term planning after stabilization: trigger avoidance, bronchodilator maintenance options, inhaled corticosteroids, bronchopulmonary hygiene, peak-flow monitoring'
  ],
  array['NIV/intubation pathway when failure criteria emerge', 'mechanical ventilation for ventilatory failure (rising PaCO2 with decreasing pH)'],
  array[
    'observe-only while failing',
    'premature de-escalation of monitoring',
    'continuing prolonged information gathering instead of emergent treatment in severe acute attack'
  ],
  '[
    {"pattern":"asthma_early","findings":"acute hyperventilation with hypoxemia","action":"aggressive bronchodilator/anti-inflammatory management with close reassessment"},
    {"pattern":"asthma_critical_progression","findings":"respiratory acidosis with hypoxemia","action":"urgent ventilatory escalation pathway"}
  ]'::jsonb,
  '[
    {"pattern":"severe_asthma_hypoxemia","findings":"persistent or worsening hypoxemia","action":"oxygen plus rapid escalation based on response"}
  ]'::jsonb,
  '[]'::jsonb,
  array['ICU-level monitoring for unstable severe asthma episodes'],
  '{"critical_best":3,"strong":2,"helpful":1,"neutral":0,"counterproductive":-1,"very_counterproductive":-2,"dangerous":-3}'::jsonb,
  'Lesson piece 3 saved (Asthma critical): asthma is reversible but can acutely decompensate; severe episodes require rapid escalation. Trigger set saved: cigarette smoke, pollen, dust, mold, exercise, infections, cold air, GERD, stress, and chemical exposure. IG severe findings saved: dyspnea/chest tightness, wheeze that may progress to diminished airflow, tachypnea, accessory-muscle use, cyanosis, anxiety/diaphoresis, speaking difficulty, tachycardia, pulsus paradoxus, hyperresonant percussion, and increased A-P chest diameter. Diagnostic expectations saved: CXR increased A-P diameter + flattened diaphragms, ABG early hyperventilation+hypoxemia then respiratory acidosis+hypoxemia, PFT decreased flow with normal DLCO, and pre/post bronchodilator improvement indicating reversibility. DM treatment split saved: acute emergency management (oxygen, SABA + anticholinergic, possible continuous aerosol, corticosteroids, close vitals, intubation/mechanical ventilation for rising PaCO2 + falling pH) versus long-term control (trigger avoidance, bronchodilators, inhaled corticosteroids, bronchopulmonary hygiene, peak-flow monitoring).',
  'Exhale Faculty',
  '2026-02-23'
)
on conflict (disease_slug, track) do update
set
  disease_name = excluded.disease_name,
  summary = excluded.summary,
  emergency_cues = excluded.emergency_cues,
  scenario_setting_templates = excluded.scenario_setting_templates,
  scenario_patient_summary_templates = excluded.scenario_patient_summary_templates,
  scenario_history_templates = excluded.scenario_history_templates,
  ig_visual_priorities = excluded.ig_visual_priorities,
  ig_bedside_priorities = excluded.ig_bedside_priorities,
  ig_basic_lab_priorities = excluded.ig_basic_lab_priorities,
  ig_special_test_priorities = excluded.ig_special_test_priorities,
  ig_avoid_or_penalize = excluded.ig_avoid_or_penalize,
  dm_best_actions = excluded.dm_best_actions,
  dm_reasonable_alternatives = excluded.dm_reasonable_alternatives,
  dm_unsafe_actions = excluded.dm_unsafe_actions,
  abg_patterns = excluded.abg_patterns,
  oxygenation_patterns = excluded.oxygenation_patterns,
  ventilator_patterns = excluded.ventilator_patterns,
  disposition_guidance = excluded.disposition_guidance,
  scoring_guidance = excluded.scoring_guidance,
  author_notes = excluded.author_notes,
  source_name = excluded.source_name,
  source_revision = excluded.source_revision;

commit;
