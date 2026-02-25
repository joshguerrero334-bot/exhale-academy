# Category Taxonomy Setup (Table Editor Only)

## 1) Create `categories` table
1. Open Supabase Dashboard.
2. Go to **Table Editor**.
3. Click **Create a new table**.
4. Table name: `categories`.
5. Add columns:
   - `id` → `int8` → **Identity** → Primary Key.
   - `slug` → `text` → Required.
   - `name` → `text` → Required.
   - `sort_order` → `int4` → Required.
   - `is_active` → `bool` → Default `true`.
6. Save table.
7. In **Table Editor**, add a **Unique constraint** for `slug`.

## 2) Add `category_slug` to `questions`
1. Open `questions` table in Table Editor.
2. Click **Add column**.
3. Column name: `category_slug`.
4. Type: `text`.
5. Mark as Required (Not Null) after data backfill is complete.
6. Save.
7. Keep existing `category` column for now.

## 3) Import category taxonomy CSV
1. Download `/categories.csv` from app or use `public/categories.csv`.
2. In Supabase Table Editor, open `categories`.
3. Click **Insert** → **Import data from CSV**.
4. Upload `categories.csv`.

## 4) Backfill existing questions
1. Export `questions` from Table Editor as CSV.
2. Run:
   - `node scripts/backfill-category-slug.mjs input.csv output.csv`
3. Re-import `output.csv` into `questions` (upsert/update in Table Editor).
4. Confirm `category_slug` is populated.

## 5) Validation
1. Open `/admin/tools` and confirm headers.
2. Open `/dashboard` and verify category cards show slug-based counts.
3. Open `/quiz/oxygenation` and verify 10-question flow loads.
