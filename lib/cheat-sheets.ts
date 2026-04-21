export type CheatSheetSlide = {
  src: string;
  title: string;
  alt: string;
};

export type CheatSheetDeck = {
  slug: string;
  title: string;
  eyebrow: string;
  description: string;
  route: string;
  imageBasePath: string;
  slideCount: number;
  slides: CheatSheetSlide[];
};

export const asthmaCheatSheetDeck: CheatSheetDeck = {
  slug: "asthma",
  title: "Asthma Visual Cheat Sheet",
  eyebrow: "Respiratory Diseases",
  description:
    "A visual walkthrough of asthma definition, symptoms, triggers, diagnostics, treatment, and board exam reminders.",
  route: "/cheat-sheets/asthma",
  imageBasePath: "/cheat-sheets/asthma",
  slideCount: 7,
  slides: [
    {
      src: "/cheat-sheets/asthma/asthma-01.png",
      title: "Respiratory Diseases: Asthma",
      alt: "Asthma title slide from the Exhale Academy respiratory diseases visual cheat sheet.",
    },
    {
      src: "/cheat-sheets/asthma/asthma-02.png",
      title: "Learning Content",
      alt: "Asthma learning content slide listing respiratory disease, symptoms and causes, risk factors, diagnosis, and treatment.",
    },
    {
      src: "/cheat-sheets/asthma/asthma-03.png",
      title: "What Is Asthma?",
      alt: "Asthma definition slide describing chronic inflammatory airway disease with reversible bronchoconstriction.",
    },
    {
      src: "/cheat-sheets/asthma/asthma-04.png",
      title: "Symptoms and Triggers",
      alt: "Asthma symptoms and triggers slide listing wheezing, coughing, chest tightness, shortness of breath, allergens, cold air, exercise, stress, and respiratory infections.",
    },
    {
      src: "/cheat-sheets/asthma/asthma-05.png",
      title: "Diagnostics",
      alt: "Asthma diagnostics slide listing decreased peak flow, decreased FEV1, normal DLCO, and hyperinflation on X-ray during attack.",
    },
    {
      src: "/cheat-sheets/asthma/asthma-06.png",
      title: "Interventions",
      alt: "Asthma interventions slide listing SABAs, corticosteroids, peak flow monitoring, and oxygen therapy if hypoxic.",
    },
    {
      src: "/cheat-sheets/asthma/asthma-07.png",
      title: "Remember",
      alt: "Asthma reminder slide emphasizing inhaler technique and reversibility with bronchodilators.",
    },
  ],
};

export const cheatSheetDecks: CheatSheetDeck[] = [asthmaCheatSheetDeck];
