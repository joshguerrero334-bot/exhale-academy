import Link from "next/link";
import type { Metadata } from "next";
import BlogHero from "../../components/blog/BlogHero";
import FeaturedPostCard from "../../components/blog/FeaturedPostCard";
import BlogPostCard from "../../components/blog/BlogPostCard";
import { buildBlogIndexMetadata } from "../../lib/blog/metadata";
import { getBlogCategories, getBlogTags, getPublishedBlogFeed } from "../../lib/blog/queries";

export const dynamic = "force-dynamic";
export const metadata: Metadata = buildBlogIndexMetadata();

type Props = {
  searchParams?: Promise<{ q?: string; category?: string; tag?: string; page?: string }>;
};

export default async function BlogIndexPage({ searchParams }: Props) {
  const params = searchParams ? await searchParams : {};
  const q = String(params.q ?? "").trim();
  const category = String(params.category ?? "").trim();
  const tag = String(params.tag ?? "").trim();
  const page = Math.max(1, Number(params.page ?? 1) || 1);

  const [feed, categories, tags] = await Promise.all([
    getPublishedBlogFeed({ q, category, tag, page, pageSize: 6 }),
    getBlogCategories(),
    getBlogTags(),
  ]);

  const featuredPost = page === 1 ? feed.items.find((post) => post.isFeatured) ?? feed.items[0] ?? null : null;
  const listPosts = featuredPost ? feed.items.filter((post) => post.id !== featuredPost.id) : feed.items;

  const buildPageHref = (nextPage: number) => {
    const url = new URLSearchParams();
    if (q) url.set("q", q);
    if (category) url.set("category", category);
    if (tag) url.set("tag", tag);
    if (nextPage > 1) url.set("page", String(nextPage));
    const search = url.toString();
    return search ? `/blog?${search}` : "/blog";
  };

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-6xl space-y-8">
        <BlogHero categories={categories} tags={tags} q={q} category={category} tag={tag} />

        {featuredPost ? <FeaturedPostCard post={featuredPost} /> : null}

        <section className="space-y-5">
          <div className="flex flex-wrap items-end justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Latest Articles</p>
              <h2 className="mt-2 text-3xl font-semibold text-[color:var(--brand-navy)]">TMC, CSE, and bedside reasoning</h2>
            </div>
            <p className="text-sm text-slate-600">{feed.total} article{feed.total === 1 ? "" : "s"}</p>
          </div>

          {listPosts.length > 0 ? (
            <div className="grid gap-6 lg:grid-cols-2">
              {listPosts.map((post) => <BlogPostCard key={post.id} post={post} />)}
            </div>
          ) : (
            <div className="rounded-2xl border border-[color:var(--border)] bg-white p-6 text-sm text-slate-600 shadow-sm">No blog posts matched this search yet.</div>
          )}

          {feed.totalPages > 1 ? (
            <div className="flex items-center justify-between gap-3 rounded-2xl border border-[color:var(--border)] bg-white p-4 shadow-sm">
              <Link href={buildPageHref(Math.max(1, feed.page - 1))} className={`btn-secondary ${feed.page === 1 ? "pointer-events-none opacity-40" : ""}`}>Previous</Link>
              <p className="text-sm text-slate-600">Page {feed.page} of {feed.totalPages}</p>
              <Link href={buildPageHref(Math.min(feed.totalPages, feed.page + 1))} className={`btn-secondary ${feed.page === feed.totalPages ? "pointer-events-none opacity-40" : ""}`}>Next</Link>
            </div>
          ) : null}
        </section>
      </div>
    </main>
  );
}
