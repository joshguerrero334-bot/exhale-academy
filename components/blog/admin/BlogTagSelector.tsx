import type { BlogPost } from "../../../lib/blog/types";

export default function BlogTagSelector({ post }: { post: BlogPost | null }) {
  return (
    <div>
      <label className="mb-2 block text-sm font-semibold text-[color:var(--brand-navy)]">Tags</label>
      <input type="text" name="tags" defaultValue={post?.tags.map((tag) => tag.name).join(", ") ?? ""} placeholder="ABGs, Ventilator Management, TMC Strategy" className="w-full rounded-xl border border-[color:var(--border)] bg-white px-4 py-3 text-sm outline-none transition focus:border-[color:var(--brand-gold)]" />
    </div>
  );
}
