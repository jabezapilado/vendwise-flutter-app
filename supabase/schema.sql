-- Supabase schema setup for the Vendwise app.
-- Run this script in the Supabase SQL editor after creating your project.

-- Enable useful extensions (already available in Supabase, but harmless if re-run).
create extension if not exists "uuid-ossp";
create extension if not exists pgcrypto;

-- INVENTORY -----------------------------------------------------------------
create table if not exists public.inventory (
  id uuid primary key default uuid_generate_v4(),
  product_name text not null,
  supplier_name text,
  price numeric(10, 2) default 0,
  quantity integer default 0,
  contact_number bigint,
  email text,
  expiry_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_inventory_product_name on public.inventory (product_name);

-- SUPPLIERS ------------------------------------------------------------------
create table if not exists public.suppliers (
  id uuid primary key default uuid_generate_v4(),
  supplier_name text not null,
  contact_number bigint,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_suppliers_name on public.suppliers (supplier_name);

-- PRODUCTS -------------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default uuid_generate_v4(),
  product_name text not null,
  product_desc text,
  price_m integer default 0,
  price_l integer default 0,
  prod_type text,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_products_type on public.products (prod_type);

-- TRANSACTIONS ---------------------------------------------------------------
create table if not exists public.transactions (
  id uuid primary key default uuid_generate_v4(),
  customer_name text,
  item_count integer default 0,
  total_amount integer default 0,
  time_purchased timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_time on public.transactions (time_purchased desc);

-- APP USERS ------------------------------------------------------------------
create table if not exists public.app_users (
  id uuid primary key default uuid_generate_v4(),
  username text not null unique,
  full_name text,
  email text,
  role text default 'staff',
  is_active boolean default true,
  password_hash text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_app_users_username on public.app_users (username);
create index if not exists idx_app_users_role on public.app_users (role);

-- TIMESTAMP TRIGGERS ---------------------------------------------------------
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger handle_inventory_updated_at
before update on public.inventory
for each row execute procedure public.handle_updated_at();

create trigger handle_suppliers_updated_at
before update on public.suppliers
for each row execute procedure public.handle_updated_at();

create trigger handle_products_updated_at
before update on public.products
for each row execute procedure public.handle_updated_at();

create trigger handle_transactions_updated_at
before update on public.transactions
for each row execute procedure public.handle_updated_at();

create trigger handle_app_users_updated_at
before update on public.app_users
for each row execute procedure public.handle_updated_at();

-- ROW LEVEL SECURITY ---------------------------------------------------------
-- Supabase enables RLS automatically; define policies for anon access.

alter table public.inventory enable row level security;
alter table public.suppliers enable row level security;
alter table public.products enable row level security;
alter table public.transactions enable row level security;
alter table public.app_users enable row level security;

-- Replace these policies with tighter rules before production.
create policy "Allow anon read inventory" on public.inventory
  for select using (auth.role() = 'anon');

create policy "Anon manage inventory" on public.inventory
  for all using (auth.role() = 'anon')
  with check (auth.role() = 'anon');

create policy "Allow anon read suppliers" on public.suppliers
  for select using (auth.role() = 'anon');

create policy "Anon manage suppliers" on public.suppliers
  for all using (auth.role() = 'anon')
  with check (auth.role() = 'anon');

create policy "Allow anon read products" on public.products
  for select using (auth.role() = 'anon');

create policy "Anon manage products" on public.products
  for all using (auth.role() = 'anon')
  with check (auth.role() = 'anon');

create policy "Allow anon read transactions" on public.transactions
  for select using (auth.role() = 'anon');

create policy "Anon manage transactions" on public.transactions
  for all using (auth.role() = 'anon')
  with check (auth.role() = 'anon');

create policy "Allow anon read app users" on public.app_users
  for select using (auth.role() = 'anon');

create policy "Anon manage app users" on public.app_users
  for all using (auth.role() = 'anon')
  with check (auth.role() = 'anon');

-- Optional: allow inserts/updates from authenticated users (adjust as needed).
create policy "Authenticated manage inventory" on public.inventory
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Authenticated manage suppliers" on public.suppliers
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Authenticated manage products" on public.products
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Authenticated manage transactions" on public.transactions
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "Authenticated manage app users" on public.app_users
  for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- You can tighten policies later (e.g., role-based checks, ownership filtering).
