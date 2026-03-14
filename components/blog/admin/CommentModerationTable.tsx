import { moderateBlogComment } from "../../../app/admin/blog/actions";
import CommentStatusBadge from "./CommentStatusBadge";

type AdminComment = {
  id: string;
  postTitle: string;
  postSlug: string;
  authorName: string;
  content: string;
  status: "pending" | "approved" | "hidden" | "rejected";
  createdAt: string;
};

function formatDate(value: string) {
  return new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" }).format(new Date(value));
}

export default function CommentModerationTable({ comments }: { comments: AdminComment[] }) {
  return (
    <div className="space-y-4">
      {comments.map((comment) => (
        <article key={comment.id} className="rounded-xl border border-[color:var(--cool-gray)] bg-white p-4">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div>
              <div className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">
                <CommentStatusBadge status={comment.status} />
                <span>{formatDate(comment.createdAt)}</span>
                <span>{comment.postTitle}</span>
              </div>
              <p className="mt-2 text-sm font-semibold text-[color:var(--brand-navy)]">{comment.authorName}</p>
              <p className="mt-2 whitespace-pre-line text-sm text-slate-600">{comment.content}</p>
            </div>
            <div className="flex flex-wrap gap-2">
              {(["approved", "hidden", "rejected"] as const).map((status) => (
                <form key={status} action={moderateBlogComment}>
                  <input type="hidden" name="comment_id" value={comment.id} />
                  <input type="hidden" name="status" value={status} />
                  <button type="submit" className="btn-secondary">{status}</button>
                </form>
              ))}
            </div>
          </div>
        </article>
      ))}
    </div>
  );
}
