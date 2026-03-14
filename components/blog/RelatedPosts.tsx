import type { BlogPost } from "../../lib/blog/types";
import BlogPostCard from "./BlogPostCard";

type Props = { posts: BlogPost[] };

export default function RelatedPosts({ posts }: Props) {
  if (posts.length === 0) return null;
  return (
    <section className="space-y-5">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Keep Reading</p>
        <h2 className="mt-2 text-3xl font-semibold text-[color:var(--brand-navy)]">Related posts</h2>
      </div>
      <div className="grid gap-6 lg:grid-cols-3">
        {posts.map((post) => <BlogPostCard key={post.id} post={post} />)}
      </div>
    </section>
  );
}
