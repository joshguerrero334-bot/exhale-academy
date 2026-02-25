import { redirect } from "next/navigation";

type PageProps = {
  params: Promise<{ attemptId: string }>;
};

export default async function LegacyMasterAttemptPage({ params }: PageProps) {
  const { attemptId } = await params;
  redirect(`/master/${encodeURIComponent(attemptId)}`);
}
