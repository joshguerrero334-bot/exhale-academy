import type { BlogComment, ViewerBlogState } from "../../lib/blog/types";
import SubscriptionCommentGate from "./SubscriptionCommentGate";
import { CommentForm, EditCommentForm } from "./CommentForm";
import CommentList from "./CommentList";

type Props = {
  slug: string;
  postId: string;
  allowComments: boolean;
  comments: BlogComment[];
  pendingComments: BlogComment[];
  viewer: ViewerBlogState;
};

function formatDate(value: string) {
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" }).format(new Date(value));
}

function canEdit(comment: BlogComment, userId: string | null) {
  if (!userId || comment.userId !== userId) return false;
  const createdMs = new Date(comment.createdAt).getTime();
  return Number.isFinite(createdMs) && Date.now() - createdMs <= 15 * 60 * 1000;
}

export default function CommentSection({ slug, postId, allowComments, comments, pendingComments, viewer }: Props) {
  return (
    <section id="comments" className="space-y-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[color:var(--brand-navy)]">Community</p>
        <h2 className="mt-2 text-3xl font-semibold text-[color:var(--brand-navy)]">Comments</h2>
        <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-600 sm:text-base">
          Ask follow-up questions, share how you are studying, and compare reasoning with other Exhale subscribers.
        </p>
      </div>

      {!allowComments ? (
        <div className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface-soft)] p-5 text-sm text-slate-600">Comments are turned off for this post.</div>
      ) : viewer.canComment ? (
        <div className="rounded-[1.75rem] border border-[color:var(--border)] bg-white p-6 shadow-sm">
          <CommentForm slug={slug} postId={postId} />
        </div>
      ) : (
        <SubscriptionCommentGate isLoggedIn={viewer.isLoggedIn} isSubscribed={viewer.isSubscribed} slug={slug} />
      )}

      {pendingComments.length > 0 ? (
        <div className="rounded-[1.75rem] border border-amber-200 bg-amber-50 p-6">
          <h3 className="text-lg font-semibold text-[color:var(--brand-navy)]">Your pending comments</h3>
          <p className="mt-2 text-sm text-slate-600">These are waiting for review and are only visible to you right now.</p>
          <div className="mt-4 space-y-4">
            {pendingComments.map((comment) => (
              <article key={comment.id} className="rounded-2xl border border-amber-200 bg-white p-4">
                <div className="flex items-center justify-between gap-3">
                  <p className="text-sm font-semibold text-[color:var(--brand-navy)]">Submitted {formatDate(comment.createdAt)}</p>
                  <span className="rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-amber-700">{comment.status}</span>
                </div>
                <p className="mt-3 whitespace-pre-line text-sm leading-7 text-slate-700">{comment.content}</p>
                {canEdit(comment, viewer.userId) ? <EditCommentForm slug={slug} comment={comment} /> : null}
              </article>
            ))}
          </div>
        </div>
      ) : null}

      <CommentList comments={comments} slug={slug} postId={postId} viewer={viewer} />
    </section>
  );
}
