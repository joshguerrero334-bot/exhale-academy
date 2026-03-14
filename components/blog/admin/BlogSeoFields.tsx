import type { BlogPost } from "../../../lib/blog/types";

export default function BlogSeoFields({ post }: { post: BlogPost | null }) {
  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div className="sm:col-span-2">
        <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">SEO title</label>
        <input type="text" name="seo_title" defaultValue={post?.seoTitle ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">SEO description</label>
        <textarea name="seo_description" rows={3} defaultValue={post?.seoDescription ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
      </div>
      <div className="sm:col-span-2">
        <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Canonical URL</label>
        <input type="url" name="canonical_url" defaultValue={post?.canonicalUrl ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
      </div>
    </div>
  );
}
