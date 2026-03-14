import { notFound, redirect } from "next/navigation";
import BlogEditorForm from "../../../../../components/blog/admin/BlogEditorForm";
import { isAdminUser } from "../../../../../lib/auth/admin";
import { getAdminBlogPostById, getBlogAuthorsForAdmin, getBlogCategories } from "../../../../../lib/blog/queries";
import { createClient } from "../../../../../lib/supabase/server";

type Props = {
  params: Promise<{ id: string }>;
  searchParams?: Promise<{ uploaded?: string; message?: string; error?: string }>;
};

export default async function AdminEditBlogPostPage({ params, searchParams }: Props) {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login?next=%2Fadmin%2Fblog");
  if (!isAdminUser({ id: user.id, email: user.email ?? null })) redirect("/dashboard?error=Admin%20access%20only");

  const emptySearch: { uploaded?: string; message?: string; error?: string } = {};
  const [{ id }, search] = await Promise.all([params, searchParams ?? Promise.resolve(emptySearch)]);
  const [post, categories, authors] = await Promise.all([getAdminBlogPostById(id), getBlogCategories(), getBlogAuthorsForAdmin()]);
  if (!post) notFound();
  const authorList = authors.some((author) => author.id === user.id)
    ? authors
    : [{ id: user.id, displayName: user.email?.split("@")[0] || "Admin", avatarUrl: null }, ...authors];

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Admin Blog</p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">Edit blog post</h1>
          <p className="mt-3 text-sm text-slate-600">Update content, SEO fields, featured imagery, and comment settings.</p>
          {search.message ? <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700">{search.message}</p> : null}
          {search.error ? <p className="mt-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{search.error}</p> : null}
        </section>
        <BlogEditorForm post={post} categories={categories} authors={authorList} redirectPath={`/admin/blog/${post.id}/edit`} uploadedImageUrl={search.uploaded} />
      </div>
    </main>
  );
}
