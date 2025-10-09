# Next Iteration Plan

## Goals
1. **Transactional Supabase integration**
   - Replace mock navigation-only flows with real CRUD mutations for inventory, products, suppliers, and transactions.
   - Add optimistic UI updates and toast confirmations.
2. **Image lifecycle management**
   - Allow in-app deletion of Supabase Storage objects tied to a product when removing an image.
   - Surface upload progress indicators and retry options.
3. **Access control hardening**
   - Implement role-based screens (admin, manager, cashier) with guard clauses and restricted navigation.
   - Tighten Row Level Security policies to reflect role capabilities.
4. **Offline readiness**
   - Cache inventory and product data locally using `sqflite` or `drift`.
   - Queue offline mutations to sync when connectivity returns.

## Supporting tasks
- Expand widget and integration tests for the new CRUD flows.
- Monitor Supabase CPU/storage usage and adjust policies if limits are near.
- Gather beta feedback from store operators on the reorganized UI.
