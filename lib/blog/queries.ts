import { createAdminClient } from "../supabase/admin";
import { generateExcerpt } from "./excerpt";
import { estimateReadTime } from "./read-time";
import type { BlogAuthor, BlogCategory, BlogComment, BlogFeedFilters, BlogPost, BlogTag, PaginatedBlogPosts } from "./types";

type RawRecord = Record<string, unknown>;

function asRecord(value: unknown): RawRecord | null {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return value as RawRecord;
  }
  return null;
}

function asRecordArray(value: unknown) {
  return Array.isArray(value) ? value.map((entry) => asRecord(entry)).filter(Boolean) as RawRecord[] : [];
}

function buildCommentTree(comments: BlogComment[]) {
  const byId = new Map<string, BlogComment>();
  const roots: BlogComment[] = [];

  for (const comment of comments) {
    byId.set(comment.id, { ...comment, replies: [] });
  }

  for (const comment of byId.values()) {
    if (comment.parentId && byId.has(comment.parentId)) {
      byId.get(comment.parentId)!.replies.push(comment);
    } else {
      roots.push(comment);
    }
  }

  return roots;
}

async function getProfileMap(userIds: string[]) {
  const ids = Array.from(new Set(userIds.filter(Boolean)));
  if (ids.length === 0) return new Map<string, BlogAuthor>();

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("profiles")
    .select("id, first_name, last_name, avatar_url")
    .in("id", ids);

  if (error) throw new Error(error.message);

  const map = new Map<string, BlogAuthor>();
  for (const row of asRecordArray(data)) {
    const userId = String(row.id ?? "");
    const first = String(row.first_name ?? "").trim();
    const last = String(row.last_name ?? "").trim();
    const displayName = [first, last].filter(Boolean).join(" ") || "Exhale Academy";
    map.set(userId, {
      id: userId,
      displayName,
      avatarUrl: row.avatar_url ? String(row.avatar_url) : null,
    });
  }
  return map;
}

function mapCategory(record: RawRecord): BlogCategory {
  return {
    id: String(record.id ?? ""),
    name: String(record.name ?? ""),
    slug: String(record.slug ?? ""),
    description: record.description ? String(record.description) : null,
  };
}

function mapTag(record: RawRecord): BlogTag {
  return {
    id: String(record.id ?? ""),
    name: String(record.name ?? ""),
    slug: String(record.slug ?? ""),
  };
}

async function getPrimaryCategoryMap(postIds: string[]) {
  const ids = Array.from(new Set(postIds.filter(Boolean)));
  if (ids.length === 0) return new Map<string, BlogCategory>();

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_post_categories")
    .select("post_id, blog_categories(id, name, slug, description)")
    .in("post_id", ids);

  if (error) throw new Error(error.message);

  const map = new Map<string, BlogCategory>();
  for (const row of asRecordArray(data)) {
    const category = asRecord(row.blog_categories);
    if (!category) continue;
    map.set(String(row.post_id ?? ""), mapCategory(category));
  }
  return map;
}

async function getTagMapByPost(postIds: string[]) {
  const ids = Array.from(new Set(postIds.filter(Boolean)));
  if (ids.length === 0) return new Map<string, BlogTag[]>();

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_post_tags")
    .select("post_id, blog_tags(id, name, slug)")
    .in("post_id", ids);

  if (error) throw new Error(error.message);

  const map = new Map<string, BlogTag[]>();
  for (const row of asRecordArray(data)) {
    const postId = String(row.post_id ?? "");
    const tag = asRecord(row.blog_tags);
    if (!tag) continue;
    const list = map.get(postId) ?? [];
    list.push(mapTag(tag));
    map.set(postId, list);
  }
  return map;
}

async function mapPosts(rows: RawRecord[]) {
  const authorMap = await getProfileMap(rows.map((row) => String(row.author_id ?? "")).filter(Boolean));
  const categoryMap = await getPrimaryCategoryMap(rows.map((row) => String(row.id ?? "")));
  const tagMap = await getTagMapByPost(rows.map((row) => String(row.id ?? "")));

  return rows.map((row) => {
    const id = String(row.id ?? "");
    const content = String(row.content ?? "");
    const excerpt = String(row.excerpt ?? "").trim() || generateExcerpt(content);
    return {
      id,
      title: String(row.title ?? ""),
      slug: String(row.slug ?? ""),
      excerpt,
      content,
      featuredImageUrl: row.featured_image_url ? String(row.featured_image_url) : null,
      author: authorMap.get(String(row.author_id ?? "")) ?? null,
      status: String(row.status ?? "draft") as BlogPost["status"],
      publishedAt: row.published_at ? String(row.published_at) : null,
      seoTitle: row.seo_title ? String(row.seo_title) : null,
      seoDescription: row.seo_description ? String(row.seo_description) : null,
      canonicalUrl: row.canonical_url ? String(row.canonical_url) : null,
      isFeatured: row.is_featured === true,
      allowComments: row.allow_comments !== false,
      readTimeMinutes:
        typeof row.read_time_minutes === "number" && Number.isFinite(row.read_time_minutes)
          ? Number(row.read_time_minutes)
          : estimateReadTime(content),
      primaryCategory: categoryMap.get(id) ?? null,
      tags: tagMap.get(id) ?? [],
      createdAt: String(row.created_at ?? ""),
      updatedAt: String(row.updated_at ?? ""),
    } satisfies BlogPost;
  });
}

