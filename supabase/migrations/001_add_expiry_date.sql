-- Migration: add expiry_date to inventory (idempotent)
-- Run this in Supabase SQL editor or via psql against your database.

-- Add column if missing
ALTER TABLE public.inventory
ADD COLUMN IF NOT EXISTS expiry_date timestamptz;

-- Optional: backfill expiry_date for existing rows if you want a default
-- Example: set expiry_date to 90 days from created_at for rows without expiry
-- UPDATE public.inventory
-- SET expiry_date = created_at + interval '90 days'
-- WHERE expiry_date IS NULL;

-- Example seed adjustments (run only if you want to set sample expiry values):
-- INSERT INTO public.inventory (product_name, supplier_name, price, quantity, contact_number, email, expiry_date)
-- VALUES ('Sample Item', 'Sample Supplier', 10.00, 100, 1112223333, 'sample@supplier.com', now() + interval '180 days');

-- NOTE: You should backup your data or run in staging if unsure.
