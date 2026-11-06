# 9ja Life setup

## Supabase database

Run these files once in the Supabase SQL Editor, in this order:

1. `supabase/migrations/202611030001_create_orders.sql` (skip if the `orders` table already exists).
2. `supabase/migrations/202611040001_order_payment.sql` (skip if payment columns already exist).
3. `supabase/migrations/202611050001_menu_management.sql`.

The menu migration seeds the current menu, creates the protected menu table and photo bucket, and adds staff-only write policies. Customers can read only active menu items. Orders still go through Edge Functions.

## Customer email or phone-code accounts

The account panel lets a customer choose either an email address or a phone number as their sign-in method. They enter a name and one contact method; Supabase Auth creates or signs in the account and verifies that selected contact with an OTP. Enter phone numbers in international format, such as `+2348012345678`.

In Supabase Dashboard → Authentication:

1. Under **Sign In / Providers**, enable Email and Phone.
2. Under **Emails → SMTP Settings**, configure a custom SMTP service for email delivery. The default Supabase email service is only for project-team testing and is limited; it is not for sending codes to public customers.
3. Under **Emails → Templates**, edit both **Confirm signup** and **Magic Link or OTP** to show the email code. Include `{{ .Token }}` in the message, for example: `<p>Your 9ja Life confirmation code is <strong>{{ .Token }}</strong>.</p>`. Customers enter this code in the app.
4. In the Phone provider settings, choose and configure a supported SMS provider with its credentials. SMS delivery can incur provider charges. Then test with a phone number you control.

A customer can receive an email code at Gmail or another email service. Phone codes are sent by the configured SMS provider. The app stores the login session in the customer's browser. The current delete-data button logs out and clears that browser's saved profile and preferences; it does not delete the Supabase Auth user or existing order records.

## Restaurant staff access

1. In Supabase Dashboard → Authentication → Users, create an account for each trusted staff member.
2. In the SQL Editor, add each staff user's Auth user ID to `public.restaurant_staff` and leave `active` set to `true`. For example:

   ```sql
   insert into public.restaurant_staff (user_id, active)
   select id, true from auth.users where email = 'staff@example.com'
   on conflict (user_id) do update set active = true;
   ```

3. After GitHub Pages is updated, staff sign in at `https://fajuyagbeayobami091-hue.github.io/9ja-life/admin.html`.

The staff page lets staff add menu items, upload JPG/PNG/WebP photos up to 5 MB, edit descriptions/categories/prices, and hide or show items. Do not give staff Supabase owner or service-role credentials.

## Edge Functions

Deploy `supabase/functions/create-order/index.ts` to the existing `create-order` Edge Function after the menu migration. It reads current active prices from `menu_items`, calculates the order total on the server, and saves the order. Deploy `supabase/functions/track-order/index.ts` to the existing `track-order` function if its deployed version does not return `payment_status`.

## Payments and notifications

The current fixed OPay/PalmPay transfer account does not automatically report deposits to the app. Staff must verify a transfer and set the order's `payment_status` to `paid` in Supabase. When the order moves onto a bike, staff set `status` to `on_the_way`.

The customer must allow browser notifications and keep the tracking page open to receive these updates. The site does not yet send Web Push after the page is closed. Automatic payment confirmation needs a merchant payment provider and a signed webhook. Background phone notifications need a push subscription and a server-side Web Push sender. Store payment-provider secrets and private VAPID keys in Supabase secrets, never in HTML or GitHub.

Customers can opt into menu price alerts in App preferences. While the customer has the site open, it refreshes the active menu every 30 seconds and sends a browser notification when a price changes. It cannot notify customers while the site is closed; that requires Web Push subscriptions and a server-side sender.

## Publish

GitHub Pages serves the root `index.html`; `admin.html` is the staff menu page and `sw.js` displays and routes supported browser notifications. Push commits to the `main` branch to publish these files.

Only the Supabase anon key belongs in browser code. Never put a service-role or secret key in HTML or GitHub.