function applyPostFilters(posts: BlogPost[], filters: BlogFeedFilters) {
  const q = String(filters.q ?? "").trim().toLowerCase();
  const category = String(filters.category ?? "").trim().toLowerCase();
  const tag = String(filters.tag ?? "").trim().toLowerCase();

  return posts.filter((post) => {
    const matchesSearch =
      !q ||
      post.title.toLowerCase().includes(q) ||
      post.excerpt.toLowerCase().includes(q) ||
      post.content.toLowerCase().includes(q) ||
      post.tags.some((entry) => entry.name.toLowerCase().includes(q));
    const matchesCategory = !category || post.primaryCategory?.slug === category;
    const matchesTag = !tag || post.tags.some((entry) => entry.slug === tag);
    return matchesSearch && matchesCategory && matchesTag;
  });
}

function paginatePosts(posts: BlogPost[], page: number, pageSize: number): PaginatedBlogPosts {
  const total = posts.length;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const safePage = Math.min(Math.max(1, page), totalPages);
  const start = (safePage - 1) * pageSize;
  return {
    items: posts.slice(start, start + pageSize),
    total,
    page: safePage,
    pageSize,
    totalPages,
  };
}

export async function getPublishedBlogFeed(filters: BlogFeedFilters = {}): Promise<PaginatedBlogPosts> {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_posts")
    .select("id, title, slug, excerpt, content, featured_image_url, author_id, status, published_at, seo_title, seo_description, canonical_url, is_featured, allow_comments, read_time_minutes, created_at, updated_at")
    .eq("status", "published")
    .order("is_featured", { ascending: false })
    .order("published_at", { ascending: false });

  if (error) throw new Error(error.message);

  const mapped = await mapPosts(asRecordArray(data));
  const filtered = applyPostFilters(mapped, filters);
  return paginatePosts(filtered, filters.page ?? 1, filters.pageSize ?? 6);
}

export async function getPublishedBlogPostBySlug(slug: string) {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_posts")
    .select("id, title, slug, excerpt, content, featured_image_url, author_id, status, published_at, seo_title, seo_description, canonical_url, is_featured, allow_comments, read_time_minutes, created_at, updated_at")
    .eq("slug", slug)
    .eq("status", "published")
    .maybeSingle();

  if (error) throw new Error(error.message);
  const row = asRecord(data);
  if (!row) return null;
  const posts = await mapPosts([row]);
  return posts[0] ?? null;
}

export async function getAdminBlogPostById(id: string) {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_posts")
    .select("id, title, slug, excerpt, content, featured_image_url, author_id, status, published_at, seo_title, seo_description, canonical_url, is_featured, allow_comments, read_time_minutes, created_at, updated_at")
    .eq("id", id)
    .maybeSingle();

  if (error) throw new Error(error.message);
  const row = asRecord(data);
  if (!row) return null;
  const posts = await mapPosts([row]);
  return posts[0] ?? null;
}

export async function getAdminBlogPosts() {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_posts")
    .select("id, title, slug, excerpt, content, featured_image_url, author_id, status, published_at, seo_title, seo_description, canonical_url, is_featured, allow_comments, read_time_minutes, created_at, updated_at")
    .order("updated_at", { ascending: false });

  if (error) throw new Error(error.message);
  return mapPosts(asRecordArray(data));
}

export async function getBlogCategories() {
  const admin = createAdminClient();
  const { data, error } = await admin.from("blog_categories").select("id, name, slug, description, updated_at").order("name", { ascending: true });
  if (error) throw new Error(error.message);

  const rows = asRecordArray(data).map((row) => mapCategory(row));
  const feed = await getPublishedBlogFeed({ pageSize: 1000 });
  return rows.map((category) => ({
    ...category,
    postCount: feed.items.filter((post) => post.primaryCategory?.id === category.id).length,
  }));
}

export async function getBlogTags() {
  const admin = createAdminClient();
  const { data, error } = await admin.from("blog_tags").select("id, name, slug, updated_at").order("name", { ascending: true });
  if (error) throw new Error(error.message);

  const rows = asRecordArray(data).map((row) => mapTag(row));
  const feed = await getPublishedBlogFeed({ pageSize: 1000 });
  return rows.map((tag) => ({
    ...tag,
    postCount: feed.items.filter((post) => post.tags.some((entry) => entry.id === tag.id)).length,
  }));
}

export async function getBlogCategoryBySlug(slug: string) {
  const items = await getBlogCategories();
  return items.find((entry) => entry.slug === slug) ?? null;
}

export async function getBlogTagBySlug(slug: string) {
  const items = await getBlogTags();
  return items.find((entry) => entry.slug === slug) ?? null;
}

