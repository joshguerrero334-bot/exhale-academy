import { redirect } from "next/navigation";

export default async function AdminBlogIdRedirectPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  redirect(`/admin/blog/${id}/edit`);
}
