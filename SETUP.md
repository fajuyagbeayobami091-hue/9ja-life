# 9ja Life setup

## Supabase database

The orders table is in Supabase. For payment recording, run the migration in `supabase/migrations/202611040001_order_payment.sql` once in the Supabase SQL Editor. It adds payment method and payment status fields to existing orders.

## Edge Functions

The deployed `create-order` function verifies menu prices on the server, totals all items, records the payment choice, and saves the order. `track-order` returns the status, total, and payment information for its tracking code. Source files are in `supabase/functions/`.

## Payment options

Customers can choose bank transfer or cash on delivery. Bank transfers go to the OPay/PalmPay account shown at checkout. The app marks transfer payment as pending confirmation; staff must verify the transfer and update `payment_status` to `paid` in Supabase. Cash-on-delivery orders start as unpaid. The site does not process card payments or verify transfers automatically.

## Publish

The website is served from the root `index.html` using GitHub Pages. Supabase project URL and the public anon key are used in the browser. Never put a service-role or secret key in the HTML or GitHub.
