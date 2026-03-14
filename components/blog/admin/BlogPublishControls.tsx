import type { BlogPost } from "../../../lib/blog/types";

export default function BlogPublishControls({ post }: { post: BlogPost | null }) {
  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div>
        <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Status</label>
        <select name="status" defaultValue={post?.status ?? "draft"} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]">
          <option value="draft">Draft</option>
          <option value="published">Published</option>
          <option value="archived">Archived</option>
        </select>
      </div>
      <div>
        <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Preview URL</label>
        <input type="text" readOnly value={post?.slug ? `/blog/${post.slug}` : "Will generate from slug"} className="w-full rounded-xl border border-[color:var(--border)] bg-[color:var(--surface-soft)] px-4 py-3 text-sm text-slate-600" />
      </div>
      <label className="flex items-center gap-3 text-sm font-medium text-[color:var(--brand-navy)]">
        <input type="checkbox" name="is_featured" defaultChecked={post?.isFeatured ?? false} className="h-4 w-4" />
        Mark as featured post
      </label>
      <label className="flex items-center gap-3 text-sm font-medium text-[color:var(--brand-navy)]">
        <input type="checkbox" name="allow_comments" defaultChecked={post?.allowComments ?? true} className="h-4 w-4" />
        Allow comments on this post
      </label>
    </div>
  );
}
