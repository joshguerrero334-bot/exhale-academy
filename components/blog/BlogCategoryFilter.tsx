import Link from "next/link";
import type { BlogCategory } from "../../lib/blog/types";

type Props = {
  categories: BlogCategory[];
  activeCategory?: string;
  q?: string;
  tag?: string;
};

function buildHref(categorySlug: string | null, q?: string, tag?: string) {
  const params = new URLSearchParams();
  if (q) params.set("q", q);
  if (tag) params.set("tag", tag);
  if (categorySlug) params.set("category", categorySlug);
  const search = params.toString();
  return search ? `/blog?${search}` : "/blog";
}

export default function BlogCategoryFilter({ categories, activeCategory, q, tag }: Props) {
  return (
    <div className="flex flex-wrap gap-2">
      <Link href={buildHref(null, q, tag)} className={`rounded-full px-4 py-2 text-sm font-medium transition ${!activeCategory ? "bg-[color:var(--brand-navy)] text-white" : "bg-white text-slate-600 hover:text-[color:var(--brand-navy)]"}`}>
        All
      </Link>
      {categories.map((category) => (
        <Link key={category.id} href={buildHref(category.slug, q, tag)} className={`rounded-full px-4 py-2 text-sm font-medium transition ${activeCategory === category.slug ? "bg-[color:var(--brand-navy)] text-white" : "bg-white text-slate-600 hover:text-[color:var(--brand-navy)]"}`}>
          {category.name}
        </Link>
      ))}
    </div>
  );
}
