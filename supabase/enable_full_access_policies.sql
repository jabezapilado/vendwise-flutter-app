-- Run this script in the Supabase SQL Editor to grant broad read/write access
-- to every application table. It resets existing policies and allows both
-- anonymous (anon) and authenticated (logged-in) users to perform all actions.

-- INVENTORY -----------------------------------------------------------------
alter table public.inventory enable row level security;

drop policy if exists "Anon manage inventory" on public.inventory;
drop policy if exists "Allow anon read inventory" on public.inventory;
drop policy if exists "Authenticated manage inventory" on public.inventory;
drop policy if exists "Open access inventory" on public.inventory;

create policy "Open access inventory" on public.inventory
  for all
  using (auth.role() in ('anon', 'authenticated', 'service_role'))
  with check (auth.role() in ('anon', 'authenticated', 'service_role'));

-- SUPPLIERS ------------------------------------------------------------------
alter table public.suppliers enable row level security;

drop policy if exists "Anon manage suppliers" on public.suppliers;
drop policy if exists "Allow anon read suppliers" on public.suppliers;
drop policy if exists "Authenticated manage suppliers" on public.suppliers;
drop policy if exists "Open access suppliers" on public.suppliers;

create policy "Open access suppliers" on public.suppliers
  for all
  using (auth.role() in ('anon', 'authenticated', 'service_role'))
  with check (auth.role() in ('anon', 'authenticated', 'service_role'));

-- PRODUCTS -------------------------------------------------------------------
alter table public.products enable row level security;

drop policy if exists "Anon manage products" on public.products;
drop policy if exists "Allow anon read products" on public.products;
drop policy if exists "Authenticated manage products" on public.products;
drop policy if exists "Open access products" on public.products;

create policy "Open access products" on public.products
  for all
  using (auth.role() in ('anon', 'authenticated', 'service_role'))
  with check (auth.role() in ('anon', 'authenticated', 'service_role'));

-- TRANSACTIONS ---------------------------------------------------------------
alter table public.transactions enable row level security;

drop policy if exists "Anon manage transactions" on public.transactions;
drop policy if exists "Allow anon read transactions" on public.transactions;
drop policy if exists "Authenticated manage transactions" on public.transactions;
drop policy if exists "Open access transactions" on public.transactions;

create policy "Open access transactions" on public.transactions
  for all
  using (auth.role() in ('anon', 'authenticated', 'service_role'))
  with check (auth.role() in ('anon', 'authenticated', 'service_role'));

-- APP USERS ------------------------------------------------------------------
alter table public.app_users enable row level security;

drop policy if exists "Anon manage app users" on public.app_users;
drop policy if exists "Allow anon read app users" on public.app_users;
drop policy if exists "Authenticated manage app users" on public.app_users;
drop policy if exists "Open access app users" on public.app_users;

create policy "Open access app users" on public.app_users
  for all
  using (auth.role() in ('anon', 'authenticated', 'service_role'))
  with check (auth.role() in ('anon', 'authenticated', 'service_role'));
