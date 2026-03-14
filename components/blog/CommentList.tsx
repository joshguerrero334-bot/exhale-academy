import type { BlogComment, ViewerBlogState } from "../../lib/blog/types";
import { CommentForm, EditCommentForm } from "./CommentForm";

function formatDate(value: string) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(value));
}

function canEdit(comment: BlogComment, userId: string | null) {
  if (!userId || comment.userId !== userId) return false;
  const createdMs = new Date(comment.createdAt).getTime();
  return Number.isFinite(createdMs) && Date.now() - createdMs <= 15 * 60 * 1000;
}

type Props = {
  comments: BlogComment[];
  slug: string;
  postId: string;
  viewer: ViewerBlogState;
  level?: number;
};

export default function CommentList({ comments, slug, postId, viewer, level = 0 }: Props) {
  if (comments.length === 0) {
    return <div className="rounded-2xl border border-[color:var(--border)] bg-white p-6 text-sm text-slate-600 shadow-sm">No approved comments yet. Start the discussion.</div>;
  }

  return (
    <div className="space-y-4">
      {comments.map((comment) => (
        <article key={comment.id} className={`rounded-2xl border border-[color:var(--border)] bg-white p-5 shadow-sm ${level > 0 ? "ml-0 sm:ml-8" : ""}`}>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="font-semibold text-[color:var(--brand-navy)]">{comment.authorName}</p>
              <p className="text-xs uppercase tracking-[0.14em] text-slate-500">{formatDate(comment.createdAt)}</p>
            </div>
            <span className="rounded-full bg-[color:var(--surface-soft)] px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Approved</span>
          </div>
          <p className="mt-4 whitespace-pre-line text-sm leading-7 text-slate-700 sm:text-base">{comment.content}</p>

          <div className="mt-4 space-y-3">
            {viewer.canComment ? (
              <details className="rounded-xl border border-[color:var(--border)] bg-[color:var(--surface-soft)] p-4">
                <summary className="cursor-pointer text-sm font-semibold text-[color:var(--brand-navy)]">Reply</summary>
                <div className="mt-4">
                  <CommentForm slug={slug} postId={postId} parentId={comment.id} placeholder="Add a reply" />
                </div>
              </details>
            ) : null}

            {canEdit(comment, viewer.userId) ? (
              <details className="rounded-xl border border-[color:var(--border)] bg-[color:var(--surface-soft)] p-4">
                <summary className="cursor-pointer text-sm font-semibold text-[color:var(--brand-navy)]">Edit comment</summary>
                <EditCommentForm slug={slug} comment={comment} />
              </details>
            ) : null}
          </div>

          {comment.replies.length > 0 ? <div className="mt-5"><CommentList comments={comment.replies} slug={slug} postId={postId} viewer={viewer} level={level + 1} /></div> : null}
        </article>
      ))}
    </div>
  );
}
