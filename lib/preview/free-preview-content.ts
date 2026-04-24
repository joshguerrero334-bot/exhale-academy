export type PreviewQuestion = {
  id: string;
  stem: string;
  options: Record<"A" | "B" | "C" | "D", string>;
  correct: "A" | "B" | "C" | "D";
  rationale: string;
  category: string;
};

export type PreviewFlashcard = {
  id: string;
  section: string;
  front: string;
  back: string;
};

export const previewQuestions: PreviewQuestion[] = [
  {
    id: "free-tmc-abg-ventilation",
    category: "ABG Interpretation",
    stem: "A patient receiving volume control ventilation has an ABG of pH 7.29, PaCO2 58 mmHg, PaO2 86 mmHg, and HCO3 26 mEq/L. Which ventilator change should be recommended?",
    options: { A: "Decrease the respiratory rate", B: "Increase minute ventilation", C: "Decrease PEEP", D: "Increase humidification" },
    correct: "B",
    rationale: "The low pH and high PaCO2 indicate respiratory acidosis. Increasing minute ventilation helps remove CO2.",
  },
  {
    id: "free-tmc-oxygen-device",
    category: "Oxygen Devices",
    stem: "A stable patient has mild hypoxemia and needs a low-flow oxygen device for short-term support. Which device is most appropriate?",
    options: { A: "Nasal cannula", B: "Non-rebreather mask", C: "CPAP", D: "Manual resuscitator" },
    correct: "A",
    rationale: "A nasal cannula is appropriate for stable patients with low oxygen needs, typically 1-6 L/min.",
  },
  {
    id: "free-tmc-copd-oxygen",
    category: "COPD",
    stem: "A patient with severe COPD is awake and speaking but has SpO2 87% on room air. Which oxygen strategy is most appropriate initially?",
    options: { A: "Low-flow oxygen titrated to target saturation", B: "FiO2 1.0 by non-rebreather for 8 hours", C: "No oxygen because COPD patients cannot receive oxygen", D: "Immediate intubation for all COPD hypoxemia" },
    correct: "A",
    rationale: "COPD patients still receive oxygen when hypoxemic, but it should be titrated carefully while monitoring ventilation and CO2 retention risk.",
  },
  {
    id: "free-tmc-pe-clue",
    category: "Disease Recognition",
    stem: "A post-op patient suddenly develops dyspnea, tachypnea, chest pain, and mostly clear breath sounds. Which condition should be suspected?",
    options: { A: "Pulmonary embolism", B: "Chronic bronchitis", C: "Pulmonary fibrosis", D: "Croup" },
    correct: "A",
    rationale: "Sudden dyspnea with chest pain, tachycardia, risk factors, and clear breath sounds is a classic pulmonary embolism clue.",
  },
  {
    id: "free-tmc-ards-settings",
    category: "ARDS",
    stem: "A patient with ARDS is placed on lung-protective ventilation. Which tidal volume strategy is most appropriate?",
    options: { A: "4-6 mL/kg predicted body weight", B: "10-12 mL/kg actual body weight", C: "15 mL/kg until oxygenation improves", D: "No PEEP with high tidal volumes" },
    correct: "A",
    rationale: "ARDS management emphasizes low tidal volume ventilation, usually 4-6 mL/kg predicted body weight, with plateau pressure control.",
  },
  {
    id: "free-tmc-high-pip-normal-plat",
    category: "Ventilator Troubleshooting",
    stem: "A ventilated patient has a high peak inspiratory pressure but a normal plateau pressure. What is the most likely problem?",
    options: { A: "Increased airway resistance", B: "Decreased lung compliance", C: "Pulmonary edema only", D: "Incorrect SpO2 probe placement" },
    correct: "A",
    rationale: "High PIP with normal plateau points to airway resistance, such as secretions, bronchospasm, biting, or kinked tubing.",
  },
  {
    id: "free-tmc-pft-obstruction",
    category: "PFTs",
    stem: "Which PFT pattern is most consistent with obstructive lung disease?",
    options: { A: "Low FEV1/FVC ratio", B: "Low TLC with normal ratio", C: "High DLCO with low RV", D: "Normal FEV1/FVC with low TLC only" },
    correct: "A",
    rationale: "A reduced FEV1/FVC ratio is the major pattern-recognition clue for obstruction.",
  },
  {
    id: "free-tmc-cpap-bipap",
    category: "Noninvasive Support",
    stem: "A COPD patient has pH 7.30 and PaCO2 62 mmHg with increased work of breathing but is alert and protecting the airway. Which support is most appropriate?",
    options: { A: "BiPAP", B: "CPAP only", C: "Nasal cannula only", D: "Incentive spirometry only" },
    correct: "A",
    rationale: "BiPAP supports ventilation through inspiratory pressure and is commonly used for hypercapnic COPD exacerbations when appropriate.",
  },
  {
    id: "free-tmc-normal-values",
    category: "Normal Values",
    stem: "Which value is within the normal PaCO2 range?",
    options: { A: "28 mmHg", B: "40 mmHg", C: "52 mmHg", D: "68 mmHg" },
    correct: "B",
    rationale: "Normal PaCO2 is about 35-45 mmHg. A PaCO2 of 40 mmHg is normal.",
  },
  {
    id: "free-tmc-racemic-epi",
    category: "Pharmacology",
    stem: "A child has stridor after an upper-airway illness. Which aerosolized medication is commonly used for temporary improvement?",
    options: { A: "Racemic epinephrine", B: "Dornase alfa", C: "Tiotropium", D: "Theophylline" },
    correct: "A",
    rationale: "Racemic epinephrine is commonly associated with croup, stridor, and upper-airway edema, but rebound symptoms must be monitored.",
  },
];

