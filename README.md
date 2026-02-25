## Exhale Academy

Next.js + Supabase app for TMC and CSE training.

## Local Development

1. Copy env vars:
```bash
cp .env.example .env.local
```
2. Fill values in `.env.local`:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
3. Start local dev:
```bash
npm run dev
```
4. Optional LAN testing on phone (same Wi-Fi):
```bash
npm run dev:lan
```
Then open `http://<your-lan-ip>:3001`.

## Production Deployment (Vercel + Supabase)

### 1. Deploy to Vercel
1. Push repo to GitHub.
2. In Vercel: `Add New Project` -> import repo.
3. Build settings:
- Framework: `Next.js`
- Build command: `npm run build`
- Output: default (`.next`)
4. Add environment variables in Vercel Project Settings:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
5. Deploy.

### 2. Configure Supabase Auth for Public Domain
In Supabase Dashboard -> Authentication -> URL Configuration:
1. Set `Site URL` to your production app URL (example: `https://app.exhaleacademy.com`).
2. Add `Redirect URLs`:
- `https://app.exhaleacademy.com`
- `https://app.exhaleacademy.com/login`
- `https://app.exhaleacademy.com/signup`
- `https://<your-vercel-domain>.vercel.app`
- `https://<your-vercel-domain>.vercel.app/login`
- `https://<your-vercel-domain>.vercel.app/signup`

If you use Vercel Preview Deployments, also add:
- `https://*.vercel.app`

### 3. Domain Setup
1. In Vercel, add your custom domain.
2. Update DNS records at your domain provider as instructed by Vercel.
3. Wait for SSL issuance and verify HTTPS works.

### 4. Post-Deploy Validation
Test from phone over cellular (not only Wi-Fi):
1. Visit home page and login/signup pages.
2. Complete one TMC quiz flow.
3. Complete one CSE case flow.
4. Complete one Master CSE attempt start to first case.

## Notes

- This app uses password-based Supabase auth (`signInWithPassword`, `signUp`).
- For real user phone access, use the public Vercel URL or your custom domain. `localhost` and LAN URLs are not production endpoints.
# exhale-academy
