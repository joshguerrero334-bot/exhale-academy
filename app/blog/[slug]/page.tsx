import type { Metadata } from "next";
import { notFound } from "next/navigation";
import BlogArticle from "../../../components/blog/BlogArticle";
import BlogCTA from "../../../components/blog/BlogCTA";
import BlogTableOfContents from "../../../components/blog/BlogTableOfContents";
import ContextualRelatedPosts from "../../../components/blog/ContextualRelatedPosts";
import RelatedPosts from "../../../components/blog/RelatedPosts";
import CommentSection from "../../../components/blog/CommentSection";
import { buildBlogPostMetadata } from "../../../lib/blog/metadata";
import { getApprovedCommentsForPost, getContextualRelatedLinks, getPublishedBlogPostBySlug, getRelatedBlogPosts, getViewerPendingComments } from "../../../lib/blog/queries";
import { buildBlogPostingStructuredData } from "../../../lib/blog/structured-data";
import { extractTableOfContents, renderMarkdown } from "../../../lib/blog/markdown";
import { createClient } from "../../../lib/supabase/server";
import { canCommentOnBlog } from "../../../lib/blog/subscription-gate";

export const dynamic = "force-dynamic";

type Props = {
  params: Promise<{ slug: string }>;
  searchParams?: Promise<{ message?: string; error?: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPublishedBlogPostBySlug(slug);
  if (!post) return { title: "Article Not Found | Exhale Academy Blog" };
  return buildBlogPostMetadata(post);
}

export default async function BlogPostPage({ params, searchParams }: Props) {
  const [{ slug }, query] = await Promise.all([
    params,
    searchParams ? searchParams : Promise.resolve<{ message?: string; error?: string }>({}),
  ]);

  const post = await getPublishedBlogPostBySlug(slug);
  if (!post) notFound();

  const [comments, relatedPosts, contextualRelatedLinks, supabase] = await Promise.all([
    getApprovedCommentsForPost(post.id),
    getRelatedBlogPosts(post, 3),
    getContextualRelatedLinks(post),
    createClient(),
  ]);

  const { data: { user } } = await supabase.auth.getUser();
  const isSubscribed = user ? await canCommentOnBlog(supabase, user.id) : false;
  const pendingComments = user ? await getViewerPendingComments(post.id, user.id) : [];
  const articleHtml = renderMarkdown(post.content);
  const tableOfContents = extractTableOfContents(post.content);
  const structuredData = buildBlogPostingStructuredData(post);

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-6xl space-y-8">
        <article className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_280px] lg:items-start">
          <div className="space-y-8">
            <BlogArticle post={post} articleHtml={articleHtml} />

            {query.message ? <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-700">{query.message}</div> : null}
            {query.error ? <div className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">{query.error}</div> : null}

            <BlogCTA />
            <ContextualRelatedPosts items={contextualRelatedLinks} />
            <RelatedPosts posts={relatedPosts} />
            <CommentSection
              slug={post.slug}
              postId={post.id}
              allowComments={post.allowComments}
              comments={comments}
              pendingComments={pendingComments}
              viewer={{
                isLoggedIn: Boolean(user),
                isSubscribed,
                canComment: Boolean(user && isSubscribed),
                userId: user?.id ?? null,
              }}
            />
          </div>

          <aside className="space-y-5 lg:sticky lg:top-[92px]">
            <div className="rounded-[1.5rem] border border-[color:var(--border)] bg-white p-5 shadow-sm">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-navy)]">Article Snapshot</p>
              <dl className="mt-4 space-y-3 text-sm text-slate-600">
                <div>
                  <dt className="font-semibold text-[color:var(--brand-navy)]">Author</dt>
                  <dd>{post.author?.displayName ?? "Exhale Academy"}</dd>
                </div>
                <div>
                  <dt className="font-semibold text-[color:var(--brand-navy)]">Published</dt>
                  <dd>{post.publishedAt ? new Intl.DateTimeFormat("en-US", { month: "long", day: "numeric", year: "numeric" }).format(new Date(post.publishedAt)) : "Draft"}</dd>
                </div>
                <div>
                  <dt className="font-semibold text-[color:var(--brand-navy)]">Read time</dt>
                  <dd>{post.readTimeMinutes ?? 1} minutes</dd>
                </div>
              </dl>
            </div>
            <BlogTableOfContents items={tableOfContents} />
          </aside>
        </article>
      </div>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }} />
    </main>
  );
}