export const previewFlashcards: PreviewFlashcard[] = [
  { id: "free-card-paco2", section: "ABGs", front: "What does PaCO2 tell you?", back: "Ventilation. High PaCO2 means hypoventilation; low PaCO2 means hyperventilation." },
  { id: "free-card-ards", section: "Disease Patterns", front: "What buzzword points to ARDS?", back: "Refractory hypoxemia with bilateral infiltrates and decreased compliance." },
  { id: "free-card-copd", section: "Disease Patterns", front: "What PFT clue points to COPD?", back: "Low FEV1/FVC ratio with air trapping and increased RV/TLC." },
  { id: "free-card-pe", section: "Disease Patterns", front: "What clue should make you think PE?", back: "Sudden dyspnea, chest pain, tachycardia, and often clear lung sounds." },
  { id: "free-card-bipap", section: "Noninvasive Support", front: "Elevated CO2: CPAP or BiPAP?", back: "BiPAP, because IPAP helps support ventilation and tidal volume." },
  { id: "free-card-cpap", section: "Noninvasive Support", front: "OSA or mild CHF: CPAP or BiPAP?", back: "CPAP is commonly used when oxygenation/recruitment is the main issue and ventilation support is not needed." },
  { id: "free-card-pip", section: "Vent Troubleshooting", front: "High PIP with normal plateau means what?", back: "Increased airway resistance: secretions, bronchospasm, biting, kink, or obstruction." },
  { id: "free-card-plateau", section: "Vent Troubleshooting", front: "High PIP and high plateau means what?", back: "Decreased lung compliance, such as ARDS, pulmonary edema, atelectasis, or pneumothorax." },
  { id: "free-card-dlco", section: "PFTs", front: "Low DLCO points toward what?", back: "Gas exchange problems, especially emphysema or pulmonary fibrosis." },
  { id: "free-card-ics", section: "Pharmacology", front: "What is the key teaching for inhaled corticosteroids?", back: "Rinse the mouth after use to reduce oral thrush risk." },
];

export const previewCseCases = [
  {
    slug: "case-6-acute-severe-bronchospasm-fatigue",
    label: "Severe Bronchospasm",
    description: "A real branching CSE case focused on worsening bronchospasm, reassessment, and escalation timing.",
  },
  {
    slug: "trauma-critical-tension-pneumothorax",
    label: "Trauma Chest Emergency",
    description: "A real branching CSE case focused on trauma assessment, chest findings, and urgent intervention.",
  },
] as const;
