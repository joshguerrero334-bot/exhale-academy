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
  const baseClass =
    "inline-flex min-h-11 min-w-[72px] items-center justify-center rounded-full border px-4 py-2 text-sm font-medium transition";
  const activeClass = "border-[color:var(--brand-navy)] bg-[color:var(--brand-navy)] text-white shadow-sm";
  const inactiveClass =
    "border-[color:var(--border)] bg-white text-slate-700 hover:border-[color:var(--brand-gold)] hover:text-[color:var(--brand-navy)]";

  return (
    <div className="flex flex-wrap gap-2">
      <Link
        href={buildHref(null, q, tag)}
        className={`${baseClass} ${!activeCategory ? activeClass : inactiveClass}`}
        aria-current={!activeCategory ? "page" : undefined}
      >
        All Posts
      </Link>
      {categories.map((category) => (
        <Link
          key={category.id}
          href={buildHref(category.slug, q, tag)}
          className={`${baseClass} ${activeCategory === category.slug ? activeClass : inactiveClass}`}
          aria-current={activeCategory === category.slug ? "page" : undefined}
        >
          {category.name}
        </Link>
      ))}
    </div>
  );
}
