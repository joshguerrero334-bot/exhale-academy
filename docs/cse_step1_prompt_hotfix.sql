-- Exhale Academy CSE Step-1 prompt hotfix
-- Purpose: overwrite stale DB prompts that still expose diagnosis in Step 1.

begin;

-- Pediatric bronchiolitis (step 1)
update public.cse_steps s
set prompt = 'You are called to bedside for a 7-month-old male with URI progression, feeding intolerance, tachypnea, and retractions. Focused respiratory assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
from public.cse_cases c
where s.case_id = c.id
  and c.slug = 'pediatric-critical-bronchiolitis-rsv-edema-apnea-risk'
  and s.step_order = 1;

-- Neonatal apnea of prematurity (step 1)
update public.cse_steps s
set prompt = 'You are called to bedside for a 31-week male preterm neonate in the NICU with recurrent apnea episodes associated with bradycardia and desaturation. Focused assessment is pending. What are your next steps? SELECT AS MANY AS INDICATED (MAX 8).'
from public.cse_cases c
where s.case_id = c.id
  and c.slug = 'neonatal-critical-apnea-of-prematurity-bradycardia-episodes'
  and s.step_order = 1;

-- Generic cleanup for stale legacy phrasing that may still exist in DB.
update public.cse_steps
set prompt = regexp_replace(prompt, '\s*Opening monitor data is available now\.\s*', ' ', 'gi')
where prompt ~* 'Opening monitor data is available now\.';

update public.cse_steps
set prompt = regexp_replace(prompt, '\s+', ' ', 'g')
where prompt ~ '\s{2,}';

commit;

-- Verification
select c.slug, s.step_order, s.prompt
from public.cse_steps s
join public.cse_cases c on c.id = s.case_id
where (c.slug in (
  'pediatric-critical-bronchiolitis-rsv-edema-apnea-risk',
  'neonatal-critical-apnea-of-prematurity-bradycardia-episodes'
) and s.step_order = 1)
or s.prompt ilike '%Opening monitor data is available now%';
