import type { Metadata } from "next";
import type { BlogCategory, BlogPost, BlogTag } from "./types";
import { toAbsoluteUrl } from "../site";

const DEFAULT_SOCIAL_PREVIEW = toAbsoluteUrl("/exhale-blog-social-preview.svg");

export function buildBlogIndexMetadata(): Metadata {
  return {
    title: "Exhale Academy Blog | TMC, CSE, ABG, and RT Study Articles",
    description:
      "Free respiratory therapy articles from Exhale Academy covering TMC prep, CSE strategy, ABGs, ventilator management, and RT study systems.",
    alternates: { canonical: "/blog" },
    openGraph: {
      title: "Exhale Academy Blog",
      description:
        "Free respiratory therapy articles focused on TMC prep, CSE prep, ABGs, ventilator management, and RT clinical reasoning.",
      url: toAbsoluteUrl("/blog"),
      type: "website",
      images: [{ url: DEFAULT_SOCIAL_PREVIEW, alt: "Exhale Academy Blog" }],
    },
    twitter: {
      card: "summary_large_image",
      title: "Exhale Academy Blog",
      description:
        "Free respiratory therapy articles focused on TMC prep, CSE prep, ABGs, ventilator management, and RT clinical reasoning.",
      images: [DEFAULT_SOCIAL_PREVIEW],
    },
  };
}

export function buildBlogPostMetadata(post: BlogPost): Metadata {
  const title = post.seoTitle || `${post.title} | Exhale Academy Blog`;
  const description = post.seoDescription || post.excerpt;
  const canonical = post.canonicalUrl || toAbsoluteUrl(`/blog/${post.slug}`);
  return {
    title,
    description,
    alternates: { canonical },
    openGraph: {
      title,
      description,
      url: canonical,
      type: "article",
      publishedTime: post.publishedAt || undefined,
      authors: post.author?.displayName ? [post.author.displayName] : undefined,
      images: [{ url: post.featuredImageUrl || DEFAULT_SOCIAL_PREVIEW, alt: post.title }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [post.featuredImageUrl || DEFAULT_SOCIAL_PREVIEW],
    },
  };
}

export function buildBlogArchiveMetadata(kind: "category" | "tag", entry: BlogCategory | BlogTag): Metadata {
  const title = `${entry.name} | Exhale Academy Blog`;
  const categoryDescription = kind === "category" ? (entry as BlogCategory).description : null;
  const description =
    kind === "category"
      ? categoryDescription || `Browse Exhale Academy blog posts in ${entry.name}.`
      : `Browse Exhale Academy blog posts tagged ${entry.name}.`;
  const canonical = toAbsoluteUrl(`/blog/${kind}/${entry.slug}`);
  return {
    title,
    description,
    alternates: { canonical },
    openGraph: {
      title,
      description,
      url: canonical,
      type: "website",
      images: [{ url: DEFAULT_SOCIAL_PREVIEW, alt: "Exhale Academy Blog" }],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [DEFAULT_SOCIAL_PREVIEW],
    },
  };
}
