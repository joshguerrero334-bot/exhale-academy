export type BlogStatus = "draft" | "published" | "archived";
export type BlogCommentStatus = "pending" | "approved" | "hidden" | "rejected";

export type BlogCategory = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  postCount?: number;
};

export type BlogTag = {
  id: string;
  name: string;
  slug: string;
  postCount?: number;
};

export type BlogAuthor = {
  id: string;
  displayName: string;
  avatarUrl: string | null;
};

export type BlogPost = {
  id: string;
  title: string;
  slug: string;
  excerpt: string;
  content: string;
  featuredImageUrl: string | null;
  author: BlogAuthor | null;
  status: BlogStatus;
  publishedAt: string | null;
  seoTitle: string | null;
  seoDescription: string | null;
  canonicalUrl: string | null;
  isFeatured: boolean;
  allowComments: boolean;
  readTimeMinutes: number | null;
  primaryCategory: BlogCategory | null;
  tags: BlogTag[];
  createdAt: string;
  updatedAt: string;
};

export type BlogComment = {
  id: string;
  postId: string;
  userId: string;
  parentId: string | null;
  content: string;
  status: BlogCommentStatus;
  authorName: string;
  authorAvatarUrl: string | null;
  createdAt: string;
  updatedAt: string;
  replies: BlogComment[];
};

export type BlogFeedFilters = {
  q?: string;
  category?: string;
  tag?: string;
  page?: number;
  pageSize?: number;
};

export type PaginatedBlogPosts = {
  items: BlogPost[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
};

export type ViewerBlogState = {
  isLoggedIn: boolean;
  isSubscribed: boolean;
  canComment: boolean;
  userId: string | null;
};
