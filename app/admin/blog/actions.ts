"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { isAdminUser } from "../../../lib/auth/admin";
import { buildPostPayload, cleanField, ensureUniquePostSlug, syncPrimaryCategory, syncTags } from "../../../lib/blog/mutations";
import { slugify } from "../../../lib/blog/slug";
import { createAdminClient } from "../../../lib/supabase/admin";
import { createClient } from "../../../lib/supabase/server";

function extensionFromMime(mimeType: string) {
  switch (mimeType) {
    case "image/jpeg":
      return "jpg";
    case "image/png":
      return "png";
    case "image/webp":
      return "webp";
    default:
      return null;
  }
}

async function requireAdminIdentity() {
  const supabase = await createClient();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    redirect("/login?next=%2Fadmin%2Fblog");
  }

  if (!isAdminUser({ id: user.id, email: user.email ?? null })) {
    redirect("/dashboard?error=Admin%20access%20only");
  }

  return user;
}

function revalidateBlogPaths(slug?: string) {
  revalidatePath("/blog");
  revalidatePath("/admin/blog");
  revalidatePath("/admin/blog/comments");
  revalidatePath("/admin/blog/categories");
  revalidatePath("/admin/blog/tags");
  revalidatePath("/sitemap.xml");
  if (slug) revalidatePath(`/blog/${slug}`);
}

export async function saveBlogPost(formData: FormData) {
  const user = await requireAdminIdentity();
  const admin = createAdminClient();

  const postId = cleanField(formData.get("id"));
  const title = cleanField(formData.get("title"));
  const content = cleanField(formData.get("content"));
  const authorId = cleanField(formData.get("author_id")) || user.id;
  const slugBase = slugify(cleanField(formData.get("slug")) || title);
  const categoryId = cleanField(formData.get("category_id")) || null;
  const tags = cleanField(formData.get("tags"));

  if (!title || !content) {
    redirect(`${postId ? `/admin/blog/${postId}/edit` : "/admin/blog/new"}?error=${encodeURIComponent("Title and content are required.")}`);
  }

  const slug = await ensureUniquePostSlug(slugBase, postId || undefined);
  const payload = { ...buildPostPayload(formData, slug), author_id: authorId };

  let savedId = postId;
  if (postId) {
    const { error } = await admin.from("blog_posts").update(payload).eq("id", postId);
    if (error) {
      redirect(`/admin/blog/${postId}/edit?error=${encodeURIComponent(error.message)}`);
    }
  } else {
    const { data, error } = await admin.from("blog_posts").insert(payload).select("id").single();
    if (error) {
      redirect(`/admin/blog/new?error=${encodeURIComponent(error.message)}`);
    }
    savedId = String(data.id);
  }

  await syncPrimaryCategory(savedId, categoryId);
  await syncTags(savedId, tags);

  revalidateBlogPaths(slug);
  redirect(`/admin/blog/${savedId}/edit?message=${encodeURIComponent("Post saved.")}`);
}

export async function deleteBlogPost(formData: FormData) {
  await requireAdminIdentity();
  const admin = createAdminClient();
  const postId = cleanField(formData.get("post_id"));
  if (!postId) redirect("/admin/blog?error=Missing%20post%20id.");

  const { data: row } = await admin.from("blog_posts").select("slug").eq("id", postId).maybeSingle();
  const { error } = await admin.from("blog_posts").delete().eq("id", postId);
  if (error) redirect(`/admin/blog?error=${encodeURIComponent(error.message)}`);

  revalidateBlogPaths(String(row?.slug ?? ""));
  redirect("/admin/blog?message=Post%20deleted.");
}

export async function moderateBlogComment(formData: FormData) {
  await requireAdminIdentity();
  const admin = createAdminClient();
  const commentId = cleanField(formData.get("comment_id"));
  const status = cleanField(formData.get("status"));
  if (!commentId || !["pending", "approved", "hidden", "rejected"].includes(status)) {
    redirect("/admin/blog/comments?error=Invalid%20comment%20moderation%20request.");
  }

  const { error } = await admin.from("blog_comments").update({ status }).eq("id", commentId);
  if (error) {
    redirect(`/admin/blog/comments?error=${encodeURIComponent(error.message)}`);
  }

  revalidateBlogPaths();
  redirect(`/admin/blog/comments?message=${encodeURIComponent(`Comment marked ${status}.`)}`);
}

