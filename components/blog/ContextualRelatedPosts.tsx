import Link from "next/link";
import type { BlogRelatedLink } from "../../lib/blog/types";

type Props = {
  heading?: string;
  items: BlogRelatedLink[];
};

export default function ContextualRelatedPosts({ heading = "Related posts", items }: Props) {
  if (items.length === 0) return null;

  return (
    <section className="space-y-5">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Keep Reading</p>
        <h2 className="mt-2 text-3xl font-semibold text-[color:var(--brand-navy)]">{heading}</h2>
      </div>
      <div className="grid gap-6 lg:grid-cols-3">
        {items.map((item) => (
          <article
            key={item.title}
            className="rounded-[1.75rem] border border-[color:var(--border)] bg-white p-6 shadow-sm"
          >
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">
              {item.available ? "Published" : "Coming Soon"}
            </p>
            <h3 className="mt-3 text-2xl font-semibold text-[color:var(--brand-navy)]">{item.title}</h3>
            <p className="mt-3 text-sm leading-7 text-slate-600 sm:text-base">{item.excerpt}</p>
            <div className="mt-5">
              {item.href ? (
                <Link href={item.href} className="btn-secondary">
                  Read Article
                </Link>
              ) : (
                <span className="inline-flex min-h-11 items-center justify-center rounded-lg border border-[color:var(--border)] bg-[color:var(--surface-soft)] px-4 py-2 text-sm font-semibold text-slate-500">
                  Draft Reference
                </span>
              )}
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}
