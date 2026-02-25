import Link from "next/link";

type PracticeSwitchBarProps = {
  active?: "cse" | "tmc";
  cseHref: string;
  tmcHref: string;
};

export default function PracticeSwitchBar({ active, cseHref, tmcHref }: PracticeSwitchBarProps) {
  const base =
    "inline-flex w-full items-center justify-center rounded-full px-4 py-2 text-sm font-semibold transition";

  return (
    <div className="sticky top-[68px] z-40 border-b border-graysoft/30 bg-white/90 backdrop-blur">
      <div className="mx-auto flex w-full max-w-5xl px-4 py-3 sm:px-6 lg:px-8">
        <div className="inline-flex w-full max-w-md rounded-full border border-graysoft/30 bg-background p-1">
          <Link
            href={cseHref}
            className={`${base} ${
              active === "cse"
                ? "bg-primary text-white"
                : "text-charcoal hover:bg-white"
            }`}
          >
            CSE Practice
          </Link>
          <Link
            href={tmcHref}
            className={`${base} ${
              active === "tmc"
                ? "bg-primary text-white"
                : "text-charcoal hover:bg-white"
            }`}
          >
            TMC Practice
          </Link>
        </div>
      </div>
    </div>
  );
}
