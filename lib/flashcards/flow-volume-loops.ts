export type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: string;
  frontImage?: string;
  frontImageAlt?: string;
};

export const flowVolumeLoopSections = [
  "Loop Identification",
  "Loop Clues",
] as const;

export const flowVolumeLoopCards: Flashcard[] = [
  {
    id: "loop-image-normal",
    section: "Loop Identification",
    front: "What type of loop is this?",
    back: "Normal flow-volume loop.",
    frontImage: "/flashcards/pft-loops/normal-loop.svg",
    frontImageAlt: "Normal flow-volume loop identification card",
  },
  {
    id: "loop-image-obstructive",
    section: "Loop Identification",
    front: "What type of loop is this?",
    back: "Obstructive flow-volume loop.",
    frontImage: "/flashcards/pft-loops/obstructive-loop.svg",
    frontImageAlt: "Obstructive flow-volume loop identification card",
  },
  {
    id: "loop-image-restrictive",
    section: "Loop Identification",
    front: "What type of loop is this?",
    back: "Restrictive flow-volume loop.",
    frontImage: "/flashcards/pft-loops/restrictive-loop.svg",
    frontImageAlt: "Restrictive flow-volume loop identification card",
  },
  {
    id: "loop-clue-normal",
    section: "Loop Clues",
    front: "What clue points to a normal flow-volume loop?",
    back: "A rounded, balanced shape with a smooth descending limb.",
  },
  {
    id: "loop-clue-obstructive",
    section: "Loop Clues",
    front: "What clue points to an obstructive loop?",
    back: "A scooped-out or coved descending limb, often with reduced peak flow.",
  },
  {
    id: "loop-clue-restrictive",
    section: "Loop Clues",
    front: "What clue points to a restrictive loop?",
    back: "A tall, narrow loop with reduced total volume.",
  },
  {
    id: "loop-disease-obstructive",
    section: "Loop Clues",
    front: "Which diseases commonly match an obstructive loop?",
    back: "COPD and asthma.",
  },
  {
    id: "loop-disease-restrictive",
    section: "Loop Clues",
    front: "Which diseases commonly match a restrictive loop?",
    back: "Fibrosis, ARDS, and neuromuscular disease.",
  },
];
