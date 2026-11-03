# Connect 9ja Life to Supabase

The website is configured with your Supabase project URL and browser-safe anon key. The anon key is public by design; Row Level Security is enabled and no public table access policies are created. The service-role/secret key is never put in the website. Order create/lookup calls run through Edge Functions.

## Deploy the database and functions

1. Instathen open PowerShell in this app folder.
2. Install the Supabase CLI: `npm install --global supabase`.
3. Sign in: `supabase login`.
4. Link your project: `supabase link --project-ref tqkyplmasxrwbjbqgdpc`.
5. Apply the schema: `supabase db push`.
6. Deploy both functions: `supabase functions deploy create-order` and `supabase functions deploy track-order`.

The functions use Supabase's server-provided secret key environment variable. Do not add a service-role/secret key to GitHub, this HTML file, or a .env file that gets committed.

## Staff order updates

In Supabase Dashboard → Table Editor → `orders`, staff can change `status` to `preparing`, `ready`, `on_the_way`, `delivered`, or `cancelled`. Customers who have enabled browser notifications and are tracking their code receive an update as the status changes. For phone/SMS or updates when the page is closed, connect a notification provider and server-side webhook later.

## Publish with GitHub

Create a GitHub repository, then upload `outputs/index.html`, `supabase/`, and this file (or move the app files to the repository root). The project has no Git remote configured yet, so it has not been pushed. You can host the static page with GitHub Pages after placing `index.html` at the repository root.

## Notes

Order records include customer phone and delivery address. Restrict Supabase dashboard access to trusted staff. The public tracking code is random and only returns the order status and total needed by the tracker.
