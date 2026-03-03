import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service | Exhale Academy",
  description: "Read the Exhale Academy Terms of Service.",
};

export default function TermsPage() {
  return (
    <main className="bg-[#0A1A2F] text-white">
      <div className="mx-auto max-w-3xl px-6 py-16">
        <h1 className="text-3xl font-bold">Terms of Service</h1>
        <p className="mt-2 text-white/70">Last Updated: March 2026</p>

        <p className="mt-6 text-white/70">
          Welcome to Exhale Academy (&ldquo;we&rdquo;, &ldquo;us&rdquo;, &ldquo;our&rdquo;). By accessing or using this website,
          application, or any related services (&ldquo;Service&rdquo;), you agree to these Terms of Service
          (&ldquo;Terms&rdquo;). If you do not agree, you may not use the Service.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Educational Use Only (No Medical Advice)</h2>
        <p className="mt-3 text-white/70">
          Exhale Academy provides test-preparation content only. Nothing on this site constitutes medical advice,
          clinical instruction, diagnosis, or treatment guidance. Do not apply any scenario or recommendation to real
          patients.
        </p>
        <p className="mt-3 text-white/70">
          You agree that you will not rely on the Service for any medical, clinical, or emergency decision-making.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Not Affiliated With NBRC or Any Exam Provider</h2>
        <p className="mt-3 text-white/70">
          Exhale Academy is an independent educational resource and is not affiliated, endorsed, or sponsored by the
          National Board for Respiratory Care (NBRC) or any credentialing body. Any similarity to official exam
          content is purely coincidental.
        </p>

        <h2 className="mt-8 text-xl font-semibold">No Outcome Guarantees</h2>
        <p className="mt-3 text-white/70">
          We do not guarantee that you will pass any exam, improve clinically, earn certification, or achieve any
          particular score. You use the Service at your own risk and discretion.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Subscription, Billing, and Refunds</h2>
        <ul className="mt-3 list-disc space-y-2 pl-5 text-white/70">
          <li>Subscriptions auto-renew unless canceled before the renewal date.</li>
          <li>All sales are final once access has been granted.</li>
          <li>No refunds for partial months, unused time, or dissatisfaction with content.</li>
          <li>You are responsible for maintaining your payment method.</li>
        </ul>
        <p className="mt-3 text-white/70">
          Chargebacks without first contacting support may result in account termination.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Account Rules</h2>
        <p className="mt-3 text-white/70">You agree to:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>NOT share your account or login</li>
          <li>NOT copy, reproduce, or redistribute content</li>
          <li>NOT use bots or automated tools</li>
          <li>NOT attempt unauthorized access to any part of the system</li>
        </ul>
        <p className="mt-3 text-white/70">
          Accounts found violating these rules may be suspended without refund.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Intellectual Property</h2>
        <p className="mt-3 text-white/70">
          All exams, cases, scenarios, designs, questions, and materials on Exhale Academy are proprietary. You may
          not copy, distribute, or create derivative works.
        </p>

        <h2 className="mt-8 text-xl font-semibold">No Protected Health Information (PHI)</h2>
        <p className="mt-3 text-white/70">
          You agree not to submit, upload, or enter real patient data, HIPAA-protected health information, or
          sensitive workplace documentation. Violation may result in immediate account termination.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Age Requirement</h2>
        <p className="mt-3 text-white/70">You must be 18 years or older to use the Service.</p>

        <h2 className="mt-8 text-xl font-semibold">Limitation of Liability</h2>
        <p className="mt-3 text-white/70">To the fullest extent permitted by law:</p>
        <ul className="mt-2 list-disc space-y-2 pl-5 text-white/70">
          <li>We are not liable for damages arising from use of the Service.</li>
          <li>We are not liable for exam failure, loss of employment, or academic penalties.</li>
          <li>Your sole remedy is discontinuing use of the Service.</li>
        </ul>

        <h2 className="mt-8 text-xl font-semibold">Modification of Terms</h2>
        <p className="mt-3 text-white/70">
          We may update these Terms at any time. Continued use after updates constitutes acceptance.
        </p>

        <h2 className="mt-8 text-xl font-semibold">Contact</h2>
        <p className="mt-3 text-white/70">For questions or concerns: myexhaleacademy@gmail.com</p>

        <p className="mt-8 text-white/70">
          By using the Service, you acknowledge that you have read and agree to these Terms.
        </p>
      </div>
    </main>
  );
}
