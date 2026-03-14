"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { canCommentOnBlog } from "../../lib/blog/subscription-gate";
import { createAdminClient } from "../../lib/supabase/admin";
import { createClient } from "../../lib/supabase/server";

function clean(value: FormDataEntryValue | null) {
  return String(value ?? "").trim();
}

function canEditComment(createdAt: string) {
  const createdMs = new Date(createdAt).getTime();
  return Number.isFinite(createdMs) && Date.now() - createdMs <= 15 * 60 * 1000;
}

function profileName(profile: Record<string, unknown> | null, email: string | null | undefined) {
  const first = String(profile?.first_name ?? "").trim();
  const last = String(profile?.last_name ?? "").trim();
  if (first || last) return [first, last].filter(Boolean).join(" ");
  return String(email ?? "Subscriber").split("@")[0] || "Subscriber";
}

export async function createBlogComment(formData: FormData) {
  const slug = clean(formData.get("slug"));
  const postId = clean(formData.get("post_id"));
  const parentId = clean(formData.get("parent_id")) || null;
  const content = clean(formData.get("content"));

  if (!slug || !postId) redirect("/blog?error=Comment%20target%20is%20missing.");
  if (!content || content.length < 3) {
    redirect(`/blog/${slug}?error=${encodeURIComponent("Comment must be at least 3 characters.")}#comments`);
  }

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(`/login?next=${encodeURIComponent(`/blog/${slug}#comments`)}`);

  const isSubscribed = await canCommentOnBlog(supabase, user.id);
  if (!isSubscribed) {
    redirect(`/blog/${slug}?error=${encodeURIComponent("Comments are available to Exhale subscribers only.")}#comments`);
  }

  const admin = createAdminClient();
  const { data: post, error: postError } = await admin.from("blog_posts").select("id,slug,allow_comments,status").eq("id", postId).maybeSingle();
  if (postError || !post || post.status !== "published" || post.allow_comments === false) {
    redirect(`/blog/${slug}?error=${encodeURIComponent("Comments are disabled for this post.")}#comments`);
  }

  const { data: profile } = await admin.from("profiles").select("first_name,last_name,avatar_url").eq("user_id", user.id).maybeSingle();

  const { error } = await admin.from("blog_comments").insert({
    post_id: postId,
    user_id: user.id,
    parent_id: parentId,
    content,
    status: "pending",
  });
  if (error) redirect(`/blog/${slug}?error=${encodeURIComponent(error.message)}#comments`);

  revalidatePath(`/blog/${slug}`);
  redirect(`/blog/${slug}?message=${encodeURIComponent(`${profileName((profile as Record<string, unknown> | null), user.email)}, your comment was submitted for review.`)}#comments`);
}

export async function updateBlogComment(formData: FormData) {
  const slug = clean(formData.get("slug"));
  const commentId = clean(formData.get("comment_id"));
  const content = clean(formData.get("content"));

  if (!slug || !commentId || !content) {
    redirect(`/blog/${slug || ""}?error=${encodeURIComponent("Could not update comment.")}#comments`);
  }

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect(`/login?next=${encodeURIComponent(`/blog/${slug}#comments`)}`);

  const isSubscribed = await canCommentOnBlog(supabase, user.id);
  if (!isSubscribed) {
    redirect(`/blog/${slug}?error=${encodeURIComponent("Comments are available to Exhale subscribers only.")}#comments`);
  }

  const admin = createAdminClient();
  const { data: comment, error } = await admin.from("blog_comments").select("id,user_id,created_at").eq("id", commentId).maybeSingle();
  if (error || !comment || String(comment.user_id) !== user.id) {
    redirect(`/blog/${slug}?error=${encodeURIComponent("You can only edit your own comments.")}#comments`);
  }

  if (!canEditComment(String(comment.created_at))) {
    redirect(`/blog/${slug}?error=${encodeURIComponent("Editing window has expired.")}#comments`);
  }

  const { error: updateError } = await admin.from("blog_comments").update({ content, status: "pending" }).eq("id", commentId);
  if (updateError) redirect(`/blog/${slug}?error=${encodeURIComponent(updateError.message)}#comments`);

  revalidatePath(`/blog/${slug}`);
  redirect(`/blog/${slug}?message=${encodeURIComponent("Comment updated and sent for review.")}#comments`);
}
