-- Migration: convert integer price columns to numeric with 2 decimal places
-- Run this in the Supabase SQL editor. Make a backup before running in production.

BEGIN;

-- Products: price_m, price_l -> numeric(10,2)
ALTER TABLE public.products
  ALTER COLUMN price_m TYPE numeric(10,2)
    USING (price_m::numeric(10,2)),
  ALTER COLUMN price_l TYPE numeric(10,2)
    USING (price_l::numeric(10,2));

-- Inventory: price already numeric in schema.sql, but include safety in case
-- the deployed DB differs from local schema.sql
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'inventory' AND column_name = 'price'
    AND data_type <> 'numeric'
  ) THEN
    ALTER TABLE public.inventory
      ALTER COLUMN price TYPE numeric(10,2)
        USING (price::numeric(10,2));
  END IF;
END$$;

-- Transactions: total_amount may be integer; convert to numeric if desired
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'transactions' AND column_name = 'total_amount'
    AND data_type <> 'numeric'
  ) THEN
    ALTER TABLE public.transactions
      ALTER COLUMN total_amount TYPE numeric(10,2)
        USING (total_amount::numeric(10,2));
  END IF;
END$$;

COMMIT;
