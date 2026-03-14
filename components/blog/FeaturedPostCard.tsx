import Link from "next/link";
import type { BlogPost } from "../../lib/blog/types";

type Props = { post: BlogPost };

export default function FeaturedPostCard({ post }: Props) {
  return (
    <section className="overflow-hidden rounded-[2rem] border border-[color:var(--border)] bg-white shadow-sm">
      <div className="grid gap-0 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="aspect-[16/10] bg-[color:var(--surface-soft)] lg:aspect-auto">
          {post.featuredImageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={post.featuredImageUrl} alt={post.title} className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full items-center justify-center bg-[linear-gradient(135deg,rgba(113,201,194,0.18),rgba(38,39,43,0.04))] px-6 text-center text-sm font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-navy)]/70">
              Featured Article
            </div>
          )}
        </div>
        <div className="p-6 sm:p-8 lg:p-10">
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[color:var(--brand-gold)]">Featured Post</p>
          <h2 className="mt-3 text-3xl font-semibold text-[color:var(--brand-navy)] sm:text-4xl">{post.title}</h2>
          <p className="mt-4 text-sm leading-8 text-slate-600 sm:text-base">{post.excerpt}</p>
          <div className="mt-5 flex flex-wrap gap-3 text-sm text-slate-600">
            <span>{post.author?.displayName ?? "Exhale Academy"}</span>
            <span>{post.primaryCategory?.name ?? "General"}</span>
            <span>{post.readTimeMinutes ?? 1} min read</span>
          </div>
          <Link href={`/blog/${post.slug}`} className="btn-primary mt-7">
            Read Article
          </Link>
        </div>
      </div>
    </section>
  );
}
