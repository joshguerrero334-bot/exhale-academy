-- Exhale Academy CSE disease knowledge base
-- Stores authoring guidance by disease and acuity track for reusable case generation.

begin;

create extension if not exists pgcrypto;

create table if not exists public.cse_disease_playbooks (
  id uuid primary key default gen_random_uuid(),
  disease_slug text not null,
  disease_name text not null,
  track text not null check (track in ('conservative', 'non_critical', 'critical')),
  summary text not null,
  emergency_cues text[] not null default '{}',
  scenario_setting_templates text[] not null default '{}',
  scenario_patient_summary_templates text[] not null default '{}',
  scenario_history_templates text[] not null default '{}',
  ig_visual_priorities text[] not null default '{}',
  ig_bedside_priorities text[] not null default '{}',
  ig_basic_lab_priorities text[] not null default '{}',
  ig_special_test_priorities text[] not null default '{}',
  ig_avoid_or_penalize text[] not null default '{}',
  dm_best_actions text[] not null default '{}',
  dm_reasonable_alternatives text[] not null default '{}',
  dm_unsafe_actions text[] not null default '{}',
  abg_patterns jsonb not null default '[]'::jsonb,
  oxygenation_patterns jsonb not null default '[]'::jsonb,
  ventilator_patterns jsonb not null default '[]'::jsonb,
  disposition_guidance text[] not null default '{}',
  scoring_guidance jsonb not null default '{}'::jsonb,
  author_notes text,
  source_name text not null default 'Exhale Faculty',
  source_revision text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (disease_slug, track)
);

-- Ensure existing databases also allow COPD non_critical track.
alter table public.cse_disease_playbooks
  drop constraint if exists cse_disease_playbooks_track_check;

alter table public.cse_disease_playbooks
  add constraint cse_disease_playbooks_track_check
  check (track in ('conservative', 'non_critical', 'critical'));

create or replace function public.touch_cse_disease_playbooks_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_touch_cse_disease_playbooks_updated_at on public.cse_disease_playbooks;
create trigger trg_touch_cse_disease_playbooks_updated_at
before update on public.cse_disease_playbooks
for each row
execute function public.touch_cse_disease_playbooks_updated_at();

create index if not exists idx_cse_disease_playbooks_slug_track
  on public.cse_disease_playbooks (disease_slug, track);

alter table public.cse_disease_playbooks enable row level security;

drop policy if exists cse_disease_playbooks_authenticated_read on public.cse_disease_playbooks;
create policy cse_disease_playbooks_authenticated_read
  on public.cse_disease_playbooks
  for select to authenticated
  using (true);

commit;
