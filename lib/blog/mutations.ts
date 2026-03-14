import { createAdminClient } from "../supabase/admin";
import { generateExcerpt } from "./excerpt";
import { estimateReadTime } from "./read-time";
import { slugify } from "./slug";

function clean(value: FormDataEntryValue | null) {
  return String(value ?? "").trim();
}

export function boolFromForm(formData: FormData, key: string) {
  return formData.get(key) === "on";
}

export function cleanField(value: FormDataEntryValue | null) {
  return clean(value);
}

export async function ensureUniquePostSlug(baseSlug: string, postId?: string) {
  const admin = createAdminClient();
  let candidate = baseSlug || `post-${Date.now()}`;
  let counter = 1;

  while (true) {
    let query = admin.from("blog_posts").select("id").eq("slug", candidate);
    if (postId) query = query.neq("id", postId);
    const { data, error } = await query.maybeSingle();
    if (error && !error.message.toLowerCase().includes("no rows")) {
      throw new Error(error.message);
    }
    if (!data) return candidate;
    counter += 1;
    candidate = `${baseSlug}-${counter}`;
  }
}

export async function syncPrimaryCategory(postId: string, categoryId: string | null) {
  const admin = createAdminClient();
  const { error: deleteError } = await admin.from("blog_post_categories").delete().eq("post_id", postId);
  if (deleteError) throw new Error(deleteError.message);
  if (!categoryId) return;
  const { error: insertError } = await admin.from("blog_post_categories").insert({ post_id: postId, category_id: categoryId });
  if (insertError) throw new Error(insertError.message);
}

export async function syncTags(postId: string, tagsValue: string) {
  const admin = createAdminClient();
  const tags = Array.from(new Set(tagsValue.split(",").map((entry) => entry.trim()).filter(Boolean)));
  const tagRows = tags.map((name) => ({ name, slug: slugify(name) })).filter((entry) => entry.slug);

  if (tagRows.length > 0) {
    const { error } = await admin.from("blog_tags").upsert(tagRows, { onConflict: "slug" });
    if (error) throw new Error(error.message);
  }

  const { data: allTags, error: tagsError } = await admin.from("blog_tags").select("id, slug");
  if (tagsError) throw new Error(tagsError.message);

  const selectedIds = (allTags ?? [])
    .filter((row) => tagRows.some((entry) => entry.slug === String(row.slug ?? "")))
    .map((row) => String(row.id));

  const { error: deleteError } = await admin.from("blog_post_tags").delete().eq("post_id", postId);
  if (deleteError) throw new Error(deleteError.message);

  if (selectedIds.length > 0) {
    const { error: insertError } = await admin.from("blog_post_tags").insert(selectedIds.map((tagId) => ({ post_id: postId, tag_id: tagId })));
    if (insertError) throw new Error(insertError.message);
  }
}

export function buildPostPayload(formData: FormData, slug: string) {
  const content = clean(formData.get("content"));
  const excerpt = clean(formData.get("excerpt")) || generateExcerpt(content);
  const status = ["draft", "published", "archived"].includes(clean(formData.get("status")))
    ? clean(formData.get("status"))
    : "draft";

  return {
    title: clean(formData.get("title")),
    slug,
    excerpt,
    content,
    featured_image_url: clean(formData.get("featured_image_url")) || null,
    author_id: clean(formData.get("author_id")) || null,
    status,
    published_at: status === "published" ? clean(formData.get("published_at")) || new Date().toISOString() : null,
    seo_title: clean(formData.get("seo_title")) || null,
    seo_description: clean(formData.get("seo_description")) || null,
    canonical_url: clean(formData.get("canonical_url")) || null,
    is_featured: boolFromForm(formData, "is_featured"),
    allow_comments: boolFromForm(formData, "allow_comments"),
    read_time_minutes: estimateReadTime(content),
  };
}
