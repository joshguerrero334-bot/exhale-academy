export function estimateReadTime(markdown: string) {
  const plain = markdown
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/`[^`]+`/g, " ")
    .replace(/[>#*_\-[\]()]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  const words = plain ? plain.split(" ").length : 0;
  return Math.max(1, Math.ceil(words / 200));
}
