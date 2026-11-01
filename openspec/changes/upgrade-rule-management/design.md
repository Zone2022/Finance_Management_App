## Design
The existing merchant_rules table remains authoritative. Management edits records by ID, preserving the existing longest-keyword and newest-ID precedence. Edits affect future classification only. No rule table migration or destructive initialization is performed.

Upgrade preservation depends on retaining the same application ID and signing certificate and installing over the existing app. SQLite v1/v2 upgrade paths remain unchanged and are tested with existing transactions, categories and rules. Credentials and pending notifications use existing platform storage. Uninstall, app data clearing, incompatible signatures, OS data loss and keystore loss are outside the guarantees of an in-place update.
