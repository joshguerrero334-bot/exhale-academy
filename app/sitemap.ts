import type { MetadataRoute } from "next";
import { getBlogCategories, getBlogTags, getPublishedBlogPostSlugs } from "../lib/blog/data";
import { getSiteUrl } from "../lib/site";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = getSiteUrl();
  const hasAdminEnv =
    Boolean(String(process.env.NEXT_PUBLIC_SUPABASE_URL ?? "").trim()) &&
    Boolean(String(process.env.SUPABASE_SERVICE_ROLE_KEY ?? "").trim());
  const [blogPosts, categories, tags] = hasAdminEnv
    ? await Promise.all([getPublishedBlogPostSlugs(), getBlogCategories(), getBlogTags()])
    : [[], [], []];

  const staticRoutes: MetadataRoute.Sitemap = [
    "",
    "/about",
    "/blog",
    "/free-cse-slideshows",
    "/login",
    "/signup",
    "/privacy",
    "/terms",
  ].map((pathname) => ({
    url: `${base}${pathname || "/"}`,
    lastModified: new Date(),
    changeFrequency: pathname === "/blog" || pathname === "" ? "weekly" : "monthly",
    priority: pathname === "" ? 1 : pathname === "/blog" || pathname === "/free-cse-slideshows" ? 0.9 : 0.6,
  }));

  const blogRoutes: MetadataRoute.Sitemap = blogPosts.map((post) => ({
    url: `${base}/blog/${post.slug}`,
    lastModified: post.updatedAt ? new Date(post.updatedAt) : new Date(),
    changeFrequency: "weekly",
    priority: 0.8,
  }));

  const categoryRoutes: MetadataRoute.Sitemap = categories.map((category) => ({
    url: `${base}/blog/category/${category.slug}`,
    lastModified: new Date(),
    changeFrequency: "weekly",
    priority: 0.7,
  }));

  const tagRoutes: MetadataRoute.Sitemap = tags.map((tag) => ({
    url: `${base}/blog/tag/${tag.slug}`,
    lastModified: new Date(),
    changeFrequency: "weekly",
    priority: 0.6,
  }));

  return [...staticRoutes, ...blogRoutes, ...categoryRoutes, ...tagRoutes];
}
