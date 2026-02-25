"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

const ACK_KEY = "cse_ack_v1";

type CseStartGateProps = {
  mode: "tutor" | "exam";
};

export default function CseStartGate({ mode }: CseStartGateProps) {
  const router = useRouter();

  useEffect(() => {
    const acknowledged = window.localStorage.getItem(ACK_KEY) === "true";
    if (!acknowledged) {
      router.replace("/cse/how-it-works");
      return;
    }

    router.replace(`/cse/case/1?mode=${mode}`);
  }, [mode, router]);

  return (
    <main className="page-shell">
      <div className="mx-auto w-full max-w-3xl rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-6 shadow-sm sm:p-8">
        <h1 className="text-2xl font-bold text-[color:var(--brand-navy)]">Preparing CSE Session</h1>
        <p className="mt-2 text-sm text-slate-600">
          Verifying setup and loading your {mode === "tutor" ? "Tutor" : "Exam"} mode case.
        </p>
      </div>
    </main>
  );
}
