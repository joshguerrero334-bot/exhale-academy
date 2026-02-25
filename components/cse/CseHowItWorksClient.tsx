"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

const ACK_KEY = "cse_ack_v1";

type Choice = {
  id: string;
  label: string;
};

const IG_CHOICES: Choice[] = [
  { id: "abg", label: "Review ABG and oxygenation trend" },
  { id: "cxr", label: "Review chest radiograph" },
  { id: "bmp", label: "Order daily BMP" },
  { id: "echo", label: "Order immediate echocardiogram" },
];

const DM_CHOICES: Choice[] = [
  { id: "peep", label: "Increase PEEP and reassess oxygenation" },
  { id: "fio2", label: "Only increase FiO2 to 1.0 and wait" },
  { id: "sedate", label: "Increase sedation first" },
  { id: "extubate", label: "Proceed to extubation" },
];

export default function CseHowItWorksClient() {
  const router = useRouter();
  const [igSelected, setIgSelected] = useState<string[]>([]);
  const [igWarning, setIgWarning] = useState<string | null>(null);
  const [dmSelected, setDmSelected] = useState<string>("");
  const [acknowledged, setAcknowledged] = useState(false);

  const igLimit = 3;

  const canStart = useMemo(() => acknowledged, [acknowledged]);

  useEffect(() => {
    const stored = window.localStorage.getItem(ACK_KEY) === "true";
    // eslint-disable-next-line react-hooks/set-state-in-effect -- one-time client hydration sync from localStorage
    setAcknowledged(stored);
  }, []);

  function toggleIg(id: string) {
    setIgWarning(null);
    setIgSelected((prev) => {
      if (prev.includes(id)) return prev.filter((x) => x !== id);
      if (prev.length >= igLimit) {
        setIgWarning(`Selection limit reached. You can choose up to ${igLimit} options.`);
        return prev;
      }
      return [...prev, id];
    });
  }

  function onAcknowledgeChange(checked: boolean) {
    setAcknowledged(checked);
    window.localStorage.setItem(ACK_KEY, checked ? "true" : "false");
  }

  return (
    <div className="space-y-6">
      <section className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
        <h3 className="text-lg font-semibold text-[color:var(--brand-navy)]">Interactive Mini-Demo</h3>

        <div className="mt-4 space-y-3">
          <p className="text-sm font-semibold text-[color:var(--brand-navy)]">
            Information Gathering (IG): select up to {igLimit}
          </p>
          <div className="grid gap-2">
            {IG_CHOICES.map((choice) => {
              const checked = igSelected.includes(choice.id);
              return (
                <label
                  key={choice.id}
                  className="flex cursor-pointer items-center gap-3 rounded-lg border border-[color:var(--cool-gray)] bg-white px-3 py-2 text-sm"
                >
                  <input
                    type="checkbox"
                    checked={checked}
                    onChange={() => toggleIg(choice.id)}
                    className="h-4 w-4"
                  />
                  <span className="text-slate-700">{choice.label}</span>
                </label>
              );
            })}
          </div>
          {igWarning ? <p className="text-xs text-red-700">{igWarning}</p> : null}
        </div>

        <div className="mt-5 space-y-3">
          <p className="text-sm font-semibold text-[color:var(--brand-navy)]">Decision Making (DM): one best choice</p>
          <div className="grid gap-2">
            {DM_CHOICES.map((choice) => (
              <label
                key={choice.id}
                className="flex cursor-pointer items-center gap-3 rounded-lg border border-[color:var(--cool-gray)] bg-white px-3 py-2 text-sm"
              >
                <input
                  type="radio"
                  name="dm_demo"
                  checked={dmSelected === choice.id}
                  onChange={() => setDmSelected(choice.id)}
                  className="h-4 w-4"
                />
                <span className="text-slate-700">{choice.label}</span>
              </label>
            ))}
          </div>
        </div>
      </section>

      <section className="rounded-xl border border-[color:var(--cool-gray)] bg-[color:var(--surface-soft)] p-4">
        <label className="flex items-start gap-3 text-sm text-slate-700">
          <input
            type="checkbox"
            checked={acknowledged}
            onChange={(e) => onAcknowledgeChange(e.target.checked)}
            className="mt-0.5 h-4 w-4"
          />
          <span>I understand the CSE 3-window layout, section confirmation flow, and scoring behavior.</span>
        </label>

        <button
          type="button"
          disabled={!canStart}
          onClick={() => router.push("/cse/cases")}
          className="mt-4 inline-flex rounded-lg bg-[color:var(--brand-gold)] px-5 py-2.5 text-sm font-semibold text-[color:var(--brand-navy)] disabled:cursor-not-allowed disabled:bg-slate-300 disabled:text-slate-500"
        >
          Start CSE Practice
        </button>
      </section>
    </div>
  );
}
