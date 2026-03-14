import type { BlogCategory, BlogPost } from "../../../lib/blog/types";

export default function BlogCategorySelector({ categories, post }: { categories: BlogCategory[]; post: BlogPost | null }) {
  return (
    <div>
      <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Primary category</label>
      <select name="category_id" defaultValue={post?.primaryCategory?.id ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]">
        <option value="">No category</option>
        {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
      </select>
    </div>
  );
}
