-- Exhale Academy CSE case taxonomy fields
-- Adds disease-based grouping so learners can select by condition + track.

begin;

alter table public.cse_cases
  add column if not exists disease_slug text;

alter table public.cse_cases
  add column if not exists disease_track text;

create index if not exists idx_cse_cases_disease_track
  on public.cse_cases (disease_slug, disease_track);

commit;
