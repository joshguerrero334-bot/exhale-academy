import Link from "next/link";
import { headingFont } from "../lib/fonts";

type BrandLogoProps = {
  href?: string;
};

export default function BrandLogo({ href = "/" }: BrandLogoProps) {
  return (
    <Link href={href} className="inline-flex min-w-0 items-center gap-2 sm:gap-3">
      <div className="flex h-10 w-10 shrink-0 items-center justify-center sm:h-12 sm:w-12">
        <svg
          viewBox="0 0 64 64"
          aria-hidden="true"
          className="h-10 w-10 sm:h-12 sm:w-12"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path d="M31 5v16c0 3-2 4-4 6-3 2-7 9-7 16v12c0 2-2 4-5 3C9 56 6 49 6 39 6 24 16 13 31 11" stroke="#71C9C2" strokeWidth="1.6" strokeLinecap="round" />
          <path d="M33 5v16c0 3 2 4 4 6 3 2 7 9 7 16v12c0 2 2 4 5 3 6-2 9-9 9-19 0-15-10-26-25-28" stroke="#71C9C2" strokeWidth="1.6" strokeLinecap="round" />
          <path d="M29 5h6v8h-6z" stroke="#71C9C2" strokeWidth="1.2" />
          <path d="M10 28l16 10M12 40l14-3M15 22l11 7M20 18l6 6M23 31l3 9" stroke="#71C9C2" strokeWidth="1" strokeLinecap="round" opacity=".8" />
          <path d="M54 28L38 38M52 40l-14-3M49 22l-11 7M44 18l-6 6M41 31l-3 9" stroke="#71C9C2" strokeWidth="1" strokeLinecap="round" opacity=".8" />
        </svg>
      </div>

      <div className="min-w-0 leading-tight">
        <div className={`${headingFont} truncate text-lg font-semibold tracking-wide sm:text-2xl`}>
          <span className="text-charcoal">Exhale</span>
          <span className="text-primary">Academy</span>
        </div>
        <div className="hidden text-[10px] uppercase tracking-[0.35em] text-graysoft sm:block">
          Breathe easy. Pass with confidence.
        </div>
      </div>
    </Link>
  );
}
