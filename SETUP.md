# 9ja Life setup

## Supabase database

The orders table is in Supabase. For payment recording, run the migration in `supabase/migrations/202611040001_order_payment.sql` once in the Supabase SQL Editor. It adds payment method and payment status fields to existing orders.

## Edge Functions

The deployed `create-order` function verifies menu prices on the server, totals all items, records the payment choice, and saves the order. `track-order` returns the status, total, and payment information for its tracking code. Source files are in `supabase/functions/`.

## Payment options

Customers can choose bank transfer or cash on delivery. Bank transfers go to the OPay/PalmPay account shown at checkout. The current fixed account number does not send an automatic payment event to the app, so staff must verify the transfer and set `payment_status` to `paid` in Supabase. Cash-on-delivery orders start as unpaid.

## Customer order notifications

The tracker checks for order and payment changes every 10 seconds while the customer keeps the tracking page open. The customer must allow browser notifications. When staff marks payment as paid, the tracker shows “Payment received successfully” and sends a notification. When staff changes status to `on_the_way`, the app shows a scooter symbol and sends an on-the-way notification. Clicking a notification returns to the tracker. The site does not yet send push notifications after the customer closes the page.

For automatic bank confirmation, integrate a merchant payment provider that verifies incoming payments and sends a signed server webhook. For notifications while the site is closed, add a Web Push subscription flow and a server-side push sender with protected VAPID keys. Never place payment-provider secrets or private push keys in the website HTML or GitHub.

## Publish

The website is served from the root `index.html` using GitHub Pages. Supabase project URL and the public anon key are used in the browser. Never put a service-role or secret key in the HTML or GitHub.
