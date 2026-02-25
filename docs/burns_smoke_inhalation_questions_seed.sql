-- Exhale Academy Burns and Smoke Inhalation TMC question seed
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
    'Burns and Smoke Inhalation',
    'Smoke Inhalation Priority',
    'hard',
    'application',
    'high',
    'A fire victim has worsening respiratory distress after smoke exposure. What is the key life-threatening concern for an RT to prioritize?',
    'Immediate risk of progressive airway obstruction',
    'Delayed musculoskeletal pain only',
    'Stable airway with no urgent respiratory risk',
    'Primary concern is outpatient PFT scheduling',
    'A',
    'Smoke inhalation can rapidly progress to complete airway obstruction and requires urgent airway-focused management.',
    '{"B":"Pain may be present but is not the top immediate airway threat.","C":"Unsafe assumption in smoke inhalation injury.","D":"Not appropriate for an acute inhalation emergency."}'::jsonb,
    array['smoke exposure', 'worsening distress', 'airway obstruction risk'],
    'Underestimating airway risk in smoke inhalation injury.',
    'Prioritize airway-threatening inhalation injury before nonurgent testing.',
    'Core RT emergency priority in smoke inhalation.'
  ),
  (
    'Burns and Smoke Inhalation',
    'Smoke Exposure Context',
    'medium',
    'analysis',
    'medium',
    'Which exposure history should raise strong suspicion for clinically significant smoke inhalation injury?',
    'House-fire victim, firefighter in enclosed smoke, or heavy car-exhaust inhalation',
    'Minor isolated extremity bruise with no inhalation exposure',
    'Stable chronic cough without smoke exposure event',
    'Single brief outdoor pollen exposure only',
    'A',
    'Fire victims, firefighters, and car-exhaust inhalation exposures are high-risk contexts for inhalation injury and airway compromise.',
    '{"B":"No inhalation-risk context.","C":"Not an acute smoke-inhalation scenario.","D":"Not related to smoke inhalation injury."}'::jsonb,
    array['fire victim', 'firefighter', 'car exhaust inhalation'],
    'Missing high-risk exposure context during triage.',
    'Tie exposure mechanism to airway emergency risk.',
    'Identify high-risk smoke inhalation scenarios.'
  ),
  (
    'Burns and Smoke Inhalation',
    'Information Gathering',
    'medium',
    'analysis',
    'high',
    'Which information-gathering findings are most expected in smoke inhalation injury?',
    'Black sooty secretions and tachypnea',
    'Clear secretions with bradypnea',
    'No respiratory findings in early course',
    'Isolated unilateral hyperresonance only',
    'A',
    'Black/sooty secretions and fast breathing are classic high-yield inhalation-injury clues.',
    '{"B":"Opposite of expected pattern.","C":"Unsafe assumption; early signs are often present.","D":"More aligned with focal pleural air process."}'::jsonb,
    array['sooty secretions', 'tachypnea', 'smoke inhalation'],
    'Missing hallmark airway/secretions clues.',
    'Use secretion color and breathing pattern as early triage indicators.',
    'Core IG pattern for inhalation injury.'
  ),
  (
    'Burns and Smoke Inhalation',
    'Carbon Monoxide Poisoning',
    'hard',
    'application',
    'high',
    'On CSE, a smoke-exposed patient has a cherry red appearance. Which recommendation is most appropriate?',
    'Suspect CO poisoning, check COHb with co-oximeter, and recommend hyperbaric oxygen therapy if available',
    'Rule out CO poisoning if standard ABG analyzer is normal',
    'Delay all oxygen therapy until CT imaging is completed',
    'Treat as uncomplicated anxiety-related tachypnea only',
    'A',
    'Cherry red appearance is a major CO-poisoning clue; COHb requires co-oximetry, and hyperbaric oxygen should be recommended when available.',
    '{"B":"Standard ABG analyzer is not sufficient for COHb determination.","C":"Unsafe delay.","D":"Misses high-risk toxic inhalation injury."}'::jsonb,
    array['cherry red', 'CO poisoning', 'COHb', 'co-oximeter', 'hyperbaric oxygen'],
    'Relying on standard ABG analyzer alone for CO poisoning.',
    'CO poisoning workup and treatment should be triggered by exam clue and exposure context.',
    'CSE exam-hint integration for CO poisoning.'
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
