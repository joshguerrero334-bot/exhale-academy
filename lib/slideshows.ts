export type SlideshowSlide = {
  src: string;
  title: string;
  alt: string;
  category?: string;
};

export type SlideshowDeck = {
  slug: string;
  title: string;
  eyebrow: string;
  description: string;
  route: string;
  imageBasePath: string;
  slideCount: number;
  slides: SlideshowSlide[];
};

function makeRespiratoryDiseaseSlides(args: {
  slug: string;
  disease: string;
  count: number;
  topics: string[];
}) {
  return args.topics.slice(0, args.count).map((topic, index) => {
    const slideNumber = String(index + 1).padStart(2, "0");
    return {
      src: `/slideshows/${args.slug}/${args.slug}-${slideNumber}.png`,
      title: topic,
      alt: `${args.disease} slideshow slide ${index + 1}: ${topic}.`,
    };
  });
}

function makeCseCheatSheetSlide(args: {
  filename: string;
  title: string;
  category: string;
}): SlideshowSlide {
  return {
    src: `/slideshows/cse-cheat-sheets/${args.filename}`,
    title: args.title,
    category: args.category,
    alt: `CSE slideshow cheat sheet: ${args.title}.`,
  };
}

export const asthmaSlideshowDeck: SlideshowDeck = {
  slug: "asthma",
  title: "Asthma Visual Slideshow",
  eyebrow: "Respiratory Diseases",
  description:
    "A visual walkthrough of asthma definition, symptoms, triggers, diagnostics, treatment, and board exam reminders.",
  route: "/slideshows/asthma",
  imageBasePath: "/slideshows/asthma",
  slideCount: 7,
  slides: makeRespiratoryDiseaseSlides({
    slug: "asthma",
    disease: "Asthma",
    count: 7,
    topics: [
      "Respiratory Diseases: Asthma",
      "Learning Content",
      "What Is Asthma?",
      "Symptoms and Triggers",
      "Diagnostics",
      "Interventions",
      "Remember",
    ],
  }),
};

export const copdSlideshowDeck: SlideshowDeck = {
  slug: "copd",
  title: "COPD Visual Slideshow",
  eyebrow: "Respiratory Diseases",
  description:
    "A visual walkthrough of COPD definition, symptoms, risk factors, diagnostics, treatment, and board exam reminders.",
  route: "/slideshows/copd",
  imageBasePath: "/slideshows/copd",
  slideCount: 7,
  slides: makeRespiratoryDiseaseSlides({
    slug: "copd",
    disease: "COPD",
    count: 7,
    topics: [
      "Respiratory Diseases: COPD",
      "Learning Content",
      "What Is COPD?",
      "Symptoms and Causes",
      "Diagnostics",
      "Interventions",
      "Remember",
    ],
  }),
};

