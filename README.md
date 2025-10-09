# Vendwise

Flutter-based inventory and point-of-sale companion app.

## Prerequisites

- Flutter 3.35.5 (or newer on stable channel)
- Supabase account (free tier is fine)
- Dart 3.8 SDK (bundled with Flutter)

## Local setup

1. Clone the repository and install dependencies:
	```bash
	flutter pub get
	```
2. Copy the environment file and add your Supabase keys:
	```bash
	cp .env.example .env
	```
	Fill in `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and adjust `SUPABASE_STORAGE_BUCKET` if you rename the bucket.
	The app also expects `SUPABASE_SERVICE_EMAIL` and `SUPABASE_SERVICE_PASSWORD` to point to a Supabase Auth
	account that has permission to write to your tables (a shared "service" login is recommended).
3. Run the analyzer and widget tests to ensure the project is healthy:
	```bash
	flutter analyze
	flutter test
	```
	If you prefer a one-click sync back to GitHub, make the helper script executable and supply a commit message (or let it pick a timestamp):
	```bash
	chmod +x tool/quick_push.sh
	./tool/quick_push.sh "Refactor screen structure"
	# or simply
	./tool/quick_push.sh
	```
	The script stages every change, creates a commit (skipping if there is nothing to commit), and pushes to whatever branch you are currently on.
	If you only need to verify Supabase connectivity (e.g., after updating the
	schema or rotating credentials), run the targeted smoke test:
	```bash
	flutter test test/supabase_connection_test.dart
	```
	To confirm the shared service account can create, update, and delete rows, run the permissions diagnostic:
	```bash
	flutter test test/supabase_permissions_test.dart
	```

## Supabase setup

1. Create a new project at [app.supabase.com](https://app.supabase.com) and note the project URL and anon public key (Project Settings → API).
2. In the Supabase dashboard, open the SQL editor and run the scripts:
				- `supabase/schema.sql` – creates the tables, indexes, triggers, and RLS policies.
				- `supabase/seed.sql` – inserts sample suppliers, inventory, products, and transactions (optional).
					The seed also provisions three application accounts in `public.app_users` (admin, manager,
					cashier) so you can immediately log in or display staff lists.
				- (Optional) `supabase/enable_full_access_policies.sql` – grants temporary full read/write access to every
					table for the `anon`, `authenticated`, and `service_role` roles. Run it only for diagnostics or demos and
					revert to the stricter policies in `schema.sql` before going to production.

### Demo credentials

The seed script inserts three staff accounts. Passwords are stored in the database as salted SHA-256
hashes (see `lib/backend/password_hasher.dart`), but you can log in with the following credentials:

| Role     | Username | Email                   | Password    |
|----------|----------|-------------------------|-------------|
| Admin    | admin    | admin@vendwise.com      | admin123    |
| Manager  | manager  | manager@vendwise.com    | manager123  |
| Cashier  | cashier  | cashier@vendwise.com    | cashier123  |

Feel free to delete or change these accounts after setup. If you update a password directly in the
database, be sure to hash it with the helper before writing the value to `password_hash`.
3. Enable Email/Password authentication (Authentication → Providers) if you plan to let users sign in. You can invite an admin account, e.g. `Admin@gmail.com`, from Authentication → Users → Invite user.
4. (Optional) Create a Storage bucket named `profile-assets` (or adjust the `.env` bucket value) if you plan to upload product images or profile photos.
5. (Optional) Migrate bundled product images into Supabase Storage by running:
	```bash
	flutter pub run tool/migrate_assets_to_supabase.dart
	```
	The script uploads every file under `assets/images` and writes `build/migrated_assets.json` with the public URLs so you can update your seed data or database rows. The app automatically loads this manifest at startup to hydrate mock data, so new uploads appear without editing source code. Core UI icons such as the logo and dashboard glyphs live under `assets/icons/` so they stay available offline; keep that directory synced manually if you change those assets.

## Product image workflow

- Both `AddProductScreen` and `UpdateProductScreen` let staff attach a product photo directly from the device via **FilePicker**. The UI shows a live preview of the selected image and exposes a “Clear selection” button to undo the choice before saving.
- When Supabase is connected (`supabaseRepositoryActive == true`) the selected file is uploaded to the bucket defined by `SUPABASE_STORAGE_BUCKET` (defaults to `profile-assets`) using `StorageService.uploadPlatformFile`. The resulting public URL is persisted on the product record.
- If Supabase is unavailable or the bucket isn’t configured, the form keeps working: it skips the upload, surfaces a snackbar explaining what happened, and proceeds without changing the image.
- On the update screen, choosing **Remove image** clears the stored URL and sets the `ProductDraft.clearImage` flag so the backend deletes the existing asset reference. No storage deletion is triggered automatically; run `tool/cleanup_supabase_storage.dart` periodically to prune unused files if needed.
- All form submissions validate prices, categories, and descriptions before calling the repository. Spinners and disabled buttons prevent duplicate submissions while uploads are in flight.

## Maintenance scripts

- Preview which Supabase Storage objects would be deleted:
	```bash
	dart run tool/cleanup_supabase_storage.dart --dry-run
	```
- Remove stray/duplicate storage objects (after reviewing the dry run):
	```bash
	dart run tool/cleanup_supabase_storage.dart
	```
- List manifest entries and filter for a specific file:
	```bash
	dart run tool/inspect_manifest.dart --counts
	```
- View a single asset’s URL:
	```bash
	dart run tool/inspect_manifest.dart --file=Classic_Milk_Tea.jpg
	```

Both commands rely on `.env` for credentials and the manifest generated by the migration script. They help keep Supabase Storage aligned with assets the application actually references.

For an at-a-glance maintenance calendar, see `supabase/MAINTENANCE.md`.

## Running the app

With `.env` populated and Supabase reachable, start the application on a device or emulator:
```bash
flutter run
```
If Supabase initialization fails (e.g., missing keys or no network), the app gracefully falls back to the mock in-memory repository so you can continue development offline.

For smoke-test scenarios on Android and iOS, follow `docs/device_checklist.md`.

### Startup health checks

On launch the app uses `initializeBackend()` to load `.env`, initialize
Supabase once, and confirm that the required tables (`inventory`,
`suppliers`, `products`, `transactions`, `app_users`) plus the optional
`SUPABASE_STORAGE_BUCKET` are available. If any prerequisite is missing it keeps
the mock repository active and logs a concise summary with the exact gap so you
know what to fix.

## Next steps

- Review the running backlog summary in `analysis/backlog_summary.md` for code-level TODOs and roadmap candidates.
- Wire CRUD forms (`AddProduct`, `AddInventory`, etc.) to call Supabase mutations instead of just navigating back.
- Expand Supabase Storage usage beyond the seeded catalog (e.g., allow staff to update product photos in-app).
- Harden Row Level Security policies before production (restrict to specific roles or owners).
- Add offline caching if the app needs to work without an internet connection.

## Continuous integration

A GitHub Actions workflow (`.github/workflows/flutter.yml`) runs `flutter pub get`, `flutter analyze`, and `flutter test` on every push or pull request to `main`, ensuring the manifest tooling and Supabase checks stay healthy.
