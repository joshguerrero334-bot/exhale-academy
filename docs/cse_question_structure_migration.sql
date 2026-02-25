-- Exhale Academy CSE question structure migration
-- Adds structured Scenario fields for each CSE step/question.

begin;

alter table public.cse_steps
  add column if not exists scenario_setting text,
  add column if not exists scenario_patient_summary text,
  add column if not exists scenario_history text;

comment on column public.cse_steps.scenario_setting is
  'Scenario section: physical setting/context (unit, location, time, care environment).';
comment on column public.cse_steps.scenario_patient_summary is
  'Scenario section: patient basics (age, sex, appearance, presenting condition).';
comment on column public.cse_steps.scenario_history is
  'Scenario section: relevant history and brief active illness/event summary.';

commit;
