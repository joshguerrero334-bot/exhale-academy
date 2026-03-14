import type { BlogCommentStatus } from "../../../lib/blog/types";

const STYLES: Record<BlogCommentStatus, string> = {
  approved: "bg-emerald-100 text-emerald-700",
  pending: "bg-amber-100 text-amber-700",
  hidden: "bg-slate-200 text-slate-700",
  rejected: "bg-red-100 text-red-700",
};

export default function CommentStatusBadge({ status }: { status: BlogCommentStatus }) {
  return <span className={`rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-[0.14em] ${STYLES[status]}`}>{status}</span>;
}
