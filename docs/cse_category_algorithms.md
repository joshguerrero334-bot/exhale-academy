# Exhale CSE Category Algorithms (A-G)

This is the clinical source of truth for case-writing.  
If a case option or branch does not match the algorithm for that category, it should be rewritten.

## How to use this file
1. Pick the NBRC category for the case.
2. Use the matching algorithm below to build IG and DM choices.
3. Ensure escalation and disposition follow the listed trigger thresholds.
4. Do not reveal diagnosis in Step 1. Let data reveal it progressively.

## A) Adult Chronic Airways Disease
### Common patterns
- COPD exacerbation (emphysema/chronic bronchitis phenotype)
- Severe asthma or bronchospasm
- NPPV trial vs intubation pathway

### IG priorities
- Work of breathing, accessory muscle use, speech tolerance, mental status
- Breath sounds (wheeze vs poor air movement)
- ABG trend: `pH, PaCO2, PaO2, HCO3`
- SpO2 trend and clinical fatigue trend

### DM core algorithm
1. Controlled oxygen + bronchodilator/steroid bundle when indicated.
2. Add NPPV when appropriate and no contraindications.
3. Recheck ABG and bedside distress at defined short intervals.
4. Intubate if worsening acidosis/fatigue/oxygenation despite NPPV.
5. After intubation, provide vent settings and require setting adjustments based on ABG/oxygenation.

### Escalation triggers
- Falling pH with rising PaCO2 despite therapy
- Worsening fatigue/mental status
- Persistent severe hypoxemia

## B) Adult Trauma
### Common patterns
- Tension pneumothorax, hemothorax, flail chest/contusion, ventilator-associated pneumothorax

### IG priorities
- Trauma context and abrupt deterioration signs
- Unilateral breath-sound changes, percussion findings, tracheal shift clues
- Hemodynamic instability signs
- CXR and targeted trauma diagnostics when patient is stable enough

### DM core algorithm
1. Stabilize oxygenation and perfusion immediately.
2. Perform emergency decompression/drainage when tension physiology or hemothorax is present.
3. If ventilated, reduce pressure/volume injury risk and reassess.
4. Continue complication surveillance and ICU-level trajectory when unstable.

### Escalation triggers
- Sudden hypotension/bradycardia with unilateral absent breath sounds
- Rising airway pressures + falling delivered VT on ventilator
- Worsening oxygenation despite initial intervention

## C) Adult Cardiovascular
### Common patterns
- CHF/cardiogenic pulmonary edema
- MI/ischemic crisis
- Shock/perfusion failure
- Cor pulmonale
- Pulmonary embolism

### IG priorities
- Chest pain, orthopnea, frothy secretions, sudden dyspnea patterns
- Perfusion signs (BP trend, skin signs, mentation)
- ABG, EKG/cardiac context, imaging/lab data tied to scenario
- PE clues in sudden postop dyspnea/tachycardia/hemoptysis

### DM core algorithm
1. Oxygenation and immediate cardiopulmonary stabilization.
2. Treat likely cause quickly (for example CHF fluid overload, ischemic pathway, PE workup).
3. Escalate support if perfusion or oxygenation worsens.
4. ICU/monitored disposition when instability risk remains high.

### Escalation triggers
- Persistent hypoxemia and respiratory distress
- Falling BP or shock signs
- Ongoing ischemic/hemodynamic compromise

## D) Adult Neurological or Neuromuscular
### Common patterns
- Myasthenia gravis crisis
- Guillain-Barre ventilatory compromise
- Stroke with respiratory failure risk
- Tetanus airway/ventilatory risk

### IG priorities
- Weakness pattern recognition (descending vs ascending)
- Bulbar signs: dysphagia, gag/cough weakness
- Respiratory muscle monitoring: `VT`, `VC`, `MIP`
- ABG trend and mental status trajectory

### DM core algorithm
1. Frequent respiratory muscle metric trending (`VT/VC/MIP`).
2. Oxygen and secretion-clearance support.
3. Disease-specific escalation (for example plasmapheresis pathways where indicated).
4. Intubate when ventilatory failure signs emerge.

### Escalation triggers
- Deteriorating `VT/VC/MIP`
- Worsening ABG ventilatory failure pattern
- Bulbar failure with aspiration/airway risk

## E) Adult Medical or Surgical
### Common patterns
- ARDS
- Infectious disease pathways
- Post-op and mixed med/surg respiratory failure
- Toxicology/overdose

### IG priorities
- Underlying trigger identification
- ABG quartet and oxygenation indices
- Imaging/lab clues (for example ARDS bilateral opacities with noncardiogenic pattern)
- Ventilator mechanics and complication signals

### DM core algorithm
1. Treat underlying cause and oxygenation/ventilation failure simultaneously.
2. For ARDS: lung-protective strategy, PEEP strategy, ABG-driven vent adjustments.
3. Avoid ineffective therapies when lesson guidance says they are not recommended.
4. ICU-level disposition for persistent instability.

### Escalation triggers
- Refractory hypoxemia
- Worsening respiratory acidosis or fatigue
- Progressive hemodynamic compromise

## F) Pediatric
### Common patterns
- Croup, epiglottitis, bronchiolitis, CF exacerbation, foreign body aspiration

### IG priorities
- Age-specific respiratory distress signs
- Airway danger signs (stridor, drooling, tripod, abrupt unilateral findings)
- Feeding/hydration and fatigue status
- Targeted diagnostics without delaying critical actions

### DM core algorithm
1. Stabilize airway/oxygenation first.
2. Match intervention to pattern (upper-airway vs lower-airway vs foreign body).
3. Reassess quickly for fatigue/apnea progression.
4. Admit/escalate when severity criteria are met.

### Escalation triggers
- Increasing work of breathing and exhaustion
- Persistent hypoxemia or apnea events
- Worsening airway obstruction signs

## G) Neonatal
### Common patterns
- Delivery room resuscitation
- Meconium aspiration
- Apnea of prematurity
- IRDS
- CHD cyanotic patterns
- BPD and neonatal surgical emergencies

### IG priorities
- Neonatal respiratory effort/tone/perfusion pattern
- Apnea/bradycardia/desaturation episodes
- Oxygenation response pattern and pre/post-ductal clues when relevant
- ABG and imaging trend as indicated by scenario stage

### DM core algorithm
1. Immediate neonatal stabilization priorities.
2. Escalate respiratory support per response.
3. Use condition-specific pathways (for example surfactant/resuscitation/surgical consult context).
4. NICU-level continuity and monitored handoff.

### Escalation triggers
- Recurrent apnea/bradycardia events
- Persistent hypoxemia despite support
- Progressive ventilatory failure pattern

## Global hard rules (all categories)
- Step 1 must include: age, sex, setting, presentation, and immediate objective.
- Step 1 must not name the diagnosis.
- If intubated, include vent settings and ABG quartet in follow-up steps.
- Vent adjustment choices must be explicitly tied to ABG/oxygenation response.
- Distractors must be plausible but wrong for the current moment.
