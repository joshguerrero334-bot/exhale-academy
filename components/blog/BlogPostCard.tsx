import Link from "next/link";
import type { BlogPost } from "../../lib/blog/types";

function formatDate(value: string | null) {
  if (!value) return "Draft";
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric" }).format(new Date(value));
}

type Props = { post: BlogPost };

export default function BlogPostCard({ post }: Props) {
  return (
    <article className="group overflow-hidden rounded-[1.75rem] border border-[color:var(--border)] bg-white shadow-sm transition hover:-translate-y-0.5 hover:border-[color:var(--brand-gold)]/60 hover:shadow-md">
      <Link href={`/blog/${post.slug}`} className="block">
        <div className="aspect-[16/9] w-full bg-[color:var(--surface-soft)]">
          {post.featuredImageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={post.featuredImageUrl} alt={post.title} className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full items-center justify-center bg-[linear-gradient(135deg,rgba(113,201,194,0.18),rgba(38,39,43,0.04))] px-6 text-center text-sm font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-navy)]/70">
              Exhale Academy Blog
            </div>
          )}
        </div>
      </Link>
      <div className="space-y-4 p-6">
        <div className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">
          {post.primaryCategory ? <span>{post.primaryCategory.name}</span> : null}
          <span>{formatDate(post.publishedAt)}</span>
          <span>{post.readTimeMinutes ?? 1} min read</span>
        </div>
        <Link href={`/blog/${post.slug}`} className="block">
          <h3 className="text-2xl font-semibold text-[color:var(--brand-navy)] transition group-hover:text-[color:var(--brand-gold)]">{post.title}</h3>
        </Link>
        <p className="text-sm leading-7 text-slate-600 sm:text-base">{post.excerpt}</p>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-sm text-slate-600">
            By <span className="font-semibold text-[color:var(--brand-navy)]">{post.author?.displayName ?? "Exhale Academy"}</span>
          </p>
          <div className="flex flex-wrap gap-2">
            {post.tags.slice(0, 3).map((tag) => (
              <Link key={tag.id} href={`/blog/tag/${tag.slug}`} className="rounded-full bg-[color:var(--surface-soft)] px-3 py-1 text-xs font-medium text-slate-600 transition hover:text-[color:var(--brand-navy)]">
                {tag.name}
              </Link>
            ))}
          </div>
        </div>
      </div>
    </article>
  );
}
