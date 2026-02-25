# Exhale CSE Case Workflow Contract

This contract defines how every CSE case should be written from Step 1 to Step 6.

## Goal
Create consistent, NBRC-style case flow where students discover the disease through data and make progressively better decisions.

## Standard 6-step structure

## Step 1 (IG): Scene + Immediate Priorities
### Required
- Bedside narrative with:
  - patient age + sex
  - setting/context
  - key initial symptoms/signs
  - no diagnosis label
- Prompt must use multi-select language.
- Options should focus on immediate safety, assessment, and essential first diagnostics.

### Forbidden
- Disease giveaway text (for example "`X disease suspected`").
- Management decisions that require unrevealed data.

## Step 2 (DM): First Decision Fork
### Required
- Single best immediate treatment pathway.
- 4-5 options:
  - 1 best (`+3` or `+2`)
  - 1 reasonable alternative (`+1`)
  - 1 weak/premature (`-1`)
  - 1-2 unsafe choices (`-2/-3`)

## Step 3 (IG): Reassessment and Objective Data
### Required
- New objective data based on prior decision quality.
- Must include critical metrics for that category (ABG, hemodynamics, VT/VC/MIP, etc. as relevant).
- Multi-select prompt focused on what to reassess now.

## Step 4 (DM): Escalation / De-escalation Decision
### Required
- Decision tied to objective worsening or improvement.
- Include explicit thresholds where relevant (for example worsening ABG trend, refractory hypoxemia).

## Step 5 (IG): Post-intervention Management
### Required
- If intubation occurred, include:
  - current vent settings
  - ABG quartet (`pH, PaCO2, PaO2, HCO3`)
  - options to adjust ventilator strategy based on results
- Multi-select options for complication checks and trend monitoring.

## Step 6 (DM): Disposition
### Required
- Disposition based on stability and monitoring needs.
- Include one clearly safest disposition and plausible unsafe alternatives.

## Rule and outcome contract
- Every step must have a `DEFAULT` rule/outcome.
- Rule priorities must reflect clinical safety sequence.
- Outcome text should describe physiologic direction, not reveal future answers.
- `vitals_override` progression must be clinically coherent.

## Writing style contract
- Use concise, realistic bedside language.
- Avoid repeating identical sentence templates across all cases.
- Keep option wording specific and actionable.
- Do not include teaching commentary inside options (put rationale in rationale fields only).

## Clinical coherence contract
- No option can depend on data not yet revealed.
- No abrupt therapy jump without a trigger (for example intubation without failure evidence).
- Reassessment steps must logically follow prior interventions.
- Do-not-recommend therapies from lesson guardrails must appear only as distractors with correct negative scoring.

## Ventilation-specific contract
- Any intubated-path case must include:
  - initial vent mode/settings,
  - ABG quartet after intervention,
  - at least one vent-adjustment DM/IG action tied to ABG and oxygenation.

## Minimal case definition of done
1. Step flow obeys this contract.
2. Option sets pass scoring pattern and plausibility rules.
3. Rules/outcomes cover all branches with a safe fallback.
4. Category algorithm alignment is confirmed.
5. Validator checklist passes with no blocker findings.
