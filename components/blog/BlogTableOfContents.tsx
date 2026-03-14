type TocItem = { id: string; text: string; level: number };

type Props = { items: TocItem[] };

export default function BlogTableOfContents({ items }: Props) {
  if (items.length === 0) return null;
  return (
    <nav className="rounded-[1.5rem] border border-[color:var(--border)] bg-white p-5 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-navy)]">Table of Contents</p>
      <ol className="mt-4 space-y-3 text-sm text-slate-600">
        {items.map((item) => (
          <li key={item.id} className={item.level === 3 ? "pl-4" : ""}>
            <a href={`#${item.id}`} className="transition hover:text-[color:var(--brand-gold)]">
              {item.text}
            </a>
          </li>
        ))}
      </ol>
    </nav>
  );
}
