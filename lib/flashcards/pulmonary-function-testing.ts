export type Flashcard = {
  id: string;
  front: string;
  back: string;
  section: string;
  frontImage?: string;
  frontImageAlt?: string;
};

export const pulmonaryFunctionTestingSections = [
  "Key Terms",
  "Interpretation Flow",
  "Patterns",
  "Flow-Volume Loops",
  "Buzzwords, Traps, and Memory",
] as const;

export const pulmonaryFunctionTestingCards: Flashcard[] = [
  { id: "fvc-definition", section: "Key Terms", front: "What is FVC?", back: "Forced vital capacity: the total amount of air exhaled during a forced breath." },
  { id: "fev1-definition", section: "Key Terms", front: "What is FEV1?", back: "Forced expiratory volume in 1 second: the amount exhaled in the first second of a forced breath." },
  { id: "ratio-purpose", section: "Key Terms", front: "What is the FEV1/FVC ratio used for?", back: "It helps separate obstructive patterns from normal or restrictive patterns." },
  { id: "rv-definition", section: "Key Terms", front: "What is RV?", back: "Residual volume: the air left in the lungs after a maximal exhalation." },
  { id: "tlc-definition", section: "Key Terms", front: "What is TLC?", back: "Total lung capacity: the total amount of air in the lungs after a maximal inhalation." },
  { id: "dlco-definition", section: "Key Terms", front: "What is DLCO?", back: "Diffusing capacity: how well gas moves across the alveolar-capillary membrane." },
  { id: "fev1-normal", section: "Key Terms", front: "What is a normal FEV1?", back: "About 80% predicted or higher." },
  { id: "fvc-normal", section: "Key Terms", front: "What is a normal FVC?", back: "About 80% predicted or higher." },
  { id: "ratio-normal", section: "Key Terms", front: "What is a normal FEV1/FVC ratio?", back: "About 70% or higher, with age adjustment." },
  { id: "tlc-normal", section: "Key Terms", front: "What is a normal TLC?", back: "About 80% to 120% predicted." },
  { id: "dlco-normal", section: "Key Terms", front: "What is a normal DLCO?", back: "About 80% to 120% predicted." },

  { id: "ratio-first", section: "Interpretation Flow", front: "What should you check first when reading PFTs?", back: "Check the FEV1/FVC ratio first." },
  { id: "low-ratio-means", section: "Interpretation Flow", front: "What does FEV1/FVC below 70% suggest?", back: "An obstructive pattern." },
  { id: "normal-ratio-next-step", section: "Interpretation Flow", front: "If the ratio is normal or high, what should you check next?", back: "Check FVC next to see if restriction is possible." },
  { id: "low-fvc-suggests", section: "Interpretation Flow", front: "What does a low FVC suggest?", back: "Possible restriction, but it is not enough to prove it by itself." },
  { id: "confirm-restriction", section: "Interpretation Flow", front: "What confirms restriction on PFTs?", back: "A low TLC confirms a restrictive process." },
  { id: "dlco-step", section: "Interpretation Flow", front: "When should DLCO come into your interpretation?", back: "After the basic pattern is identified, use DLCO to judge gas-exchange involvement." },
  { id: "low-dlco-clue", section: "Interpretation Flow", front: "What does a low DLCO often point toward?", back: "Problems with gas exchange, especially emphysema or fibrosis." },
  { id: "normal-dlco-clue", section: "Interpretation Flow", front: "What does a normal DLCO make you think about?", back: "It can fit asthma or earlier disease and may point away from emphysema." },
  { id: "study-order", section: "Interpretation Flow", front: "What is the best quick interpretation order?", back: "Ratio first, then FVC, then TLC, then DLCO." },

  { id: "obstructive-pattern", section: "Patterns", front: "What classic PFT pattern fits obstructive disease?", back: "Low FEV1, low ratio, and TLC that is normal or high." },
  { id: "restrictive-pattern", section: "Patterns", front: "What classic PFT pattern fits restrictive disease?", back: "Low FEV1, low FVC, normal or high ratio, and low TLC." },
  { id: "obstructive-examples", section: "Patterns", front: "Which diseases commonly cause an obstructive pattern?", back: "COPD and asthma are the classic board examples." },
  { id: "restrictive-examples", section: "Patterns", front: "Which diseases commonly cause a restrictive pattern?", back: "Fibrosis, ARDS, obesity, and neuromuscular disease." },
  { id: "air-out-memory", section: "Patterns", front: "What is the easiest way to remember obstructive disease?", back: "Obstructive means trouble getting air out." },
  { id: "air-in-memory", section: "Patterns", front: "What is the easiest way to remember restrictive disease?", back: "Restrictive means trouble getting air in and a low total volume." },
  { id: "low-ratio-high-tlc", section: "Patterns", front: "Board clue: low ratio with normal or high TLC. What pattern is this?", back: "Obstructive." },
  { id: "normal-ratio-low-tlc", section: "Patterns", front: "Board clue: normal ratio with low TLC. What pattern is this?", back: "Restrictive." },
  { id: "emphysema-vs-asthma-dlco", section: "Patterns", front: "Which disease is more likely to lower DLCO: emphysema or asthma?", back: "Emphysema is more likely to lower DLCO." },

  { id: "normal-loop", section: "Flow-Volume Loops", front: "What does a normal flow-volume loop look like?", back: "Rounded and symmetrical, with a smooth descending expiratory limb." },
  { id: "obstructive-loop", section: "Flow-Volume Loops", front: "What does an obstructive loop look like?", back: "Scooped or coved on the descending limb, often with reduced peak flow." },
  { id: "restrictive-loop", section: "Flow-Volume Loops", front: "What does a restrictive loop look like?", back: "Tall and narrow, with reduced total volume." },
  {
    id: "image-normal-loop",
    section: "Flow-Volume Loops",
    front: "What type of loop is this?",
    back: "Normal flow-volume loop.",
    frontImage: "/flashcards/pft-loops/normal-loop.svg",
    frontImageAlt: "Normal flow-volume loop flashcard visual",
  },
  {
    id: "image-obstructive-loop",
    section: "Flow-Volume Loops",
    front: "What type of loop is this?",
    back: "Obstructive flow-volume loop.",
    frontImage: "/flashcards/pft-loops/obstructive-loop.svg",
    frontImageAlt: "Obstructive flow-volume loop flashcard visual",
  },
  {
    id: "image-restrictive-loop",
    section: "Flow-Volume Loops",
    front: "What type of loop is this?",
    back: "Restrictive flow-volume loop.",
    frontImage: "/flashcards/pft-loops/restrictive-loop.svg",
    frontImageAlt: "Restrictive flow-volume loop flashcard visual",
  },
  { id: "scooped-loop-clue", section: "Flow-Volume Loops", front: "What board clue should make you think obstructive disease on a loop?", back: "A scooped-out descending limb." },
  { id: "tall-narrow-loop-clue", section: "Flow-Volume Loops", front: "What board clue should make you think restrictive disease on a loop?", back: "A tall, narrow loop with low volume." },
  { id: "restrictive-peak-flow", section: "Flow-Volume Loops", front: "Can peak flow look normal in a restrictive loop?", back: "Yes. The total volume is low, but peak flow may still appear near normal." },

  { id: "trap-low-fvc-alone", section: "Buzzwords, Traps, and Memory", front: "Common trap: does a low FVC alone prove restriction?", back: "No. You still need TLC to confirm restriction." },
  { id: "trap-normal-ratio", section: "Buzzwords, Traps, and Memory", front: "Common trap: does a normal or high ratio always mean normal lungs?", back: "No. It can still fit restriction, so keep going with FVC and TLC." },
  { id: "trap-ignore-dlco", section: "Buzzwords, Traps, and Memory", front: "Why is it a mistake to ignore DLCO?", back: "DLCO helps separate gas-exchange problems from patterns with preserved diffusion." },
  { id: "buzzword-low-tlc", section: "Buzzwords, Traps, and Memory", front: "Board buzzword: low TLC means what?", back: "Think restrictive disease." },
  { id: "buzzword-low-ratio", section: "Buzzwords, Traps, and Memory", front: "Board buzzword: low FEV1/FVC means what?", back: "Think obstructive disease." },
  { id: "buzzword-low-dlco", section: "Buzzwords, Traps, and Memory", front: "Board buzzword: low DLCO should make you think of what two big patterns?", back: "Emphysema and fibrosis." },
  { id: "memory-sequence", section: "Buzzwords, Traps, and Memory", front: "What quick memory trick helps you read PFTs fast?", back: "Ratio first, then FVC, then TLC, then DLCO." },
];
