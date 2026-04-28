import type { MetadataRoute } from "next";
import { getSiteUrl } from "../lib/site";

export default function robots(): MetadataRoute.Robots {
  const base = getSiteUrl();
  return {
    rules: {
      userAgent: "*",
      allow: ["/", "/blog", "/blog/", "/free-cse-pdf-guides", "/pdf-guides/"],
      disallow: ["/admin/"],
    },
    sitemap: `${base}/sitemap.xml`,
    host: base,
  };
}
