import type { BlogPost } from "./types";
import { getSiteUrl, toAbsoluteUrl } from "../site";

export function buildBlogPostingStructuredData(post: BlogPost) {
  return {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.seoDescription || post.excerpt,
    image: post.featuredImageUrl ? [post.featuredImageUrl] : undefined,
    datePublished: post.publishedAt || undefined,
    dateModified: post.updatedAt,
    author: {
      "@type": "Person",
      name: post.author?.displayName ?? "Exhale Academy",
    },
    publisher: {
      "@type": "Organization",
      name: "Exhale Academy",
      url: getSiteUrl(),
    },
    mainEntityOfPage: post.canonicalUrl || toAbsoluteUrl(`/blog/${post.slug}`),
  };
}
