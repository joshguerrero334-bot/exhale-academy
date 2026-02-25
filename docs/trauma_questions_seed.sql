-- Exhale Academy Trauma TMC question seed
-- Idempotent insert into public.questions using category + stem uniqueness check.

begin;

with seed_questions (
  category,
  sub_concept,
  difficulty,
  cognitive_level,
  exam_priority,
  stem,
  option_a,
  option_b,
  option_c,
  option_d,
  correct_answer,
  rationale_correct,
  rationale_why_others_wrong,
  keywords_to_notice,
  common_trap,
  exam_logic,
  qa_summary
) as (
  values
  (
    'Trauma',
    'Flail Chest',
    'hard',
    'application',
    'high',
    'A chest-trauma patient has paradoxical chest movement and severe pain. Which finding best supports flail chest?',
    'Fracture of at least 3 adjacent ribs causing unstable chest wall segment',
    'Isolated clavicle fracture with normal chest wall mechanics',
    'Single rib fracture with no respiratory distress',
    'Pulmonary embolism with pleuritic pain only',
    'A',
    'Flail chest is classically associated with fracture of >= 3 adjacent ribs causing paradoxical movement and instability.',
    '{"B":"Not a flail chest pattern.","C":"Too limited for flail segment.","D":"Different pathology."}'::jsonb,
    array['paradoxical movement', 'adjacent rib fractures', 'unstable thoracic cage'],
    'Confusing any rib fracture with flail chest.',
    'Link paradoxical movement to multi-rib instability, not isolated injury.',
    'Flail chest recognition in trauma scenario.'
  ),
  (
    'Trauma',
    'Tension Pneumothorax',
    'hard',
    'application',
    'high',
    'A trauma patient has severe distress, unilateral absent breath sounds, tracheal shift away from the affected side, bradycardia, and hypotension. What is the best immediate action?',
    'Obtain chest x-ray before intervention',
    'Immediate needle decompression/thoracostomy and 100% oxygen',
    'Start antibiotics and observe response',
    'Schedule PFT after stabilization',
    'B',
    'Unstable tension pneumothorax is a treat-now emergency; decompression cannot wait for routine imaging.',
    '{"A":"Unsafe delay.","C":"Not primary lifesaving action.","D":"Not an acute emergency intervention."}'::jsonb,
    array['tracheal shift away', 'absent unilateral breath sounds', 'hemodynamic instability'],
    'Waiting for chest x-ray in unstable tension pneumothorax.',
    'When clear tension physiology is present, treat first then image.',
    'Emergency treatment sequence for unstable tension pneumothorax.'
  ),
  (
    'Trauma',
    'Pneumothorax Diagnostics',
    'medium',
    'analysis',
    'high',
    'Which percussion and imaging pattern most strongly supports pneumothorax on the affected side?',
    'Dull percussion with increased radiodensity',
    'Hyperresonant percussion with hyperlucency and absent vascular markings',
    'Normal percussion with bilateral infiltrates',
    'Crackles with cardiomegaly only',
    'B',
    'Pneumothorax commonly shows hyperresonance and hyperlucency with reduced vascular markings on the affected side.',
    '{"A":"More consistent with pleural fluid/blood.","C":"Not specific for pneumothorax.","D":"Suggests alternate process."}'::jsonb,
    array['hyperresonance', 'hyperlucency', 'absent vascular markings'],
    'Mixing hemothorax and pneumothorax percussion findings.',
    'Air in pleural space -> hyperresonance + hyperlucency.',
    'Core diagnostic pattern for pneumothorax.'
  ),
  (
    'Trauma',
    'Hemothorax Diagnostics',
    'medium',
    'analysis',
    'high',
    'Which finding set is most consistent with hemothorax in chest trauma?',
    'Hyperresonant percussion and hyperlucent hemithorax',
    'Dull/flat percussion, diminished breath sounds, increased radiodensity on chest x-ray',
    'Widespread expiratory wheeze only',
    'Normal exam with isolated tachycardia',
    'B',
    'Hemothorax (blood in pleural space) typically gives dullness, reduced unilateral breath sounds, and radiodense opacification.',
    '{"A":"Classic pneumothorax pattern.","C":"Nonspecific/insufficient.","D":"Insufficient evidence for hemothorax."}'::jsonb,
    array['dull percussion', 'increased radiodensity', 'diminished unilateral breath sounds'],
    'Choosing air-pattern findings for blood accumulation.',
    'Fluid/blood in pleural space produces dullness and radiodensity.',
    'Differentiate hemothorax from pneumothorax.'
  ),
  (
    'Trauma',
    'Hemothorax Treatment',
    'hard',
    'application',
    'high',
    'In traumatic hemothorax with hypoxemia, which treatment plan is most appropriate?',
    'Give 100% oxygen and perform thoracentesis or chest-tube drainage, then reassess',
    'Give analgesics only and discharge if pain improves',
    'Start hyperinflation therapy before drainage',
    'Delay intervention until PFT confirms restrictive pattern',
    'A',
    'Hemothorax management prioritizes oxygenation plus pleural blood drainage; supportive therapies follow drainage.',
    '{"B":"Insufficient and unsafe.","C":"Wrong sequence.","D":"Unsafe delay."}'::jsonb,
    array['100% oxygen', 'drain pleural blood', 'post-drainage reassessment'],
    'Delaying drainage or using supportive therapy first.',
    'Drainage-first strategy is core in clinically significant hemothorax.',
    'Correct immediate treatment sequence for hemothorax.'
  ),
  (
    'Trauma',
    'Ventilator Complication',
    'hard',
    'application',
    'high',
    'A ventilated trauma patient suddenly develops high airway pressures and reduced tidal volume. What complication should be suspected first?',
    'Acute pulmonary edema',
    'Pneumothorax',
    'Simple atelectasis only',
    'Mild metabolic acidosis',
    'B',
    'A sudden rise in airway pressure with falling tidal volume in this context is a classic warning for pneumothorax on the ventilator.',
    '{"A":"Possible but less classic for abrupt pressure/volume alarm pattern in trauma.","C":"Can occur but this alarm pattern strongly suggests pneumothorax.","D":"Does not explain abrupt ventilator mechanics change."}'::jsonb,
    array['ventilator alarms', 'increased airway pressure', 'decreased tidal volume'],
    'Ignoring ventilator mechanics change as a pneumothorax clue.',
    'Ventilator pressure-volume change can be an early red flag for pneumothorax.',
    'Recognize ventilator-related pneumothorax signs.'
  )
)
insert into public.questions (
  category,
  sub_concept,
  difficulty,
  cognitive_level,
  exam_priority,
  stem,
  option_a,
  option_b,
  option_c,
  option_d,
  correct_answer,
  rationale_correct,
  rationale_why_others_wrong,
  keywords_to_notice,
  common_trap,
  exam_logic,
  qa_summary
)
select
  sq.category,
  sq.sub_concept,
  sq.difficulty,
  sq.cognitive_level,
  sq.exam_priority,
  sq.stem,
  sq.option_a,
  sq.option_b,
  sq.option_c,
  sq.option_d,
  sq.correct_answer,
  sq.rationale_correct,
  sq.rationale_why_others_wrong,
  sq.keywords_to_notice,
  sq.common_trap,
  sq.exam_logic,
  sq.qa_summary
from seed_questions sq
where not exists (
  select 1
  from public.questions q
  where q.category = sq.category
    and q.stem = sq.stem
);

commit;
