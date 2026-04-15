export type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: string;
  frontImage?: string;
  frontImageAlt?: string;
};

export const rtPharmacologySections = [
  "Bronchodilators",
  "Anti-Inflammatory Meds",
  "Mucolytics and Secretion Management",
  "Antitussives and Oral Meds",
  "Emergency and Airway Meds",
  "Comparison, Traps, and Memory",
] as const;

export const rtPharmacologyCards: Flashcard[] = [
  { id: "alb-class", section: "Bronchodilators", front: "What class is albuterol?", back: "SABA. It is a short-acting beta-2 agonist used for quick bronchodilation." },
  { id: "alb-use", section: "Bronchodilators", front: "What is albuterol commonly used for?", back: "Quick relief of bronchospasm in asthma and COPD." },
  { id: "alb-side-effect", section: "Bronchodilators", front: "What is a key side effect clue for albuterol?", back: "It can cause tachycardia, tremors, and nervousness." },
  { id: "leva-class", section: "Bronchodilators", front: "What class is levalbuterol?", back: "SABA. It works like albuterol but is often described as having fewer side effects." },
  { id: "leva-diff", section: "Bronchodilators", front: "How is levalbuterol different from albuterol on exams?", back: "It is often presented as the more selective option with fewer side effects." },
  { id: "salm-class", section: "Bronchodilators", front: "What class is salmeterol?", back: "LABA. It is a long-acting beta-2 agonist used for maintenance, not rescue." },
  { id: "salm-clue", section: "Bronchodilators", front: "What is the board-style clue for salmeterol?", back: "Long-acting bronchodilator for maintenance therapy; not for acute rescue." },
  { id: "form-class", section: "Bronchodilators", front: "What class is formoterol?", back: "LABA. It is long-acting but has a faster onset than salmeterol." },
  { id: "form-compare", section: "Bronchodilators", front: "What is the useful comparison between formoterol and salmeterol?", back: "Both are LABAs, but formoterol has a faster onset." },
  { id: "ipra-class", section: "Bronchodilators", front: "What class is ipratropium?", back: "SAMA. It is a short-acting anticholinergic bronchodilator." },
  { id: "ipra-use", section: "Bronchodilators", front: "When is ipratropium commonly used?", back: "COPD, asthma, and bronchospasm, often combined with albuterol." },
  { id: "ipra-combo", section: "Bronchodilators", front: "What combo clue should make you think ipratropium?", back: "DuoNeb. That usually means ipratropium plus albuterol." },
  { id: "tio-class", section: "Bronchodilators", front: "What class is tiotropium?", back: "LAMA. It is a long-acting anticholinergic used for COPD maintenance." },
  { id: "tio-clue", section: "Bronchodilators", front: "What is the exam clue for tiotropium?", back: "Once-daily COPD maintenance; not a rescue drug." },
  { id: "saba-laba", section: "Bronchodilators", front: "What does SABA vs LABA usually test?", back: "Rescue vs maintenance. SABA is fast rescue; LABA is scheduled long-term control." },

  { id: "flut-class", section: "Anti-Inflammatory Meds", front: "What class is fluticasone?", back: "ICS. It is an inhaled corticosteroid used for asthma or COPD maintenance." },
  { id: "ics-teaching", section: "Anti-Inflammatory Meds", front: "What is the most important teaching point for inhaled corticosteroids?", back: "Rinse the mouth after use to reduce the risk of oral thrush." },
  { id: "bud-class", section: "Anti-Inflammatory Meds", front: "What class is budesonide?", back: "ICS. It is used for asthma maintenance and can also be given in nebulized form." },
  { id: "bud-high-yield", section: "Anti-Inflammatory Meds", front: "Why is budesonide high-yield for RT students?", back: "It is an ICS that can be nebulized, which makes it especially relevant in pediatrics." },
  { id: "beclo-class", section: "Anti-Inflammatory Meds", front: "What class is beclomethasone?", back: "ICS. It is a controller medication, not a rescue bronchodilator." },
  { id: "ics-trap", section: "Anti-Inflammatory Meds", front: "What is the exam trap with ICS medications?", back: "Students sometimes confuse them with rescue meds. ICS drugs are for control, not immediate relief." },
  { id: "advair-components", section: "Anti-Inflammatory Meds", front: "What is Advair made of?", back: "Fluticasone plus salmeterol. ICS + LABA." },
  { id: "symbicort-components", section: "Anti-Inflammatory Meds", front: "What is Symbicort made of?", back: "Budesonide plus formoterol. ICS + LABA." },
  { id: "breo-components", section: "Anti-Inflammatory Meds", front: "What is Breo Ellipta made of?", back: "Fluticasone plus vilanterol. ICS + LABA." },
  { id: "combo-idea", section: "Anti-Inflammatory Meds", front: "What is the key idea behind combination inhalers?", back: "They combine anti-inflammatory control with long-acting bronchodilation for maintenance." },
  { id: "mont-class", section: "Anti-Inflammatory Meds", front: "What class is montelukast?", back: "Leukotriene receptor antagonist." },
  { id: "mont-use", section: "Anti-Inflammatory Meds", front: "When is montelukast commonly used?", back: "Asthma and allergic rhinitis, usually as an oral maintenance medication." },
  { id: "mont-warning", section: "Anti-Inflammatory Meds", front: "What is the key board warning for montelukast?", back: "It is not a rescue drug, and mood or behavior changes may be mentioned." },

  { id: "acetyl-class", section: "Mucolytics and Secretion Management", front: "What class is acetylcysteine?", back: "Mucolytic. It breaks down mucus but can trigger bronchospasm." },
  { id: "acetyl-clue", section: "Mucolytics and Secretion Management", front: "What is the exam clue for acetylcysteine?", back: "Thick secretions, mucolytic effect, and possible bronchospasm." },
  { id: "dorn-class", section: "Mucolytics and Secretion Management", front: "What class is dornase alfa?", back: "Mucolytic. It breaks down DNA in mucus and is strongly associated with cystic fibrosis." },
  { id: "dorn-disease", section: "Mucolytics and Secretion Management", front: "What disease clue should make you think dornase alfa?", back: "Cystic fibrosis with very thick secretions." },
  { id: "guai-use", section: "Mucolytics and Secretion Management", front: "What is guaifenesin used for?", back: "Expectorant support for cough and mucus clearance." },
  { id: "guai-teaching", section: "Mucolytics and Secretion Management", front: "What teaching point goes with guaifenesin?", back: "Encourage hydration to help mucus clearance." },

  { id: "dex-use", section: "Antitussives and Oral Meds", front: "What is dextromethorphan used for?", back: "Dry cough suppression." },
  { id: "dex-caution", section: "Antitussives and Oral Meds", front: "What is the exam caution for dextromethorphan?", back: "High doses can be abused and may cause CNS effects." },
  { id: "benz-use", section: "Antitussives and Oral Meds", front: "What is benzonatate used for?", back: "Dry cough suppression by numbing stretch receptors." },
  { id: "benz-teaching", section: "Antitussives and Oral Meds", front: "What is the key safety teaching for benzonatate?", back: "Do not chew the capsules." },
  { id: "theo-class", section: "Antitussives and Oral Meds", front: "What class is theophylline?", back: "Methylxanthine." },
  { id: "theo-clue", section: "Antitussives and Oral Meds", front: "What is the biggest board clue for theophylline?", back: "Narrow therapeutic window, many drug interactions, and need for serum-level monitoring." },

  { id: "epi-emergency", section: "Emergency and Airway Meds", front: "When should epinephrine make you think emergency?", back: "Anaphylaxis or severe asthma with urgent need for rapid bronchodilation and support." },
  { id: "epi-risk", section: "Emergency and Airway Meds", front: "What is a key effect or risk of epinephrine?", back: "Rapid onset, but monitor for tachycardia and cardiac stimulation." },
  { id: "racemic-use", section: "Emergency and Airway Meds", front: "When is racemic epinephrine commonly used?", back: "Croup, stridor, or upper-airway edema." },
  { id: "racemic-caution", section: "Emergency and Airway Meds", front: "What is the important caution with racemic epinephrine?", back: "Watch for rebound symptoms after the initial improvement." },

  { id: "fastest-rescue", section: "Comparison, Traps, and Memory", front: "What is the fastest rescue pattern in this deck?", back: "SABA drugs like albuterol and levalbuterol are the main quick-relief bronchodilators." },
  { id: "maintenance-pattern", section: "Comparison, Traps, and Memory", front: "What drug pattern means maintenance, not rescue?", back: "LABA, LAMA, ICS, leukotriene antagonists, and most combo inhalers are maintenance therapies." },
  { id: "cf-drug", section: "Comparison, Traps, and Memory", front: "What drug should make you think cystic fibrosis?", back: "Dornase alfa." },
  { id: "croup-drug", section: "Comparison, Traps, and Memory", front: "What drug should make you think croup or stridor?", back: "Racemic epinephrine." },
  { id: "thrush-drug", section: "Comparison, Traps, and Memory", front: "What drug should make you think oral thrush prevention teaching?", back: "Inhaled corticosteroids like fluticasone or budesonide." },
  { id: "level-monitoring", section: "Comparison, Traps, and Memory", front: "What drug should make you think serum level monitoring?", back: "Theophylline." },
  { id: "laba-trap", section: "Comparison, Traps, and Memory", front: "What is a common RT pharmacology trap with LABAs?", back: "They are not rescue medications, and on exams they are often paired with ICS for maintenance." },
  { id: "acetyl-trap", section: "Comparison, Traps, and Memory", front: "What is a common RT pharmacology trap with acetylcysteine?", back: "It helps break up mucus, but it can also cause bronchospasm." },
  { id: "mont-trap", section: "Comparison, Traps, and Memory", front: "What is a common RT pharmacology trap with montelukast?", back: "Students may mistake it for a quick bronchodilator, but it is not a rescue medication." },
  { id: "ipra-trap", section: "Comparison, Traps, and Memory", front: "What is a common RT pharmacology trap with ipratropium?", back: "It helps bronchodilation, especially with albuterol, but it is not the same as a beta-agonist." },
  { id: "saba-laba-memory", section: "Comparison, Traps, and Memory", front: "What memory trick helps separate SABA from LABA?", back: "SABA = short and fast rescue. LABA = long and scheduled maintenance." },
  { id: "ics-memory", section: "Comparison, Traps, and Memory", front: "What memory trick helps with ICS drugs?", back: "ICS = inflammation control, not instant symptom relief." },
  { id: "dorn-memory", section: "Comparison, Traps, and Memory", front: "What memory trick helps with dornase alfa?", back: "Dornase = DNA cutter in CF mucus." },
  { id: "theo-memory", section: "Comparison, Traps, and Memory", front: "What memory trick helps with theophylline?", back: "Theo = therapeutic levels matter." },
];
