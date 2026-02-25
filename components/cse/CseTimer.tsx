"use client";

import { useEffect, useMemo, useState } from "react";

type CseTimerProps = {
  attemptId: string;
  initialSeconds?: number;
  canReset?: boolean;
};

function formatClock(totalSeconds: number) {
  const safe = Math.max(0, totalSeconds);
  const hours = Math.floor(safe / 3600)
    .toString()
    .padStart(2, "0");
  const minutes = Math.floor((safe % 3600) / 60)
    .toString()
    .padStart(2, "0");
  const seconds = Math.floor(safe % 60)
    .toString()
    .padStart(2, "0");
  return `${hours}:${minutes}:${seconds}`;
}

export default function CseTimer({ attemptId, initialSeconds = 4 * 60 * 60, canReset = false }: CseTimerProps) {
  const key = useMemo(() => `cse-timer-${attemptId}`, [attemptId]);
  const [hidden, setHidden] = useState(false);
  const [secondsLeft, setSecondsLeft] = useState(initialSeconds);

  useEffect(() => {
    const stored = typeof window !== "undefined" ? window.localStorage.getItem(key) : null;
    const parsed = stored ? Number(stored) : Number.NaN;
    if (Number.isFinite(parsed) && parsed >= 0) {
      setSecondsLeft(parsed);
      return;
    }
    setSecondsLeft(initialSeconds);
    window.localStorage.setItem(key, String(initialSeconds));
  }, [key, initialSeconds]);

  const handleReset = () => {
    setSecondsLeft(initialSeconds);
    window.localStorage.setItem(key, String(initialSeconds));
  };

  useEffect(() => {
    const id = window.setInterval(() => {
      setSecondsLeft((prev) => {
        const next = Math.max(0, prev - 1);
        window.localStorage.setItem(key, String(next));
        return next;
      });
    }, 1000);

    return () => window.clearInterval(id);
  }, [key]);

  return (
    <div className="fixed bottom-4 left-1/2 z-40 flex -translate-x-1/2 items-center gap-2">
      <button
        type="button"
        onClick={() => setHidden((prev) => !prev)}
        className="rounded-xl border border-[color:var(--cool-gray)] bg-white px-4 py-2 text-left shadow"
        title={hidden ? "Show timer" : "Hide timer"}
      >
        {hidden ? (
          <span className="text-xs font-semibold uppercase tracking-[0.1em] text-slate-600">Show Timer</span>
        ) : (
          <>
            <span className="block text-[10px] font-semibold uppercase tracking-[0.14em] text-slate-500">Time Remaining</span>
            <span className="block text-base font-bold text-[color:var(--brand-navy)]">{formatClock(secondsLeft)}</span>
          </>
        )}
      </button>
      {canReset ? (
        <button
          type="button"
          onClick={handleReset}
          className="rounded-xl border border-[color:var(--brand-gold)] bg-white px-3 py-2 text-xs font-semibold uppercase tracking-[0.08em] text-[color:var(--brand-navy)] shadow"
          title="Reset timer"
        >
          Reset
        </button>
      ) : null}
    </div>
  );
}
