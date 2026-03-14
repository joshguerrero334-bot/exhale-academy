import Link from "next/link";

type Props = {
  isLoggedIn: boolean;
  isSubscribed: boolean;
  slug: string;
};

export default function SubscriptionCommentGate({ isLoggedIn, isSubscribed, slug }: Props) {
  const helperCopy = isLoggedIn && !isSubscribed
    ? "Comments are available to Exhale subscribers only."
    : "Log in or subscribe to join the discussion.";

  return (
    <div className="rounded-[1.75rem] border border-[color:var(--brand-gold)]/30 bg-[color:var(--brand-gold)]/10 p-6">
      <p className="text-lg font-semibold text-[color:var(--brand-navy)]">{helperCopy}</p>
      <div className="mt-4 flex flex-wrap gap-3">
        <Link href="/signup" className="btn-primary">Subscribe</Link>
        <Link href={`/login?next=${encodeURIComponent(`/blog/${slug}#comments`)}`} className="btn-secondary">Log In</Link>
      </div>
    </div>
  );
}
