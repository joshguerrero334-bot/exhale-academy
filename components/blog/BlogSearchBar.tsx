import Link from "next/link";
import type { BlogTag } from "../../lib/blog/types";

type Props = {
  search: string;
  category: string;
  tag: string;
  tags: BlogTag[];
};

export default function BlogSearchBar({ search, category, tag, tags }: Props) {
  return (
    <form className="rounded-[1.5rem] border border-[color:var(--border)] bg-[color:var(--surface-soft)] p-5 shadow-inner">
      <input type="hidden" name="category" value={category} />
      <div className="space-y-4">
        <div>
          <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Search articles</label>
          <input
            type="search"
            name="q"
            defaultValue={search}
            placeholder="ABGs, ventilator management, CSE..."
            className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]"
          />
        </div>
        <div>
          <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Tag filter</label>
          <select
            name="tag"
            defaultValue={tag}
            className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]"
          >
            <option value="">All tags</option>
            {tags.map((entry) => (
              <option key={entry.id} value={entry.slug}>
                {entry.name}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-wrap gap-3">
          <button type="submit" className="btn-primary">
            Filter Posts
          </button>
          <Link href="/blog" className="btn-secondary">
            Clear
          </Link>
        </div>
      </div>
    </form>
  );
}
