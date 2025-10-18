# VendWise Backlog Snapshot (2025-10-10)

## Code-level TODOs
- `lib/screens/inventory/update_inventory_screen.dart`: Replace legacy dropdown widget with `DropdownMenu` once the app targets Flutter 3.33+.
- `lib/screens/products/update_product_screen.dart`: Migrate dropdown input to controller-based API introduced in newer Flutter releases.

## README "Next steps" references
- Wire the CRUD forms (`AddProduct`, `AddInventory`, etc.) to real Supabase mutations.
- Expand Supabase Storage integration beyond the seeded catalog (e.g., enable updating photos in app).
- Tighten Row Level Security policies before production deployment.
- Add offline caching to keep the app usable without a network connection.

## Additional opportunities
- Review Supabase SQL policies for principle-of-least-privilege hardening.
- Audit the new `tool/` scripts for automation opportunities (e.g., scheduled storage cleanup).
- Capture user feedback from the reorganized UI to prioritize UX polish in the next iteration.