export async function getRelatedBlogPosts(post: BlogPost, limit = 3) {
  const feed = await getPublishedBlogFeed({ pageSize: 1000 });
  const sameCategory = feed.items.filter((entry) => entry.id !== post.id && entry.primaryCategory?.id === post.primaryCategory?.id);
  if (sameCategory.length >= limit) return sameCategory.slice(0, limit);

  const fallback = feed.items.filter(
    (entry) => entry.id !== post.id && entry.tags.some((tag) => post.tags.some((postTag) => postTag.id === tag.id))
  );

  const merged = [...sameCategory, ...fallback.filter((entry) => !sameCategory.some((existing) => existing.id === entry.id))];
  return merged.slice(0, limit);
}

export async function getPublishedBlogPostSlugs() {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_posts")
    .select("slug, updated_at")
    .eq("status", "published")
    .order("published_at", { ascending: false });
  if (error) throw new Error(error.message);
  return asRecordArray(data).map((row) => ({ slug: String(row.slug ?? ""), updatedAt: String(row.updated_at ?? "") }));
}

export async function getApprovedCommentsForPost(postId: string) {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_comments")
    .select("id, post_id, user_id, parent_id, content, status, created_at, updated_at")
    .eq("post_id", postId)
    .eq("status", "approved")
    .order("created_at", { ascending: true });
  if (error) throw new Error(error.message);

  const rows = asRecordArray(data);
  const authorMap = await getProfileMap(rows.map((row) => String(row.user_id ?? "")));
  return buildCommentTree(
    rows.map((row) => ({
      id: String(row.id ?? ""),
      postId: String(row.post_id ?? ""),
      userId: String(row.user_id ?? ""),
      parentId: row.parent_id ? String(row.parent_id) : null,
      content: String(row.content ?? ""),
      status: String(row.status ?? "approved") as BlogComment["status"],
      authorName: authorMap.get(String(row.user_id ?? ""))?.displayName ?? "Subscriber",
      authorAvatarUrl: authorMap.get(String(row.user_id ?? ""))?.avatarUrl ?? null,
      createdAt: String(row.created_at ?? ""),
      updatedAt: String(row.updated_at ?? ""),
      replies: [],
    }))
  );
}

export async function getViewerPendingComments(postId: string, userId: string) {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_comments")
    .select("id, post_id, user_id, parent_id, content, status, created_at, updated_at")
    .eq("post_id", postId)
    .eq("user_id", userId)
    .in("status", ["pending", "rejected"])
    .order("created_at", { ascending: false });
  if (error) throw new Error(error.message);

  const authorMap = await getProfileMap([userId]);
  return asRecordArray(data).map((row) => ({
    id: String(row.id ?? ""),
    postId: String(row.post_id ?? ""),
    userId: String(row.user_id ?? ""),
    parentId: row.parent_id ? String(row.parent_id) : null,
    content: String(row.content ?? ""),
    status: String(row.status ?? "pending") as BlogComment["status"],
    authorName: authorMap.get(userId)?.displayName ?? "Subscriber",
    authorAvatarUrl: authorMap.get(userId)?.avatarUrl ?? null,
    createdAt: String(row.created_at ?? ""),
    updatedAt: String(row.updated_at ?? ""),
    replies: [],
  }));
}

export async function getRecentBlogCommentsForAdmin() {
  const admin = createAdminClient();
  const { data, error } = await admin
    .from("blog_comments")
    .select("id, post_id, user_id, parent_id, content, status, created_at, updated_at")
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) throw new Error(error.message);

  const rows = asRecordArray(data);
  const postIds = rows.map((row) => String(row.post_id ?? ""));
  const userIds = rows.map((row) => String(row.user_id ?? ""));
  const authorMap = await getProfileMap(userIds);
  const adminClient = createAdminClient();
  const { data: postsData, error: postsError } = await adminClient.from("blog_posts").select("id, title, slug").in("id", postIds);
  if (postsError) throw new Error(postsError.message);
  const postMap = new Map(asRecordArray(postsData).map((row) => [String(row.id ?? ""), row]));

  return rows.map((row) => ({
    id: String(row.id ?? ""),
    postId: String(row.post_id ?? ""),
    userId: String(row.user_id ?? ""),
    parentId: row.parent_id ? String(row.parent_id) : null,
    content: String(row.content ?? ""),
    status: String(row.status ?? "pending") as BlogComment["status"],
    authorName: authorMap.get(String(row.user_id ?? ""))?.displayName ?? "Subscriber",
    authorAvatarUrl: authorMap.get(String(row.user_id ?? ""))?.avatarUrl ?? null,
    createdAt: String(row.created_at ?? ""),
    updatedAt: String(row.updated_at ?? ""),
    replies: [],
    postTitle: String(postMap.get(String(row.post_id ?? ""))?.title ?? "Untitled"),
    postSlug: String(postMap.get(String(row.post_id ?? ""))?.slug ?? ""),
  }));
}

export async function getBlogAuthorsForAdmin() {
  const feed = await getAdminBlogPosts();
  const map = new Map<string, BlogAuthor>();
  for (const post of feed) {
    if (post.author) map.set(post.author.id, post.author);
  }
  return Array.from(map.values()).sort((a, b) => a.displayName.localeCompare(b.displayName));
}
