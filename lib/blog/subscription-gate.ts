import { resolveIsSubscribed } from "../auth/subscription-access";

export async function canCommentOnBlog(supabase: unknown, userId: string) {
  return resolveIsSubscribed(supabase, userId);
}
