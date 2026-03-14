import { redirect } from "next/navigation";
import { deleteBlogTag, saveBlogTag } from "../../../../app/admin/blog/actions";
import { isAdminUser } from "../../../../lib/auth/admin";
import { getBlogTags } from "../../../../lib/blog/queries";
import { createClient } from "../../../../lib/supabase/server";

type Props = { searchParams?: Promise<{ message?: string; error?: string }> };

export default async function AdminBlogTagsPage({ searchParams }: Props) {
  const supabase = await createClient();
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) redirect("/login?next=%2Fadmin%2Fblog%2Ftags");
  if (!isAdminUser({ id: user.id, email: user.email ?? null })) redirect("/dashboard?error=Admin%20access%20only");

  const emptySearch: { message?: string; error?: string } = {};
  const params = await (searchParams ?? Promise.resolve(emptySearch));
  const tags = await getBlogTags();

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-5xl space-y-6">
        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Admin Blog</p>
          <h1 className="mt-2 text-3xl font-bold text-[color:var(--brand-navy)]">Tags</h1>
          {params.message ? <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-emerald-700">{params.message}</p> : null}
          {params.error ? <p className="mt-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">{params.error}</p> : null}
        </section>

        <section className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
          <h2 className="text-xl font-semibold text-[color:var(--brand-navy)]">Create tag</h2>
          <form action={saveBlogTag} className="mt-4 grid gap-4 sm:grid-cols-2">
            <input type="text" name="name" placeholder="Name" className="rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm" />
            <input type="text" name="slug" placeholder="Slug (optional)" className="rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm" />
            <button type="submit" className="btn-primary sm:col-span-2 sm:w-fit">Save Tag</button>
          </form>
        </section>

        <div className="space-y-4">
          {tags.map((tag) => (
            <article key={tag.id} className="rounded-xl border border-[color:var(--cool-gray)] bg-white p-4">
              <form action={saveBlogTag} className="grid gap-3 sm:grid-cols-[1fr_1fr_auto]">
                <input type="hidden" name="id" value={tag.id} />
                <input type="text" name="name" defaultValue={tag.name} className="rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm" />
                <input type="text" name="slug" defaultValue={tag.slug} className="rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm" />
                <button type="submit" className="btn-secondary">Update</button>
              </form>
              <form action={deleteBlogTag} className="mt-3"><input type="hidden" name="id" value={tag.id} /><button type="submit" className="rounded-lg border border-red-200 px-4 py-2 text-sm font-semibold text-red-700 transition hover:bg-red-50">Delete</button></form>
            </article>
          ))}
        </div>
      </div>
    </main>
  );
}
