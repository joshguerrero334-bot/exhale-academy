import Link from "next/link";
import type { BlogPost } from "../../lib/blog/types";

type Props = { post: BlogPost; articleHtml: string };

function formatDate(value: string | null) {
  if (!value) return "Draft";
  return new Intl.DateTimeFormat("en-US", { month: "long", day: "numeric", year: "numeric" }).format(new Date(value));
}

export default function BlogArticle({ post, articleHtml }: Props) {
  return (
    <>
      <section className="rounded-[2rem] border border-[color:var(--border)] bg-white p-6 shadow-sm sm:p-8 lg:p-10">
        <div className="flex flex-wrap items-center gap-3 text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">
          <span>{post.primaryCategory?.name ?? "Exhale Academy"}</span>
          <span>{formatDate(post.publishedAt)}</span>
          <span>{post.readTimeMinutes ?? 1} min read</span>
        </div>
        <h1 className="mt-4 text-4xl font-semibold leading-tight text-[color:var(--brand-navy)] sm:text-5xl">{post.title}</h1>
        <p className="mt-4 max-w-3xl text-base leading-8 text-slate-600">{post.excerpt}</p>
        <div className="mt-6 flex flex-wrap items-center gap-3 text-sm text-slate-600">
          <span>
            By <span className="font-semibold text-[color:var(--brand-navy)]">{post.author?.displayName ?? "Exhale Academy"}</span>
          </span>
          {post.tags.length > 0 ? (
            <div className="flex flex-wrap gap-2">
              {post.tags.map((tag) => (
                <Link key={tag.id} href={`/blog/tag/${tag.slug}`} className="rounded-full bg-[color:var(--surface-soft)] px-3 py-1 text-xs font-medium text-slate-600 transition hover:text-[color:var(--brand-navy)]">
                  {tag.name}
                </Link>
              ))}
            </div>
          ) : null}
        </div>
        {post.featuredImageUrl ? (
          <div className="mt-8 overflow-hidden rounded-[1.5rem] border border-[color:var(--border)] bg-[color:var(--surface-soft)]">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={post.featuredImageUrl} alt={post.title} className="h-full w-full object-cover" />
          </div>
        ) : null}
      </section>
      <section className="rounded-[2rem] border border-[color:var(--border)] bg-white p-6 shadow-sm sm:p-8 lg:p-10">
        <div dangerouslySetInnerHTML={{ __html: articleHtml }} />
      </section>
    </>
  );
}
