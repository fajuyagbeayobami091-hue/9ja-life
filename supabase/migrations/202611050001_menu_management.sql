create table if not exists public.restaurant_staff (
  user_id uuid primary key references auth.users(id) on delete cascade,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.restaurant_staff enable row level security;
grant select on public.restaurant_staff to authenticated;
drop policy if exists "Staff can read own membership" on public.restaurant_staff;
create policy "Staff can read own membership"
  on public.restaurant_staff for select to authenticated
  using (user_id = auth.uid());

create table if not exists public.menu_items (
  slug text primary key check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  name text not null check (length(trim(name)) between 2 and 100),
  description text not null default '',
  category text not null default 'Mains',
  price_ngn integer not null check (price_ngn > 0),
  rating numeric(2,1) not null default 4.8 check (rating between 0 and 5),
  tag text not null default 'Fresh today',
  image_url text not null default '',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.menu_items enable row level security;
grant select on public.menu_items to anon, authenticated;
grant insert, update on public.menu_items to authenticated;
drop policy if exists "Customers can view active menu items" on public.menu_items;
create policy "Customers can view active menu items"
  on public.menu_items for select to anon, authenticated
  using (active = true);
drop policy if exists "Restaurant staff can view all menu items" on public.menu_items;
create policy "Restaurant staff can view all menu items"
  on public.menu_items for select to authenticated
  using (exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ));
drop policy if exists "Restaurant staff can add menu items" on public.menu_items;
create policy "Restaurant staff can add menu items"
  on public.menu_items for insert to authenticated
  with check (exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ));
drop policy if exists "Restaurant staff can edit menu items" on public.menu_items;
create policy "Restaurant staff can edit menu items"
  on public.menu_items for update to authenticated
  using (exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ))
  with check (exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ));

insert into public.menu_items(slug,name,description,category,price_ngn,rating,tag,image_url) values
 ('party-jollof-chicken','Party Jollof & Chicken','Smoky party rice, grilled chicken & fried plantain.','Rice',4800,4.9,'Customer favourite','https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=700&q=80'),
 ('suya-beef-skewers','Suya Beef Skewers','Peppery yaji-spiced beef, onions & fresh tomatoes.','Mains',3500,4.8,'A little heat','https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?auto=format&fit=crop&w=700&q=80'),
 ('puff-puff','Puff Puff (6 pcs)','Golden, pillowy bites dusted with a little sugar.','Small chops',1800,4.9,'Sweet & fluffy','https://images.unsplash.com/photo-1600617953089-9cf5c2ed9ca3?auto=format&fit=crop&w=700&q=80'),
 ('small-chops-box','Small Chops Box','Samosa, spring roll, puff puff & spicy gizzard.','Small chops',4200,5.0,'Perfect for sharing','https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=700&q=80'),
 ('egusi-pounded-yam','Egusi & Pounded Yam','Rich melon seed soup with soft, stretchy pounded yam.','Mains',5200,4.9,'Homestyle','https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=700&q=80'),
 ('ofada-ayamase','Ofada Rice & Ayamase','Unpolished rice with bold green pepper sauce.','Rice',4600,4.8,'Local favourite','https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=700&q=80'),
 ('zobo-cooler','Zobo Cooler','Chilled hibiscus, ginger & pineapple refreshment.','Drinks',1200,4.7,'House-made','https://images.unsplash.com/photo-1546173159-315724a31696?auto=format&fit=crop&w=700&q=80'),
 ('grilled-chicken-suya','Grilled Chicken Suya','Chargrilled chicken with our signature suya spice.','Mains',3900,4.8,'Smoky & spicy','https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=700&q=80')
on conflict (slug) do nothing;

insert into storage.buckets(id,name,public)
values ('menu-photos','menu-photos',true)
on conflict (id) do nothing;

drop policy if exists "Public can view menu photos" on storage.objects;
create policy "Public can view menu photos"
  on storage.objects for select to anon, authenticated
  using (bucket_id = 'menu-photos');
drop policy if exists "Restaurant staff can upload menu photos" on storage.objects;
create policy "Restaurant staff can upload menu photos"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'menu-photos' and exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ));
drop policy if exists "Restaurant staff can replace menu photos" on storage.objects;
create policy "Restaurant staff can replace menu photos"
  on storage.objects for update to authenticated
  using (bucket_id = 'menu-photos' and exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ))
  with check (bucket_id = 'menu-photos' and exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ));
drop policy if exists "Restaurant staff can remove menu photos" on storage.objects;
create policy "Restaurant staff can remove menu photos"
  on storage.objects for delete to authenticated
  using (bucket_id = 'menu-photos' and exists (
    select 1 from public.restaurant_staff s
    where s.user_id = auth.uid() and s.active = true
  ));
