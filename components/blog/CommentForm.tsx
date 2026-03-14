import { createBlogComment, updateBlogComment } from "../../app/blog/actions";
import type { BlogComment } from "../../lib/blog/types";

type CreateProps = {
  slug: string;
  postId: string;
  parentId?: string | null;
  placeholder?: string;
};

type EditProps = {
  slug: string;
  comment: BlogComment;
};

export function CommentForm({ slug, postId, parentId = null, placeholder = "Add a thoughtful comment. New comments are reviewed before they appear publicly." }: CreateProps) {
  return (
    <form action={createBlogComment} className="space-y-3">
      <input type="hidden" name="slug" value={slug} />
      <input type="hidden" name="post_id" value={postId} />
      <input type="hidden" name="parent_id" value={parentId ?? ""} />
      <textarea
        name="content"
        rows={parentId ? 4 : 5}
        required
        className="w-full rounded-2xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm text-[color:var(--brand-navy)] outline-none transition focus:border-[color:var(--brand-gold)]"
        placeholder={placeholder}
      />
      <button type="submit" className="btn-primary">{parentId ? "Submit Reply" : "Submit Comment"}</button>
    </form>
  );
}

export function EditCommentForm({ slug, comment }: EditProps) {
  return (
    <form action={updateBlogComment} className="mt-4 space-y-3">
      <input type="hidden" name="slug" value={slug} />
      <input type="hidden" name="comment_id" value={comment.id} />
      <textarea
        name="content"
        rows={4}
        required
        defaultValue={comment.content}
        className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm text-[color:var(--brand-navy)] outline-none transition focus:border-[color:var(--brand-gold)]"
      />
      <button type="submit" className="btn-secondary">Save Changes</button>
    </form>
  );
}
