import Link from "next/link";
import { redirect } from "next/navigation";
import { deleteBlogPost } from "./actions";
import { isAdminUser } from "../../../lib/auth/admin";
import { getAdminBlogPosts, getBlogCategories, getBlogTags } from "../../../lib/blog/queries";
import { createClient } from "../../../lib/supabase/server";

function formatDate(value: string | null) {
  if (!value) return "Draft";
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric" }).format(new Date(value));
}

type Props = { searchParams?: Promise<{ message?: string; error?: string }> };

export default async function AdminBlogDashboardPage({ searchParams }: Props) {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login?next=%2Fadmin%2Fblog");
  if (!isAdminUser({ id: user.id, email: user.email ?? null })) redirect("/dashboard?error=Admin%20access%20only");

  const emptySearch: { message?: string; error?: string } = {};
  const params = await (searchParams ?? Promise.resolve(emptySearch));
  const [posts, categories, tags] = await Promise.all([getAdminBlogPosts(), getBlogCategories(), getBlogTags()]);

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-6xl space-y-6">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Admin Blog</p>
              <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">Publish and moderate Exhale articles</h1>
              <p className="mt-3 max-w-2xl text-sm text-slate-600">Manage posts, SEO, comments, categories, tags, and featured placement from one dashboard.</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Link href="/admin/blog/new" className="btn-primary">New Post</Link>
              <Link href="/admin/blog/comments" className="btn-secondary">Moderate Comments</Link>
              <Link href="/blog" className="btn-secondary">View Blog</Link>
            </div>
          </div>
          <div className="mt-6 grid gap-3 sm:grid-cols-4">
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4"><p className="text-xs uppercase tracking-[0.14em] text-slate-500">Total Posts</p><p className="mt-2 text-2xl font-semibold text-[color:var(--brand-navy)]">{posts.length}</p></div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4"><p className="text-xs uppercase tracking-[0.14em] text-slate-500">Published</p><p className="mt-2 text-2xl font-semibold text-[color:var(--brand-navy)]">{posts.filter((post) => post.status === "published").length}</p></div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4"><p className="text-xs uppercase tracking-[0.14em] text-slate-500">Categories</p><p className="mt-2 text-2xl font-semibold text-[color:var(--brand-navy)]">{categories.length}</p></div>
            <div className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4"><p className="text-xs uppercase tracking-[0.14em] text-slate-500">Tags</p><p className="mt-2 text-2xl font-semibold text-[color:var(--brand-navy)]">{tags.length}</p></div>
          </div>
          {params.message ? <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700">{params.message}</p> : null}
          {params.error ? <p className="mt-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{params.error}</p> : null}
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Posts</h2>
            <div className="flex gap-3 text-sm">
              <Link href="/admin/blog/categories" className="btn-secondary">Categories</Link>
              <Link href="/admin/blog/tags" className="btn-secondary">Tags</Link>
            </div>
          </div>
          <div className="mt-5 space-y-4">
            {posts.length > 0 ? posts.map((post) => (
              <article key={post.id} className="rounded-xl border border-[color:var(--cool-gray)] bg-white p-4">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <div className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">
                      <span>{post.status}</span>
                      <span>{formatDate(post.publishedAt)}</span>
                      <span>{post.primaryCategory?.name ?? "No category"}</span>
                      {post.isFeatured ? <span>Featured</span> : null}
                    </div>
                    <h3 className="mt-2 text-xl font-semibold text-[color:var(--brand-navy)]">{post.title}</h3>
                    <p className="mt-2 max-w-3xl text-sm text-slate-600">{post.excerpt}</p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Link href={`/admin/blog/${post.id}/edit`} className="btn-secondary">Edit</Link>
                    <Link href={`/blog/${post.slug}`} className="btn-secondary">View</Link>
                    <form action={deleteBlogPost}><input type="hidden" name="post_id" value={post.id} /><button type="submit" className="rounded-lg border border-red-200 px-4 py-2 text-sm font-semibold text-red-700 transition hover:bg-red-50">Delete</button></form>
                  </div>
                </div>
              </article>
            )) : <p className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4 text-sm text-slate-600">No posts yet.</p>}
          </div>
        </section>
      </div>
    </main>
  );
}
