import { redirect } from "next/navigation";
import BlogEditorForm from "../../../../components/blog/admin/BlogEditorForm";
import { isAdminUser } from "../../../../lib/auth/admin";
import { getBlogAuthorsForAdmin, getBlogCategories } from "../../../../lib/blog/queries";
import { createClient } from "../../../../lib/supabase/server";

type Props = { searchParams?: Promise<{ uploaded?: string; message?: string; error?: string }> };

export default async function AdminNewBlogPostPage({ searchParams }: Props) {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login?next=%2Fadmin%2Fblog%2Fnew");
  if (!isAdminUser({ id: user.id, email: user.email ?? null })) redirect("/dashboard?error=Admin%20access%20only");

  const emptySearch: { uploaded?: string; message?: string; error?: string } = {};
  const params = await (searchParams ?? Promise.resolve(emptySearch));
  const [categories, authors] = await Promise.all([getBlogCategories(), getBlogAuthorsForAdmin()]);
  const authorList = authors.some((author) => author.id === user.id)
    ? authors
    : [{ id: user.id, displayName: user.email?.split("@")[0] || "Admin", avatarUrl: null }, ...authors];

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Admin Blog</p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">Create blog post</h1>
          <p className="mt-3 text-sm text-slate-600">Draft, publish, and optimize articles for Exhale Academy SEO and conversion.</p>
          {params.message ? <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700">{params.message}</p> : null}
          {params.error ? <p className="mt-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{params.error}</p> : null}
        </section>
        <BlogEditorForm post={null} categories={categories} authors={authorList} redirectPath="/admin/blog/new" uploadedImageUrl={params.uploaded} />
      </div>
    </main>
  );
}
