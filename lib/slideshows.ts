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

export const slideshowDecks: SlideshowDeck[] = [
  asthmaSlideshowDeck,
  copdSlideshowDeck,
];
