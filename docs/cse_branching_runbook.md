# CSE Branching Engine Runbook

Use only these files for the active CSE implementation:

1. `docs/cse_branching_engine_migration.sql`
2. `docs/cse_case1_branching_insert.sql`
3. `docs/cse_case3_branching_insert.sql`

## Run order
1. Run migration:
   - `docs/cse_branching_engine_migration.sql`
2. Run seed:
   - `docs/cse_case3_branching_insert.sql`

## Do not run
- Any SQL under `docs/legacy_static_cse/`

Those files use the old static flow (`cse_choices` + static reveal text) and will conflict with branching-engine constraints.
