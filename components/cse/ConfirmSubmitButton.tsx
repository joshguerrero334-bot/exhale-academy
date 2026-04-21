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
      type="submit"
      form={formId}
      className={className}
      onClick={(event) => {
        if (!window.confirm(confirmText)) {
          event.preventDefault();
        }
      }}
    >
      {label}
    </button>
  );
}
