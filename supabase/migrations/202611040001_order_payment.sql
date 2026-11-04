alter table public.orders add column if not exists payment_method text not null default 'cash_on_delivery' check (payment_method in ('bank_transfer','cash_on_delivery'));
alter table public.orders add column if not exists payment_status text not null default 'unpaid' check (payment_status in ('unpaid','pending_confirmation','paid','failed'));
