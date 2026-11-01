## Design
Android recognizes only whitelisted source packages and explicit debit formats. Events remain in the durable queue until acknowledged after database insertion; original event-level idempotency is retained. Logs keep at most 200 metadata-only entries and omit notification contents, amounts, account numbers and secrets.

AI keys are stored via flutter_secure_storage, never prefilled into the settings UI; selection is persisted separately. The local classification rule continues to run first. A selected provider is called only for a nonempty unknown merchant. API failures preserve the existing fallback.

Bank and payment app notices have different event identifiers and may duplicate a transaction. No speculative matching is used because independent equal-value transactions can be legitimate. Users must review duplicates. True device notification and secure storage behavior require on-device tests.
