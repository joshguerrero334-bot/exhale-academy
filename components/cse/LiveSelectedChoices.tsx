"use client";

import { useEffect, useMemo, useState } from "react";

type OptionLite = {
  option_key: string;
  option_text: string;
};

type LiveSelectedChoicesProps = {
  formId: string;
  options: OptionLite[];
};

export default function LiveSelectedChoices({ formId, options }: LiveSelectedChoicesProps) {
  const [selectedKeys, setSelectedKeys] = useState<string[]>([]);

  const optionTextByKey = useMemo(() => {
    const map = new Map<string, string>();
    for (const option of options) {
      map.set(option.option_key.toUpperCase(), option.option_text);
    }
    return map;
  }, [options]);

  useEffect(() => {
    const form = document.getElementById(formId) as HTMLFormElement | null;
    if (!form) return;

    const computeSelected = () => {
      const checked = form.querySelectorAll<HTMLInputElement>('input[name="selected_keys"]:checked');
      const keys = Array.from(checked)
        .map((input) => input.value.toUpperCase())
        .filter(Boolean);
      setSelectedKeys(keys);
    };

    computeSelected();
    form.addEventListener("change", computeSelected);
    return () => form.removeEventListener("change", computeSelected);
  }, [formId]);

  return (
    <div className="rounded-lg border border-[color:var(--cool-gray)] bg-white p-3 text-sm">
      <p className="font-semibold text-[color:var(--brand-navy)]">Current Section (pending)</p>
      {selectedKeys.length === 0 ? (
        <p className="mt-1 text-slate-600">No choices selected yet.</p>
      ) : (
        <ul className="mt-2 list-disc space-y-1 pl-5 text-slate-700">
          {selectedKeys.map((key) => (
            <li key={key}>{optionTextByKey.get(key) ?? "Unknown choice"}</li>
          ))}
        </ul>
      )}
    </div>
  );
}
