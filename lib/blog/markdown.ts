function escapeHtml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");
}

function renderInline(markdown: string) {
  let html = escapeHtml(markdown);

  html = html.replace(/`([^`]+)`/g, '<code class="rounded bg-slate-100 px-1.5 py-0.5 font-mono text-[0.95em] text-[color:var(--brand-navy)]">$1</code>');
  html = html.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  html = html.replace(/\*([^*]+)\*/g, "<em>$1</em>");
  html = html.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, '<a href="$2" class="font-medium text-[color:var(--brand-gold)] underline underline-offset-4" target="_blank" rel="noreferrer">$1</a>');

  return html;
}

function isListLine(line: string) {
  return /^\s*(?:[-*]\s+|\d+\.\s+)/.test(line);
}

function isOrderedLine(line: string) {
  return /^\s*\d+\.\s+/.test(line);
}

export function estimateReadTimeMinutes(markdown: string) {
  const plain = markdown
    .replace(/```[\s\S]*?```/g, " ")
    .replace(/`[^`]+`/g, " ")
    .replace(/[#>*_\-[\]()`]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

  const words = plain ? plain.split(" ").length : 0;
  return Math.max(1, Math.ceil(words / 200));
}

export function extractTableOfContents(markdown: string) {
  return markdown
    .split(/\r?\n/)
    .map((line) => line.match(/^(#{2,3})\s+(.*)$/))
    .filter((match): match is RegExpMatchArray => Boolean(match))
    .map((match) => ({
      level: match[1].length,
      text: match[2].trim(),
      id: slugify(match[2].trim()),
    }));
}

export function renderMarkdown(markdown: string) {
  const lines = markdown.replace(/\r\n/g, "\n").split("\n");
  const blocks: string[] = [];
  let index = 0;

  while (index < lines.length) {
    const rawLine = lines[index];
    const line = rawLine.trimEnd();

    if (!line.trim()) {
      index += 1;
      continue;
    }

    if (line.startsWith("```")) {
      const language = line.slice(3).trim();
      index += 1;
      const codeLines: string[] = [];
      while (index < lines.length && !lines[index].trimStart().startsWith("```")) {
        codeLines.push(lines[index]);
        index += 1;
      }
      if (index < lines.length) index += 1;
      blocks.push(
        `<pre class="overflow-x-auto rounded-2xl border border-[color:var(--border)] bg-[color:var(--brand-navy)] px-4 py-4 text-sm text-white"><code${language ? ` data-language="${escapeHtml(language)}"` : ""}>${escapeHtml(codeLines.join("\n"))}</code></pre>`
      );
      continue;
    }

    const headingMatch = line.match(/^(#{1,6})\s+(.*)$/);
    if (headingMatch) {
      const level = Math.min(6, headingMatch[1].length);
      const text = headingMatch[2].trim();
      const id = level <= 3 ? ` id="${slugify(text)}"` : "";
      const classes =
        level === 1
          ? "mt-10 text-4xl font-semibold text-[color:var(--brand-navy)]"
          : level === 2
            ? "mt-10 text-2xl font-semibold text-[color:var(--brand-navy)]"
            : level === 3
              ? "mt-8 text-xl font-semibold text-[color:var(--brand-navy)]"
              : "mt-6 text-lg font-semibold text-[color:var(--brand-navy)]";
      blocks.push(`<h${level}${id} class="${classes}">${renderInline(text)}</h${level}>`);
      index += 1;
      continue;
    }

    if (line.trimStart().startsWith(">")) {
      const quoteLines: string[] = [];
      while (index < lines.length && lines[index].trimStart().startsWith(">")) {
        quoteLines.push(lines[index].trimStart().replace(/^>\s?/, ""));
        index += 1;
      }
      const first = quoteLines[0] ?? "";
      if (/^\[!INFO\]/i.test(first)) {
        const body = quoteLines.map((entry, idx) => (idx === 0 ? entry.replace(/^\[!INFO\]\s*/i, "") : entry)).join(" ");
        blocks.push(`<aside class="rounded-2xl border border-[color:var(--brand-gold)]/30 bg-[color:var(--brand-gold)]/10 p-5 text-sm leading-7 text-slate-700"><p class="text-xs font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-navy)]">Info</p><p class="mt-2">${renderInline(body)}</p></aside>`);
      } else {
        blocks.push(`<blockquote class="rounded-r-2xl border-l-4 border-[color:var(--brand-gold)] bg-white px-5 py-4 text-lg italic leading-8 text-slate-700">${renderInline(quoteLines.join(" "))}</blockquote>`);
      }
      continue;
    }

    if (isListLine(line)) {
      const ordered = isOrderedLine(line);
      const items: string[] = [];
      while (index < lines.length && isListLine(lines[index])) {
        items.push(lines[index].replace(/^\s*(?:[-*]\s+|\d+\.\s+)/, "").trim());
        index += 1;
      }
      const tag = ordered ? "ol" : "ul";
      const classes = ordered ? "list-decimal" : "list-disc";
      blocks.push(
        `<${tag} class="${classes} space-y-2 pl-6 text-base leading-8 text-slate-700">${items.map((item) => `<li>${renderInline(item)}</li>`).join("")}</${tag}>`
      );
      continue;
    }

    const paragraphLines = [line];
    index += 1;
    while (index < lines.length && lines[index].trim() && !lines[index].trimStart().startsWith(">") && !lines[index].trimStart().startsWith("```") && !lines[index].match(/^(#{1,6})\s+/) && !isListLine(lines[index])) {
      paragraphLines.push(lines[index].trim());
      index += 1;
    }

    blocks.push(`<p class="text-base leading-8 text-slate-700">${renderInline(paragraphLines.join(" "))}</p>`);
  }

  return blocks.join("\n");
}
