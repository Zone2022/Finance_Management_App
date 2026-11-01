## Why
Users need their existing local ledger to survive ordinary app updates, and need to inspect and adjust the local merchant classification rules.

## What Changes
- Add settings navigation for searching, adding, editing and deleting merchant rules.
- Preserve existing database schema and migration paths; add upgrade regression coverage.
- Increment Android version code for a signed upgrade build.

## Capabilities
### New Capabilities
- `merchant-rules`: Manage persisted merchant rules without rewriting existing transactions.
- `upgrade-continuity`: Preserve existing local data in supported same-signature upgrades.
### Modified Capabilities
- None; prior baseline specs have not yet been archived.

## Impact
Settings, rule repository, tests and build version; package ID and existing financial data format remain unchanged.
