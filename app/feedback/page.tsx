import { redirect } from "next/navigation";
import { headingFont } from "../../lib/fonts";
import { createClient } from "../../lib/supabase/server";
import { submitFeedback } from "./actions";

type FeedbackPageProps = {
  searchParams: Promise<{ error?: string; success?: string }>;
};

export default async function FeedbackPage({ searchParams }: FeedbackPageProps) {
  const supabase = await createClient();
  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || !user) {
    redirect("/login?next=%2Ffeedback");
  }

  const query = await searchParams;

  return (
    <main className="min-h-screen bg-background text-charcoal">
      <div className="mx-auto w-full max-w-3xl space-y-6 px-4 py-8 sm:px-6 lg:px-8">
        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-primary">How can we get better?</p>
          <h1 className={`${headingFont} mt-2 text-2xl font-semibold text-charcoal sm:text-3xl`}>
            Help us improve Exhale Academy
          </h1>
          <p className="mt-3 text-sm leading-relaxed text-graysoft sm:text-base">
            We are a new company and we are going to keep getting better. Tell us where we can improve and what looks
            great. Your honesty helps you and other RTs.
          </p>
          <p className="mt-2 text-xs text-graysoft">
            Signed in as <span className="font-semibold text-charcoal">{user.email}</span>
          </p>
        </section>

        {query.error ? (
          <section className="rounded-xl border border-red-300 bg-red-50 p-4 text-sm text-red-700">{query.error}</section>
        ) : null}

        {query.success ? (
          <section className="rounded-xl border border-green-300 bg-green-50 p-4 text-sm text-green-700">
            {query.success}
          </section>
        ) : null}

        <section className="rounded-2xl border border-graysoft/30 bg-white p-6 shadow-sm sm:p-8">
          <form action={submitFeedback} className="space-y-5">
            <div>
              <label htmlFor="product_area" className="mb-2 block text-sm font-semibold text-charcoal">
                Which part of Exhale are you reviewing?
              </label>
              <select
                id="product_area"
                name="product_area"
                defaultValue="General"
                className="w-full rounded-lg border border-graysoft/40 bg-white px-4 py-3 text-sm text-charcoal outline-none transition focus:border-primary focus:ring-2 focus:ring-primary/20"
              >
                <option value="General">General Platform</option>
                <option value="TMC Practice">TMC Practice</option>
                <option value="CSE Practice">CSE Practice</option>
                <option value="Master Exams">Master Exams</option>
                <option value="Mobile Experience">Mobile Experience</option>
                <option value="Account/Login">Account/Login</option>
              </select>
            </div>

            <div>
              <p className="mb-2 text-sm font-semibold text-charcoal">Overall experience so far</p>
              <div className="flex flex-wrap gap-2">
                {[5, 4, 3, 2, 1].map((value) => (
                  <label
                    key={value}
                    className="inline-flex cursor-pointer items-center gap-2 rounded-full border border-graysoft/40 px-3 py-2 text-sm text-charcoal transition hover:border-primary/70 hover:bg-primary/5"
                  >
                    <input type="radio" name="rating" value={value} className="accent-primary" defaultChecked={value === 5} />
                    {value}/5
                  </label>
                ))}
              </div>
            </div>

            <div>
              <label htmlFor="what_looks_great" className="mb-2 block text-sm font-semibold text-charcoal">
                What looks great?
              </label>
              <textarea
                id="what_looks_great"
                name="what_looks_great"
                rows={4}
                minLength={10}
                required
                placeholder="Tell us what is working well for you."
                className="w-full rounded-lg border border-graysoft/40 bg-white px-4 py-3 text-sm text-charcoal outline-none transition placeholder:text-graysoft focus:border-primary focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div>
              <label htmlFor="where_improve" className="mb-2 block text-sm font-semibold text-charcoal">
                Where can we improve?
              </label>
              <textarea
                id="where_improve"
                name="where_improve"
                rows={5}
                minLength={10}
                required
                placeholder="Be direct. What should we fix first?"
                className="w-full rounded-lg border border-graysoft/40 bg-white px-4 py-3 text-sm text-charcoal outline-none transition placeholder:text-graysoft focus:border-primary focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div>
              <label htmlFor="additional_notes" className="mb-2 block text-sm font-semibold text-charcoal">
                Anything else? (optional)
              </label>
              <textarea
                id="additional_notes"
                name="additional_notes"
                rows={3}
                placeholder="Feature requests, bugs, or anything else we should know."
                className="w-full rounded-lg border border-graysoft/40 bg-white px-4 py-3 text-sm text-charcoal outline-none transition placeholder:text-graysoft focus:border-primary focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div className="flex flex-wrap items-center gap-3 pt-2">
              <button type="submit" className="btn-primary">
                Submit
              </button>
              <a href="/dashboard" className="btn-secondary">
                Back to Dashboard
              </a>
            </div>
          </form>
        </section>
      </div>
    </main>
  );
}
