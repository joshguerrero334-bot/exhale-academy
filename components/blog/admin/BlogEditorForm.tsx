import Link from "next/link";
import { saveBlogPost, uploadBlogFeaturedImage } from "../../../app/admin/blog/actions";
import type { BlogAuthor, BlogCategory, BlogPost } from "../../../lib/blog/types";
import { renderMarkdown } from "../../../lib/blog/markdown";
import BlogPostSettingsPanel from "./BlogPostSettingsPanel";
import BlogPublishControls from "./BlogPublishControls";
import BlogSeoFields from "./BlogSeoFields";

type Props = {
  post: BlogPost | null;
  categories: BlogCategory[];
  authors: BlogAuthor[];
  redirectPath: string;
  uploadedImageUrl?: string;
};

export default function BlogEditorForm({ post, categories, authors, redirectPath, uploadedImageUrl }: Props) {
  const featuredImageUrl = uploadedImageUrl || post?.featuredImageUrl || "";
  const previewMarkdown = post?.content ?? "# Your title\n\nWrite the post here.";

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
        <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Featured Image</h2>
        <p className="mt-2 text-sm text-slate-600">Upload to the `blog-images` bucket or paste an existing public image URL below.</p>
        <form action={uploadBlogFeaturedImage} className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-end">
          <input type="hidden" name="redirect_to" value={redirectPath} />
          <div className="flex-1">
            <label className="mb-2 block text-sm font-medium text-[color:var(--brand-navy)]">Upload image</label>
            <input type="file" name="featured_image" accept="image/png,image/jpeg,image/webp" className="block w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm" />
          </div>
          <button type="submit" className="btn-secondary">Upload Image</button>
        </form>
        {featuredImageUrl ? (
          <div className="mt-4 overflow-hidden rounded-2xl border border-[color:var(--border)] bg-white">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={featuredImageUrl} alt="Featured preview" className="h-56 w-full object-cover" />
          </div>
        ) : null}
      </section>

      <form action={saveBlogPost} className="space-y-6">
        <input type="hidden" name="id" value={post?.id ?? ""} />
        <input type="hidden" name="published_at" value={post?.publishedAt ?? ""} />
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <div className="grid gap-5 sm:grid-cols-2">
            <div className="sm:col-span-2">
              <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Title</label>
              <input type="text" name="title" required defaultValue={post?.title ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
            </div>
            <div>
              <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Slug</label>
              <input type="text" name="slug" defaultValue={post?.slug ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
            </div>
            <div className="sm:col-span-2">
              <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Excerpt</label>
              <textarea name="excerpt" rows={3} defaultValue={post?.excerpt ?? ""} className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
            </div>
            <div className="sm:col-span-2">
              <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Featured image URL</label>
              <input type="url" name="featured_image_url" defaultValue={featuredImageUrl} placeholder="https://..." className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
            </div>
            <div className="sm:col-span-2">
              <BlogPostSettingsPanel post={post} categories={categories} authors={authors} />
            </div>
            <div className="sm:col-span-2">
              <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Content (Markdown)</label>
              <textarea name="content" rows={22} required defaultValue={previewMarkdown} className="w-full rounded-2xl border border-[color:var(--border)] bg-white px-4 py-3 font-mono text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
              <p className="mt-2 text-xs text-slate-500">Markdown chosen for stability and maintenance. Supports headings, bold, italics, lists, blockquotes, links, images, code blocks, and `&gt; [!INFO]` callouts.</p>
            </div>
          </div>
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">SEO & Publish Controls</h2>
          <div className="mt-5 space-y-6">
            <BlogSeoFields post={post} />
            <BlogPublishControls post={post} />
          </div>
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Rendered Preview</h2>
          <div className="mt-4 rounded-2xl border border-[color:var(--border)] bg-white p-6" dangerouslySetInnerHTML={{ __html: renderMarkdown(previewMarkdown) }} />
        </section>

        <div className="flex flex-wrap gap-3">
          <button type="submit" className="btn-primary">{post ? "Save Changes" : "Create Post"}</button>
          <Link href="/admin/blog" className="btn-secondary">Back to Blog Admin</Link>
        </div>
      </form>
    </div>
  );
}
