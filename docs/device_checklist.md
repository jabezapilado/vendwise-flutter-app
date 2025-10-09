# Device Verification Checklist

## Android
1. **Emulator/Device prep**
   - Android 13 or later recommended.
   - Enable internet so Supabase tests can reach the backend.
2. **Build & run**
   ```bash
   flutter run -d android
   ```
3. **Smoke tests**
   - Login via seeded admin account.
   - Navigate through Dashboard → Inventory → Products, verifying no missing assets.
   - Add a product with an image (verifies FilePicker + Supabase upload).
   - Remove the product image (verifies cleanup flags).
4. **Supabase fallback**
   - Temporarily disconnect network and relaunch. Confirm mock repository loads without crash.

## iOS
1. **Device prep**
   - iOS 17 simulator or physical device with development certificate installed.
   - Configure `.env` for production or staging Supabase credentials.
2. **Build & run**
   ```bash
   flutter run -d ios
   ```
3. **Smoke tests**
   - Validate navigation between tab sections using the bottom bar.
   - Execute a dummy transaction from the Transactions screen.
   - Confirm push-button visuals and fonts render (Inter + Kaushan Script).
4. **IPA generation**
   - Follow `FOOLPROOF_IPA_GUIDE.md` for final packaging.

## Post-run
- Capture screenshots for release notes if UI changed.
- File bugs or TODOs in `analysis/backlog_summary.md`.
