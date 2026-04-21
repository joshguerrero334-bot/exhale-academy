import type { Metadata } from "next";
import Link from "next/link";
import { headingFont } from "../../../lib/fonts";

export const metadata: Metadata = {
  title: "Email Confirmed | Exhale Academy",
  description: "Your Exhale Academy email has been confirmed.",
  robots: {
    index: false,
    follow: false,
  },
};

type ConfirmedPageProps = {
  searchParams: Promise<{ next?: string }>;
};

function sanitizeNext(raw: string | undefined) {
  if (!raw || !raw.startsWith("/")) return "/billing?autostart=1";
  if (raw.startsWith("//")) return "/billing?autostart=1";
  return raw;
}

export default async function EmailConfirmedPage({ searchParams }: ConfirmedPageProps) {
  const params = await searchParams;
  const nextPath = sanitizeNext(params.next);

  return (
    <main className="min-h-screen bg-background px-4 py-10 text-charcoal sm:px-6 lg:px-8">
      <section className="mx-auto w-full max-w-xl rounded-2xl border border-graysoft/30 bg-white p-6 text-center shadow-sm sm:p-8">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">Exhale Academy</p>
        <h1 className={`${headingFont} mt-3 text-3xl font-semibold text-charcoal sm:text-4xl`}>
          Email Confirmed
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
          Your email has been confirmed successfully. You can now continue to secure checkout and activate your Exhale Academy access.
        </p>
        <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
          <Link href={nextPath} className="btn-primary px-6 py-3 text-center">
            Continue to Checkout
          </Link>
          <Link href="/login" className="btn-secondary px-6 py-3 text-center">
            Log In Instead
          </Link>
        </div>
      </section>
    </main>
  );
}
