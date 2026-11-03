create extension if not exists pgcrypto;
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  tracking_code text not null unique,
  customer_name text not null,
  phone text not null,
  delivery_address text not null,
  items jsonb not null,
  total_ngn integer not null check (total_ngn > 0),
  status text not null default 'received' check (status in ('received','preparing','ready','on_the_way','delivered','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.orders enable row level security;
-- No public table policies: all customer operations go through Edge Functions.

create or replace function public.touch_order_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at before update on public.orders for each row execute function public.touch_order_updated_at();
