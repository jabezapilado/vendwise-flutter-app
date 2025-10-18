# Testing

This section outlines testing performed for the VendWise mobile application. It includes unit, integration, and manual test cases. The table below is formatted for inclusion in reports and papers; fill in the Actual Output and Pass/Fail columns during execution.

## Testing strategy
- Unit tests: small logical units and helpers.
- Widget tests: verify UI widgets behavior in isolation.
- Integration tests: end-to-end flows involving Supabase (auth, transactions, sync).
- Manual tests: sensor permissions, camera, offline sync, and UX checks.

## Test Case Table

| Test Case ID | Test Case Description | Input | Expected Output | Actual Output | Pass/Fail | Notes |
|---|---|---:|---|---|---|---|
| TC-01 | User sign-in with valid credentials | Email/password | Successful login and navigation to dashboard |  |  |  |
| TC-02 | User sign-in with invalid credentials | Wrong password | Error message shown, no login |  |  |  |
| TC-03 | Create inventory item | Name, SKU, price | Item appears in inventory list |  |  |  |
| TC-04 | Create sale transaction (online) | Product, qty, price | Transaction recorded in DB and shown in dashboard top-10 |  |  |  |
| TC-05 | Create transaction while offline | Product, qty, price (offline) | Transaction saved locally and synced when online |  |  |  |
| TC-06 | Recent transactions inline limit | Many transactions (>10) | Dashboard/Report shows only 10 items inline; "View More" loads full list |  |  |  |
| TC-07 | Dismiss a notification | Notification displayed; user taps dismiss | Notification no longer appears in future sessions |  |  |  |
| TC-08 | Camera permission & barcode scan | Camera permission grant + barcode image | Product scanned and filled in form |  |  |  |
| TC-09 | Build Android release | Build command | AAB produced at `build/app/outputs/bundle/release/app-release.aab` |  |  |  |
| TC-10 | iOS archive and export | Build/archive in Xcode | Archive created; IPA export requires Apple signing |  |  |  |


## Notes on running tests
- Run unit/widget tests with:

```bash
flutter test
```

- Run analyzer before committing changes:

```bash
flutter analyze
```

- For integration tests that require Supabase, ensure environment variables (SUPABASE_URL, SUPABASE_KEY) are set in a secure way.


---

*Document prepared for inclusion in project report.*
