-- Sample data for Vendwise Supabase tables.
-- Run this after executing schema.sql (either via SQL editor or psql).

insert into public.suppliers (supplier_name, contact_number, email) values
  ('Dairy Supplier Inc', 2225555666, 'dairy@supplier.com'),
  ('Tea Importers', 2225555999, 'tea@supplier.com'),
  ('Fresh Fruits Ltd', 1114444777, 'fruits@supplier.com'),
  ('Sweet Toppings', 8887776666, 'toppings@supplier.com');

insert into public.inventory (product_name, supplier_name, price, quantity, contact_number, email) values
  ('Almond Milk', 'Dairy Supplier Inc', 100.00, 1000, 2225555666, 'dairy@supplier.com'),
  ('Thai Tea Base', 'Tea Importers', 320.00, 250, 2225555999, 'tea@supplier.com'),
  ('Tapioca Pearls', 'Sweet Toppings', 80.00, 750, 8887776666, 'toppings@supplier.com'),
  ('Gardenia Bread', 'Fresh Fruits Ltd', 60.00, 180, 1114444777, 'fruits@supplier.com');

insert into public.products (product_name, product_desc, price_m, price_l, prod_type, image_url) values
  ('Classic Milk Tea', 'Timeless blend of black tea and creamy milk.', 90, 110, 'Drinks', 'https://gmrdkaaqhdbofsybbjyt.supabase.co/storage/v1/object/public/profile-assets/catalog/1760037930305-30841362-fe9d-47b3-8e0d-8c332da650a4.jpg'),
  ('Wintermelon Milk Tea', 'Refreshing sweet tea with a creamy finish.', 95, 115, 'Drinks', 'https://gmrdkaaqhdbofsybbjyt.supabase.co/storage/v1/object/public/profile-assets/catalog/1760037930449-0f9aab0e-2981-46c1-8956-42a1bee12a50.jpg'),
  ('Gardenia Bread', 'Freshly baked loaf.', 120, 0, 'Foods', 'https://gmrdkaaqhdbofsybbjyt.supabase.co/storage/v1/object/public/profile-assets/catalog/1760037929273-c09227d1-8d8d-44cc-b7e9-584a98eb7df1.jpg'),
  ('Fries', 'Crispy seasoned fries.', 35, 0, 'Foods', 'https://gmrdkaaqhdbofsybbjyt.supabase.co/storage/v1/object/public/profile-assets/catalog/1760037931089-e70830a9-c614-499b-a5c4-5210ef197ea9.jpg');

insert into public.transactions (customer_name, item_count, total_amount, time_purchased) values
  ('Louis', 3, 230, now() - interval '2 hours'),
  ('Maurice', 5, 500, now() - interval '90 minutes'),
  ('Rafael', 2, 170, now() - interval '45 minutes'),
  ('Jabez', 10, 800, now() - interval '10 minutes');

insert into public.app_users (username, full_name, email, role, is_active, password_hash)
values
  (
    'admin',
    'Vendwise Admin',
    'admin@vendwise.com',
    'admin',
    true,
    'a69559d8f836b3199f5fcecb1dfc2227b8f4f9f391b64e4f338e7d36dac1afb8'
  ),
  (
    'cashier',
    'Counter Cashier',
    'cashier@vendwise.com',
    'staff',
    true,
    '7e3e6c83384e3818ede41f0401b54952321d3a408225d7bded9619299c38cfd1'
  ),
  (
    'manager',
    'Store Manager',
    'manager@vendwise.com',
    'manager',
    true,
    '5a665a23c139b653cb27e450a5b3bf8cfd510073f39e1d18c6f5028ec4903d56'
  );
