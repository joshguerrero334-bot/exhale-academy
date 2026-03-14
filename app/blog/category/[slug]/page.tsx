import type { Metadata } from "next";
import BlogPostCard from "../../../../components/blog/BlogPostCard";
import { buildBlogArchiveMetadata } from "../../../../lib/blog/metadata";
import { getBlogCategoryBySlug, getPublishedBlogFeed } from "../../../../lib/blog/queries";
import { notFound } from "next/navigation";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const category = await getBlogCategoryBySlug(slug);
  if (!category) return { title: "Category Not Found | Exhale Academy Blog" };
  return buildBlogArchiveMetadata("category", category);
}

export default async function BlogCategoryArchivePage({ params }: Props) {
  const { slug } = await params;
  const category = await getBlogCategoryBySlug(slug);
  if (!category) notFound();

  const feed = await getPublishedBlogFeed({ category: slug, pageSize: 12 });

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-6xl space-y-8">
        <section className="rounded-[2rem] border border-[color:var(--border)] bg-white p-6 shadow-sm sm:p-8 lg:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Category Archive</p>
          <h1 className="mt-3 text-4xl font-semibold text-[color:var(--brand-navy)] sm:text-5xl">{category.name}</h1>
          <p className="mt-4 max-w-3xl text-sm leading-8 text-slate-600 sm:text-base">{category.description || `Browse Exhale Academy articles in ${category.name}.`}</p>
        </section>
        <div className="grid gap-6 lg:grid-cols-2">
          {feed.items.map((post) => <BlogPostCard key={post.id} post={post} />)}
        </div>
      </div>
    </main>
  );
}
