import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy | Exhale Academy",
  description: "Read the Exhale Academy Privacy Policy.",
};

export default function PrivacyPage() {
  return (
    <main className="bg-[#0A1A2F] text-white">
      <div className="mx-auto max-w-3xl px-6 py-16">
        <h1 className="text-3xl font-bold">Privacy Policy</h1>
        <p className="mt-2 text-white/70">Last Updated: March 2026</p>

        <p className="mt-6 text-white/70">
          Exhale Academy (&ldquo;we&rdquo;, &ldquo;us&rdquo;, &ldquo;our&rdquo;) respects your privacy. This Privacy Policy explains
          how we collect, use, store, and protect your information.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Information We Collect</h2>
        <p className="mt-3 text-white/70">We collect:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>Account information (name, email)</li>
          <li>Payment information (handled securely by Stripe)</li>
          <li>Usage analytics</li>
          <li>Technical data such as browser, device type, and IP</li>
        </ul>
        <p className="mt-3 text-white/70">We do not store full credit card numbers.</p>

        <h2 className="mt-8 text-xl font-semibold">How We Use Your Information</h2>
        <p className="mt-3 text-white/70">We use your information to:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>Provide platform access</li>
          <li>Authenticate accounts</li>
          <li>Deliver educational content</li>
          <li>Improve performance and reliability</li>
          <li>Process payments</li>
          <li>Communicate updates or support messages</li>
        </ul>
        <p className="mt-3 text-white/70">We do not sell or rent your data.</p>

        <h2 className="mt-8 text-xl font-semibold">Cookies &amp; Tracking</h2>
        <p className="mt-3 text-white/70">We use cookies and analytics tools to:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>Maintain login sessions</li>
          <li>Track usage patterns</li>
          <li>Improve user experience</li>
        </ul>
        <p className="mt-3 text-white/70">Disabling cookies may impair functionality.</p>

        <h2 className="mt-8 text-xl font-semibold">Payment Processing</h2>
        <p className="mt-3 text-white/70">
          All payments are processed by Stripe, a PCI-DSS compliant processor. We do not have access to your full
          payment card details.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Data Storage &amp; Security</h2>
        <p className="mt-3 text-white/70">Your data is stored securely using Supabase:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>Encrypted databases</li>
          <li>Row-level security</li>
          <li>Authentication and RBAC</li>
        </ul>

        <h2 className="mt-8 text-xl font-semibold">Sharing of Information</h2>
        <p className="mt-3 text-white/70">We do not share information except:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>With Stripe (for payments)</li>
          <li>With essential service providers</li>
          <li>When required by law</li>
        </ul>

        <h2 className="mt-8 text-xl font-semibold">Age Restrictions</h2>
        <p className="mt-3 text-white/70">
          This platform is intended for users 18+. We do not knowingly collect information from minors.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Your Rights</h2>
        <p className="mt-3 text-white/70">You may request:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>Account deletion</li>
          <li>Data export</li>
          <li>Correction of inaccurate information</li>
        </ul>
        <p className="mt-3 text-white/70">Contact: myexhaleacademy@gmail.com</p>

        <h2 className="mt-8 text-xl font-semibold">Changes to This Policy</h2>
        <p className="mt-3 text-white/70">
          We may update this Privacy Policy periodically. Continued use constitutes acceptance.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Contact</h2>
        <p className="mt-3 text-white/70">If you have questions: myexhaleacademy@gmail.com</p>
      </div>
    </main>
  );
}
