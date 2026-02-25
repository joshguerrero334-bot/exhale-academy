"use client";

type ConfirmSubmitButtonProps = {
  formId: string;
  label: string;
  className?: string;
  confirmText?: string;
};

export default function ConfirmSubmitButton({
  formId,
  label,
  className,
  confirmText = "Are you sure you want to move to the next section? You cannot go back.",
}: ConfirmSubmitButtonProps) {
  return (
    <button
      type="button"
      className={className}
      onClick={() => {
        if (!window.confirm(confirmText)) return;
        const form = document.getElementById(formId) as HTMLFormElement | null;
        form?.requestSubmit();
      }}
    >
      {label}
    </button>
  );
}
