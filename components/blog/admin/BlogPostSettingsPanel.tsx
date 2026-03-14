import type { BlogAuthor, BlogCategory, BlogPost } from "../../../lib/blog/types";
import BlogCategorySelector from "./BlogCategorySelector";
import BlogTagSelector from "./BlogTagSelector";

export default function BlogPostSettingsPanel({ post, categories, authors }: { post: BlogPost | null; categories: BlogCategory[]; authors: BlogAuthor[] }) {
  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <BlogCategorySelector categories={categories} post={post} />
      <div>
        <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Author</label>
        <select name="author_id" defaultValue={post?.author?.id ?? authors[0]?.id ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]">
          {authors.map((author) => <option key={author.id} value={author.id}>{author.displayName}</option>)}
        </select>
      </div>
      <div className="sm:col-span-2">
        <BlogTagSelector post={post} />
      </div>
    </div>
  );
}
