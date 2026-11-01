## ADDED Requirements

### Requirement: Preserve data in supported upgrades
When installed over a compatible version with the same Android application ID and signing certificate, the application SHALL preserve the existing local database and apply non-destructive migrations.

#### Scenario: Upgrade a v2 database
- **WHEN** an existing v2 database is opened by the current app
- **THEN** transactions, categories and merchant rules remain available and amounts are migrated to integer cents

#### Scenario: Incompatible signing certificate
- **WHEN** a different certificate is used
- **THEN** Android can reject the update and the application SHALL NOT silently uninstall or erase the old data