export async function saveBlogCategory(formData: FormData) {
  await requireAdminIdentity();
  const admin = createAdminClient();
  const id = cleanField(formData.get("id"));
  const name = cleanField(formData.get("name"));
  const slug = slugify(cleanField(formData.get("slug")) || name);
  const description = cleanField(formData.get("description")) || null;
  if (!name || !slug) {
    redirect("/admin/blog/categories?error=Category%20name%20is%20required.");
  }

  const payload = { name, slug, description };
  const query = id ? admin.from("blog_categories").update(payload).eq("id", id) : admin.from("blog_categories").insert(payload);
  const { error } = await query;
  if (error) redirect(`/admin/blog/categories?error=${encodeURIComponent(error.message)}`);

  revalidateBlogPaths();
  redirect("/admin/blog/categories?message=Category%20saved.");
}

export async function deleteBlogCategory(formData: FormData) {
  await requireAdminIdentity();
  const admin = createAdminClient();
  const id = cleanField(formData.get("id"));
  if (!id) redirect("/admin/blog/categories?error=Missing%20category%20id.");
  const { error } = await admin.from("blog_categories").delete().eq("id", id);
  if (error) redirect(`/admin/blog/categories?error=${encodeURIComponent(error.message)}`);
  revalidateBlogPaths();
  redirect("/admin/blog/categories?message=Category%20deleted.");
}

export async function saveBlogTag(formData: FormData) {
  await requireAdminIdentity();
  const admin = createAdminClient();
  const id = cleanField(formData.get("id"));
  const name = cleanField(formData.get("name"));
  const slug = slugify(cleanField(formData.get("slug")) || name);
  if (!name || !slug) redirect("/admin/blog/tags?error=Tag%20name%20is%20required.");

  const payload = { name, slug };
  const query = id ? admin.from("blog_tags").update(payload).eq("id", id) : admin.from("blog_tags").insert(payload);
  const { error } = await query;
  if (error) redirect(`/admin/blog/tags?error=${encodeURIComponent(error.message)}`);

  revalidateBlogPaths();
  redirect("/admin/blog/tags?message=Tag%20saved.");
}

export async function deleteBlogTag(formData: FormData) {
  await requireAdminIdentity();
  const admin = createAdminClient();
  const id = cleanField(formData.get("id"));
  if (!id) redirect("/admin/blog/tags?error=Missing%20tag%20id.");
  const { error } = await admin.from("blog_tags").delete().eq("id", id);
  if (error) redirect(`/admin/blog/tags?error=${encodeURIComponent(error.message)}`);
  revalidateBlogPaths();
  redirect("/admin/blog/tags?message=Tag%20deleted.");
}

export async function uploadBlogFeaturedImage(formData: FormData) {
  await requireAdminIdentity();
  const file = formData.get("featured_image");
  const redirectTo = cleanField(formData.get("redirect_to")) || "/admin/blog/new";

  if (!(file instanceof File) || file.size <= 0) {
    redirect(`${redirectTo}?error=${encodeURIComponent("Please choose an image to upload.")}`);
  }

  const allowedTypes = new Set(["image/jpeg", "image/png", "image/webp"]);
  if (!allowedTypes.has(file.type)) {
    redirect(`${redirectTo}?error=${encodeURIComponent("Only JPG, PNG, or WEBP images are allowed.")}`);
  }

  const ext = extensionFromMime(file.type);
  if (!ext) redirect(`${redirectTo}?error=${encodeURIComponent("Unsupported image type.")}`);

  const admin = createAdminClient();
  const filePath = `featured/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`;
  const { error: uploadError } = await admin.storage.from("blog-images").upload(filePath, file, {
    upsert: true,
    contentType: file.type,
  });
  if (uploadError) redirect(`${redirectTo}?error=${encodeURIComponent(uploadError.message)}`);

  const { data } = admin.storage.from("blog-images").getPublicUrl(filePath);
  const publicUrl = String(data.publicUrl ?? "").trim();
  if (!publicUrl) redirect(`${redirectTo}?error=${encodeURIComponent("Could not build image URL.")}`);

  redirect(`${redirectTo}?uploaded=${encodeURIComponent(publicUrl)}&message=${encodeURIComponent("Featured image uploaded.")}`);
}
