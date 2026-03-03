import Link from "next/link";

export default function SiteFooter() {
  return (
    <footer className="border-t border-white/10 bg-[#0A1A2F] py-8">
      <div className="mx-auto flex w-full max-w-5xl flex-col items-center justify-between gap-3 px-4 text-sm text-white/70 sm:flex-row sm:px-6 lg:px-8">
        <div className="flex flex-wrap items-center justify-center gap-4">
          <Link href="/about" className="transition hover:text-[#C9A86A]">
            About Us
          </Link>
          <Link href="/privacy" className="transition hover:text-[#C9A86A]">
            Privacy Policy
          </Link>
          <Link href="/terms" className="transition hover:text-[#C9A86A]">
            Terms of Service
          </Link>
        </div>
        <a href="mailto:myexhaleacademy@gmail.com" className="transition hover:text-[#C9A86A]">
          Support: myexhaleacademy@gmail.com
        </a>
      </div>
    </footer>
  );
}
