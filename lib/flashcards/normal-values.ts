export type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: string;
  frontImage?: string;
  frontImageAlt?: string;
};

export const normalValuesSections = [
  "ABGs",
  "Adult Assessment and Vitals",
  "CBC and Chemistry",
  "Coagulation and Cardiac Markers",
  "Hemodynamics",
  "Ventilator and Weaning Normals",
  "PFT and Oxygenation Clues",
  "Exam Traps and Memory Hooks",
] as const;

export const normalValuesCards: Flashcard[] = [
  { id: "ph-normal", section: "ABGs", front: "What is the normal pH range?", back: "7.35-7.45" },
  { id: "paco2-normal", section: "ABGs", front: "What is the normal PaCO2 range?", back: "35-45 mmHg" },
  { id: "pao2-normal", section: "ABGs", front: "What is the normal PaO2 range?", back: "80-100 mmHg" },
  { id: "hco3-normal", section: "ABGs", front: "What is the normal HCO3 range?", back: "22-26 mEq/L" },
  { id: "sao2-normal", section: "ABGs", front: "What is the normal SaO2 range?", back: "95-100%" },
  { id: "base-excess-normal", section: "ABGs", front: "What is the normal base excess range?", back: "-2 to +2" },
  { id: "paco2-high", section: "ABGs", front: "A PaCO2 of 52 mmHg is high, low, or normal?", back: "High" },
  { id: "ph-low", section: "ABGs", front: "A pH of 7.31 is high, low, or normal?", back: "Low" },
  { id: "pao2-normal-check", section: "ABGs", front: "A PaO2 of 88 mmHg is high, low, or normal?", back: "Normal" },
  { id: "ventilation-value", section: "ABGs", front: "What ABG value should you check first for ventilation?", back: "PaCO2" },

  { id: "heart-rate-normal", section: "Adult Assessment and Vitals", front: "What is the normal adult heart rate?", back: "60-100/min" },
  { id: "bp-normal", section: "Adult Assessment and Vitals", front: "What is a normal adult blood pressure?", back: "About 120/80 mmHg" },
  { id: "bp-range-normal", section: "Adult Assessment and Vitals", front: "What blood pressure range is still considered normal adult range?", back: "About 90/60 to 140/90 mmHg" },
  { id: "urine-output-normal", section: "Adult Assessment and Vitals", front: "What is the normal urine output target?", back: "About 40 mL/hour" },
  { id: "percussion-normal", section: "Adult Assessment and Vitals", front: "What percussion note is normal over the chest?", back: "Resonant" },
  { id: "breath-sounds-normal", section: "Adult Assessment and Vitals", front: "What breath sounds are considered normal?", back: "Vesicular" },
  { id: "heart-sounds-normal", section: "Adult Assessment and Vitals", front: "What heart sounds are considered normal?", back: "S1 and S2" },
  { id: "icp-normal", section: "Adult Assessment and Vitals", front: "What is the normal intracranial pressure range?", back: "5-10 mmHg" },
  { id: "cpp-normal", section: "Adult Assessment and Vitals", front: "What is the normal cerebral perfusion pressure range?", back: "70-90 mmHg" },
  { id: "co-nonsmoker", section: "Adult Assessment and Vitals", front: "What exhaled carbon monoxide level is expected in a nonsmoker?", back: "Less than 7" },

  { id: "rbc-normal", section: "CBC and Chemistry", front: "What is the normal RBC range?", back: "4-6 million/mm3" },
  { id: "hgb-normal", section: "CBC and Chemistry", front: "What is the normal hemoglobin range?", back: "12-16 g/dL" },
  { id: "hct-normal", section: "CBC and Chemistry", front: "What is the normal hematocrit range?", back: "40-50%" },
  { id: "wbc-normal", section: "CBC and Chemistry", front: "What is the normal white blood cell count?", back: "5,000-10,000/mm3" },
  { id: "na-normal", section: "CBC and Chemistry", front: "What is the normal sodium range?", back: "135-145 mEq/L" },
  { id: "k-normal", section: "CBC and Chemistry", front: "What is the normal potassium range?", back: "3.5-4.5 mEq/L" },
  { id: "cl-normal", section: "CBC and Chemistry", front: "What is the normal chloride range?", back: "80-100 mEq/L" },
  { id: "chem-hco3-normal", section: "CBC and Chemistry", front: "What is the normal bicarbonate range on chemistry values?", back: "22-26 mEq/L" },
  { id: "creatinine-normal", section: "CBC and Chemistry", front: "What is the normal creatinine range?", back: "0.7-1.3 mg/dL" },
  { id: "bun-normal", section: "CBC and Chemistry", front: "What is the normal BUN range?", back: "8-25 mg/dL" },

  { id: "platelets-normal", section: "Coagulation and Cardiac Markers", front: "What is the normal platelet count?", back: "150,000-400,000/mm3" },
  { id: "aptt-normal", section: "Coagulation and Cardiac Markers", front: "What is the normal aPTT range?", back: "24-32 seconds" },
  { id: "pt-normal", section: "Coagulation and Cardiac Markers", front: "What is the normal PT range?", back: "12-15 seconds" },
  { id: "clotting-time-normal", section: "Coagulation and Cardiac Markers", front: "What is the normal clotting time?", back: "Up to 6 minutes" },
  { id: "troponin-normal", section: "Coagulation and Cardiac Markers", front: "What troponin value is considered normal?", back: "Less than 0.1 ng/mL" },
  { id: "bnp-normal", section: "Coagulation and Cardiac Markers", front: "What BNP value is considered normal?", back: "Less than 100 pg/mL" },
  { id: "bnp-clue", section: "Coagulation and Cardiac Markers", front: "What lab clue should make you think heart failure when elevated?", back: "BNP" },

  { id: "map-normal", section: "Hemodynamics", front: "What is the normal MAP?", back: "About 93-94 mmHg" },
  { id: "cvp-normal", section: "Hemodynamics", front: "What is the normal CVP range?", back: "2-6 mmHg" },
  { id: "pap-normal", section: "Hemodynamics", front: "What is the normal PAP range?", back: "About 15-25 / 8-15 mmHg" },
  { id: "pcwp-normal", section: "Hemodynamics", front: "What is the normal PCWP range?", back: "4-12 mmHg" },
  { id: "co-normal", section: "Hemodynamics", front: "What is the normal cardiac output range?", back: "4-8 L/min" },
  { id: "ci-normal", section: "Hemodynamics", front: "What is the normal cardiac index range?", back: "2.5-4 L/min/m2" },
  { id: "svr-normal", section: "Hemodynamics", front: "What is the normal SVR range?", back: "800-1600 dynes/sec/cm5" },

  { id: "vt-initial", section: "Ventilator and Weaning Normals", front: "What is a common normal adult initial tidal volume setting?", back: "6-8 mL/kg IBW" },
  { id: "rr-initial", section: "Ventilator and Weaning Normals", front: "What is a common normal adult initial respiratory rate setting?", back: "12-20/min" },
  { id: "peep-initial", section: "Ventilator and Weaning Normals", front: "What is a common initial PEEP setting for adults?", back: "5 cmH2O" },
  { id: "fio2-initial", section: "Ventilator and Weaning Normals", front: "What is a common starting FiO2 range for a stable adult vent setup?", back: "40-60%" },
  { id: "rsbi-normal", section: "Ventilator and Weaning Normals", front: "What RSBI is usually considered favorable for weaning?", back: "Less than 105" },
  { id: "mip-normal", section: "Ventilator and Weaning Normals", front: "What NIF or MIP range suggests strong inspiratory muscle strength?", back: "About -80 to -100 cmH2O" },

  { id: "fev1fvc-normal", section: "PFT and Oxygenation Clues", front: "What FEV1/FVC ratio is generally considered normal?", back: "About 70% or higher" },
  { id: "pf-ratio-normal", section: "PFT and Oxygenation Clues", front: "What P/F ratio is considered normal?", back: "Greater than 300" },
  { id: "cstat-normal", section: "PFT and Oxygenation Clues", front: "What static compliance range is considered normal?", back: "60-100 mL/cmH2O" },
  { id: "cdyn-normal", section: "PFT and Oxygenation Clues", front: "What dynamic compliance range is considered normal?", back: "30-40 mL/cmH2O" },
  { id: "vdvt-normal", section: "PFT and Oxygenation Clues", front: "What VD/VT ratio is considered normal?", back: "0.2-0.4" },
  { id: "aa-gradient-normal", section: "PFT and Oxygenation Clues", front: "What A-a gradient on room air is generally considered normal?", back: "Less than 25 mmHg" },

  { id: "pao2-trap", section: "Exam Traps and Memory Hooks", front: "What is a common normal-values trap with PaO2?", back: "Students often panic when it is below 100, but 80-100 mmHg is still normal." },
  { id: "bp-trap", section: "Exam Traps and Memory Hooks", front: "What is a common normal-values trap with blood pressure?", back: "120/80 is the classic normal, but a wider adult range can still be normal." },
  { id: "hco3-trap", section: "Exam Traps and Memory Hooks", front: "What is a common normal-values trap with HCO3?", back: "Normal is 22-26. Do not mix it up with chemistry values outside the ABG context." },
  { id: "abg-memory", section: "Exam Traps and Memory Hooks", front: "What memory trick helps with ABGs?", back: "35-45-80-100-22-26: PaCO2, PaO2, HCO3." },
  { id: "vent-memory", section: "Exam Traps and Memory Hooks", front: "What memory trick helps with vent basics?", back: "6-8, 12-20, 5: tidal volume, rate, PEEP." },
  { id: "pft-memory", section: "Exam Traps and Memory Hooks", front: "What memory trick helps with PFT interpretation?", back: "Ratio first, then volume." },
];
