import { redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ sessionId: string }>;
};

export default async function LegacyResultsPage({ params }: PageProps) {
  const { sessionId } = await params;
  redirect(`/dashboard?error=${encodeURIComponent(`Legacy results route is deprecated (${sessionId}). Use category or master results routes.`)}`);
}
