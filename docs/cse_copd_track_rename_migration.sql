-- Exhale Academy CSE COPD track normalization
-- Renames COPD category from conservative -> non_critical across existing data.

begin;

-- Existing environments may still have the old check constraint that excludes non_critical.
alter table public.cse_disease_playbooks
  drop constraint if exists cse_disease_playbooks_track_check;

alter table public.cse_disease_playbooks
  add constraint cse_disease_playbooks_track_check
  check (track in ('conservative', 'non_critical', 'critical'));

-- Cases: normalize COPD track, source, and naming artifacts.
update public.cse_cases
set
  disease_track = 'non_critical',
  source = case
    when source = 'copd-conservative' then 'copd-non-critical'
    else source
  end,
  slug = case
    when slug like '%copd-conservative%' then replace(slug, 'copd-conservative', 'copd-non-critical')
    when slug = 'asthma-conservative-triggered-exacerbation' then 'copd-non-critical-asthma-triggered-exacerbation'
    else slug
  end,
  title = case
    when title like 'COPD Conservative (%' then replace(title, 'COPD Conservative (', 'COPD Non-Critical (')
    when title = 'Asthma Conservative (Triggered Exacerbation)' then 'COPD Non-Critical (Asthma Triggered Exacerbation)'
    else title
  end
where disease_slug = 'copd'
  and (
    disease_track = 'conservative'
    or source = 'copd-conservative'
    or slug like '%copd-conservative%'
    or slug = 'asthma-conservative-triggered-exacerbation'
    or title like 'COPD Conservative (%'
    or title = 'Asthma Conservative (Triggered Exacerbation)'
  );

-- Playbooks: avoid duplicate key conflicts if both rows already exist.
delete from public.cse_disease_playbooks p
where p.disease_slug = 'copd'
  and p.track = 'conservative'
  and exists (
    select 1
    from public.cse_disease_playbooks n
    where n.disease_slug = 'copd'
      and n.track = 'non_critical'
  );

update public.cse_disease_playbooks
set track = 'non_critical'
where disease_slug = 'copd'
  and track = 'conservative';

commit;
