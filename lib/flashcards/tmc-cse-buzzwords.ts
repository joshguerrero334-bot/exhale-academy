export type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: "Disease Recognition" | "Diagnostic Buzzwords" | "Ventilator Management";
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

  { id: "auto-peep", front: "What is Auto-PEEP and how do you fix it?", back: "Air trapping; fix with more expiratory time or lower RR", section: "Ventilator Management" },
  { id: "vent-asynchrony", front: "What is happening during patient-ventilator asynchrony and how do you fix it?", back: "Flow too low; fix with more flow or sedation", section: "Ventilator Management" },
  { id: "high-pip-normal-plateau", front: "What is causing high PIP with normal plateau?", back: "Airway resistance issue (secretions, bronchospasm)", section: "Ventilator Management" },
  { id: "high-pip-high-plateau", front: "What is causing high PIP and high plateau?", back: "Compliance issue (ARDS, pneumonia, tension pneumothorax)", section: "Ventilator Management" },
  { id: "suction-catheter-wont-pass", front: "Why wouldn't an ETT suction catheter pass?", back: "Mucus plug or kinked tube", section: "Ventilator Management" },
  { id: "post-intubation-desat", front: "What should you check if you get a sudden drop in SpO2 after intubation?", back: "Check tube placement or breath sounds", section: "Ventilator Management" },
  { id: "biting-tube", front: "What will you see on the ventilator if the patient is biting the tube, and how would you fix this?", back: "High PIP; fix with sedation or bite block", section: "Ventilator Management" },
  { id: "leaky-cuff", front: "What will you see and hear on the ventilator if you have a leaky cuff and how would you troubleshoot this?", back: "Low PIP and hissing sound; check pilot balloon", section: "Ventilator Management" },
];

export const buzzwordSections = [
  "Disease Recognition",
  "Diagnostic Buzzwords",
  "Ventilator Management",
] as const;
