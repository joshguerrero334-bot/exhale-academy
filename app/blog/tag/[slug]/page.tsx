import type { Metadata } from "next";
import { notFound } from "next/navigation";
import BlogPostCard from "../../../../components/blog/BlogPostCard";
import { buildBlogArchiveMetadata } from "../../../../lib/blog/metadata";
import { getBlogTagBySlug, getPublishedBlogFeed } from "../../../../lib/blog/queries";

export const dynamic = "force-dynamic";

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const tag = await getBlogTagBySlug(slug);
  if (!tag) return { title: "Tag Not Found | Exhale Academy Blog" };
  return buildBlogArchiveMetadata("tag", tag);
}

export default async function BlogTagArchivePage({ params }: Props) {
  const { slug } = await params;
  const tag = await getBlogTagBySlug(slug);
  if (!tag) notFound();

  const feed = await getPublishedBlogFeed({ tag: slug, pageSize: 12 });

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-6xl space-y-8">
        <section className="rounded-[2rem] border border-[color:var(--border)] bg-white p-6 shadow-sm sm:p-8 lg:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Tag Archive</p>
          <h1 className="mt-3 text-4xl font-semibold text-[color:var(--brand-navy)] sm:text-5xl">#{tag.name}</h1>
          <p className="mt-4 max-w-3xl text-sm leading-8 text-slate-600 sm:text-base">Articles tagged {tag.name} across Exhale Academy blog content.</p>
        </section>
        <div className="grid gap-6 lg:grid-cols-2">
          {feed.items.map((post) => <BlogPostCard key={post.id} post={post} />)}
        </div>
      </div>
    </main>
  );
}
