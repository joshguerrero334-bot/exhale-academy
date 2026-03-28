export type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: "Disease Recognition" | "Diagnostic Buzzwords" | "Ventilator Management" | "Quick Tips";
};

export const tmcCseBuzzwordCards: Flashcard[] = [
  { id: "refractory-hypoxemia", front: "Refractory hypoxemia", back: "ARDS", section: "Disease Recognition" },
  { id: "pink-frothy-secretions", front: "Pink frothy secretions", back: "Pulmonary edema / CHF", section: "Disease Recognition" },
  { id: "clubbing-fingers", front: "Clubbing of fingers", back: "Chronic hypoxia (COPD, CF)", section: "Disease Recognition" },
  { id: "barrel-chest", front: "Barrel chest", back: "Emphysema", section: "Disease Recognition" },
  { id: "steeple-sign", front: "Steeple sign on neck X-ray", back: "Croup", section: "Disease Recognition" },
  { id: "thumb-sign", front: "Thumb sign on neck X-ray", back: "Epiglottitis", section: "Disease Recognition" },
  { id: "hyperresonant-percussion", front: "Hyperresonant percussion", back: "Pneumothorax or air trapping", section: "Disease Recognition" },
  { id: "dull-percussion", front: "Dull percussion", back: "Pleural effusion or consolidation", section: "Disease Recognition" },
  { id: "hemoptysis", front: "Blood in sputum (hemoptysis)", back: "TB, cancer, PE", section: "Disease Recognition" },
  { id: "night-sweats-weight-loss", front: "Night sweats + weight loss", back: "Tuberculosis", section: "Disease Recognition" },
  { id: "tracheal-away", front: "Tracheal deviation away from affected side", back: "Tension pneumothorax", section: "Disease Recognition" },
  { id: "tracheal-toward", front: "Tracheal deviation toward affected side", back: "Atelectasis or lung removal", section: "Disease Recognition" },

  { id: "flattened-diaphragm", front: "Flattened diaphragm", back: "COPD", section: "Diagnostic Buzzwords" },
  { id: "ground-glass-opacity", front: "Ground-glass opacity (CXR/CT)", back: "ARDS or fibrosis", section: "Diagnostic Buzzwords" },
  { id: "batwing-butterfly", front: "Batwing / butterfly pattern", back: "Pulmonary edema", section: "Diagnostic Buzzwords" },
  { id: "honeycomb-lung", front: "Honeycomb lung", back: "Interstitial lung disease", section: "Diagnostic Buzzwords" },
  { id: "vq-mismatch", front: "V/Q mismatch", back: "COPD, pneumonia, PE", section: "Diagnostic Buzzwords" },
  { id: "capno-loss", front: "Capnography: sudden loss of waveform", back: "Tube dislodgement or disconnection", section: "Diagnostic Buzzwords" },
  { id: "capno-baseline-rise", front: "Capnography: gradual rise in baseline", back: "Rebreathing (check filters)", section: "Diagnostic Buzzwords" },
  { id: "scooped-loop", front: "Scooped flow-volume loop", back: "Obstructive disease", section: "Diagnostic Buzzwords" },
  { id: "peaked-loop", front: "Peaked / narrow loop", back: "Restrictive disease", section: "Diagnostic Buzzwords" },

  { id: "auto-peep", front: "Auto-PEEP", back: "Air trapping; fix with more expiratory time or lower RR", section: "Ventilator Management" },
  { id: "vent-asynchrony", front: "Patient-ventilator asynchrony", back: "Flow too low; fix with more flow or sedation", section: "Ventilator Management" },
  { id: "high-pip-normal-plateau", front: "High PIP with normal plateau", back: "Airway resistance issue (secretions, bronchospasm)", section: "Ventilator Management" },
  { id: "high-pip-high-plateau", front: "High PIP and high plateau", back: "Compliance issue (ARDS, pneumonia, tension pneumothorax)", section: "Ventilator Management" },
  { id: "suction-catheter-wont-pass", front: "ETT suction catheter will not pass", back: "Mucus plug or kinked tube", section: "Ventilator Management" },
  { id: "post-intubation-desat", front: "Sudden drop in SpO2 after intubation", back: "Check tube placement or breath sounds", section: "Ventilator Management" },
  { id: "biting-tube", front: "Biting the tube", back: "High PIP; fix with sedation or bite block", section: "Ventilator Management" },
  { id: "leaky-cuff", front: "Leaky cuff", back: "Low PIP and hissing sound; check pilot balloon", section: "Ventilator Management" },

  { id: "quick-tip-trust-keyword", front: "Trust the keyword.", back: "If a question says 'refractory hypoxemia,' think ARDS and avoid second-guessing.", section: "Quick Tips" },
  { id: "quick-tip-safest-simplest-fastest", front: "Think safest, simplest, fastest.", back: "NBRC usually wants the least invasive effective option first.", section: "Quick Tips" },
  { id: "quick-tip-trends", front: "Look for trends, not isolated numbers.", back: "Low pH with high PaCO2 points to respiratory acidosis. Connect the dots.", section: "Quick Tips" },
  { id: "quick-tip-sudden-change", front: "Sudden changes = emergency.", back: "Think suction, dislodgement, tension pneumothorax, or obstruction.", section: "Quick Tips" },
  { id: "quick-tip-dont-chase-numbers", front: "Do not chase numbers.", back: "If the patient is stable, avoid over-treating chronic abnormalities like chronic CO2 retention.", section: "Quick Tips" },
  { id: "quick-tip-pip", front: "High PIP alone? High PIP + high plateau?", back: "High PIP alone suggests airway issue. High PIP plus high plateau suggests compliance issue.", section: "Quick Tips" },
  { id: "quick-tip-normal-ranges", front: "Know normal ranges cold.", back: "The exam expects you to recognize abnormal values without being told.", section: "Quick Tips" },
  { id: "quick-tip-check-fio2", front: "Always check the FiO2.", back: "If PaO2 is low and FiO2 is still under 60%, it is usually safe to increase FiO2 first.", section: "Quick Tips" },
  { id: "quick-tip-capnography", front: "Capnography is key.", back: "Use it early to confirm ETT placement and detect changes fast.", section: "Quick Tips" },
  { id: "quick-tip-vq", front: "V/Q mismatch means oxygen will not fix it alone.", back: "Always think about treating the underlying cause, not just the oxygen number.", section: "Quick Tips" },
  { id: "quick-tip-obstructive", front: "For asthma and COPD, what should you prioritize?", back: "Bronchodilation and longer expiratory time.", section: "Quick Tips" },
];

export const buzzwordSections = [
  "Disease Recognition",
  "Diagnostic Buzzwords",
  "Ventilator Management",
  "Quick Tips",
] as const;

