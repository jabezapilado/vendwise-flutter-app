# Supabase Maintenance Checklist

_Last updated: 2025-10-10_

## Weekly
- **Storage cleanup (dry-run)**
  ```bash
  dart run tool/cleanup_supabase_storage.dart --dry-run
  ```
  Review output for any files that are no longer referenced by the database.
- **Manifest spot-check**
  ```bash
  dart run tool/inspect_manifest.dart --counts
  ```
  Ensure total counts match expectations for product imagery and downloadable assets.

## Bi-weekly
- **Purge unused storage objects** (only after verifying the dry-run report):
  ```bash
  dart run tool/cleanup_supabase_storage.dart
  ```
- **Sync seed data**: if `supabase/seed.sql` changed, rerun it in a staging project and confirm migrations.

## Monthly
- **Rotate service credentials**: update `SUPABASE_SERVICE_EMAIL` and `SUPABASE_SERVICE_PASSWORD` in `.env` and Supabase Auth.
- **Policy audit**: re-run `supabase/enable_full_access_policies.sql` only in a controlled environment for diagnostics, then revert to the locked-down policies in `supabase/schema.sql`.
- **Backup**: export schema and storage assets via the Supabase dashboard.

## Before production releases
- Run the full Flutter test suite (`flutter test`).
- Regenerate any assets via `tool/migrate_assets_to_supabase.dart` if new imagery was added locally.
- Confirm Row Level Security rules still match business requirements.
