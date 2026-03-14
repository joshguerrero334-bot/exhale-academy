import type { BlogCategory, BlogTag } from "../../lib/blog/types";
import BlogCategoryFilter from "./BlogCategoryFilter";
import BlogSearchBar from "./BlogSearchBar";

type Props = {
  categories: BlogCategory[];
  tags: BlogTag[];
  q: string;
  category: string;
  tag: string;
};

export default function BlogHero({ categories, tags, q, category, tag }: Props) {
  return (
    <section className="rounded-[2rem] border border-[color:var(--border)] bg-white p-6 shadow-sm sm:p-8 lg:p-10">
      <div className="grid gap-8 lg:grid-cols-[1.3fr_0.7fr] lg:items-end">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Exhale Academy Blog</p>
          <h1 className="mt-3 text-4xl font-semibold text-[color:var(--brand-navy)] sm:text-5xl">
            Free RT education that leads directly into smarter exam prep.
          </h1>
          <p className="mt-4 max-w-3xl text-sm leading-8 text-slate-600 sm:text-base">
            Explore respiratory therapy articles focused on TMC prep, ABGs, ventilator management, and bedside-first clinical reasoning. Public education up front, deeper practice inside Exhale.
          </p>
          <div className="mt-6">
            <BlogCategoryFilter categories={categories} activeCategory={category} q={q} tag={tag} />
          </div>
        </div>
        <BlogSearchBar search={q} category={category} tag={tag} tags={tags} />
      </div>
    </section>
  );
}