export const cseCheatSheetsSlides: SlideshowSlide[] = [
  makeCseCheatSheetSlide({
    filename: "cse-exam-structure-01.png",
    title: "CSE Exam Structure",
    category: "CSE Strategy",
  }),
  makeCseCheatSheetSlide({
    filename: "cse-scoring-rules-01.png",
    title: "CSE Scoring Rules",
    category: "CSE Strategy",
  }),
  makeCseCheatSheetSlide({
    filename: "information-gathering-01.png",
    title: "Information Gathering",
    category: "CSE Strategy",
  }),
  makeCseCheatSheetSlide({
    filename: "decision-making-01.png",
    title: "Decision Making",
    category: "CSE Strategy",
  }),
  makeCseCheatSheetSlide({
    filename: "emergency-algorithm-01.png",
    title: "CSE Emergency Algorithm",
    category: "CSE Strategy",
  }),
  makeCseCheatSheetSlide({
    filename: "what-test-should-i-pick-01.png",
    title: "What Test Should I Pick?",
    category: "Tests and Ventilation Decisions",
  }),
  makeCseCheatSheetSlide({
    filename: "abg-pattern-recognition-01.png",
    title: "ABG Pattern Recognition",
    category: "Tests and Ventilation Decisions",
  }),
  makeCseCheatSheetSlide({
    filename: "bipap-vs-intubation-01.png",
    title: "BiPAP vs Intubation",
    category: "Tests and Ventilation Decisions",
  }),
  makeCseCheatSheetSlide({
    filename: "asthma-01.png",
    title: "Asthma",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "copd-critical-care-01.png",
    title: "COPD Critical Care",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "copd-consersative-management-01.png",
    title: "CSE COPD Conservative Management",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "emphysema-vs-chronic-bronchitis-01.png",
    title: "Emphysema vs Chronic Bronchitis",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "ards-01.png",
    title: "ARDS",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "chf-and-pulmonary-edema-01.png",
    title: "CHF and Pulmonary Edema",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "pulmonary-embolism-and-cor-pulmonale-01.png",
    title: "Pulmonary Embolism and Cor Pulmonale",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "pneumonia-and-aids-01.png",
    title: "Pneumonia and AIDS",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "sleep-disorders-01.png",
    title: "Sleep Disorders",
    category: "Respiratory Disease Patterns",
  }),
  makeCseCheatSheetSlide({
    filename: "pneumothorax-vs-hemothorax-01.png",
    title: "Pneumothorax vs Hemothorax",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "burns-and-smoke-inhalation-01.png",
    title: "Burns and Smoke Inhalation",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "shock-01.png",
    title: "Shock",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "thoracic-surgery-01.png",
    title: "Thoracic Surgery",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "myocardial-infarction-01.png",
    title: "Myocardial Infarction",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "renal-failure-and-diabetes-01.png",
    title: "Renal Failure and Diabetes",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "hypothermia-01.png",
    title: "Hypothermia",
    category: "Emergency and Critical Care",
  }),
  makeCseCheatSheetSlide({
    filename: "neonatal-delivery-room-01.png",
    title: "Neonatal Delivery Room",
    category: "Pediatrics and Neonatal",
  }),
  makeCseCheatSheetSlide({
    filename: "meconium-aspiration-and-apnea-01.png",
    title: "Meconium Aspiration and Apnea",
    category: "Pediatrics and Neonatal",
  }),
  makeCseCheatSheetSlide({
    filename: "croup-vs-epiglottitis-01.png",
    title: "Croup vs Epiglottitis",
    category: "Pediatrics and Neonatal",
  }),
  makeCseCheatSheetSlide({
    filename: "bronchiolitis-cf-foreign-body-01.png",
    title: "Bronchiolitis, CF, and Foreign Body",
    category: "Pediatrics and Neonatal",
  }),
  makeCseCheatSheetSlide({
    filename: "myasthenia-gravis-vs-guillain-barre-01.png",
    title: "Myasthenia Gravis vs Guillain-Barre",
    category: "Neuro and Systemic Conditions",
  }),
  makeCseCheatSheetSlide({
    filename: "neuromuscular-conditions-01.png",
    title: "Neuromuscular Conditions",
    category: "Neuro and Systemic Conditions",
  }),
  makeCseCheatSheetSlide({
    filename: "spinal-cord-injuries-01.png",
    title: "Spinal Cord Injuries",
    category: "Neuro and Systemic Conditions",
  }),
  makeCseCheatSheetSlide({
    filename: "head-trauma-01.png",
    title: "Head Trauma",
    category: "Neuro and Systemic Conditions",
  }),
];

export const cseCheatSheetsSlideshowDeck: SlideshowDeck = {
  slug: "cse-cheat-sheets",
  title: "CSE Cheat Sheet Slideshows",
  eyebrow: "CSE Visual Review",
  description:
    "Organized CSE strategy, emergency, pediatric, disease-pattern, and decision-making slides for quick clinical simulation review.",
  route: "/slideshows/cse-cheat-sheets",
  imageBasePath: "/slideshows/cse-cheat-sheets",
  slideCount: cseCheatSheetsSlides.length,
  slides: cseCheatSheetsSlides,
};

export const slideshowDecks: SlideshowDeck[] = [
  cseCheatSheetsSlideshowDeck,
  asthmaSlideshowDeck,
  copdSlideshowDeck,
];
