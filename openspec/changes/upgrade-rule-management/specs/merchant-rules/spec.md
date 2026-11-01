## ADDED Requirements

### Requirement: Manage local classification rules
Users SHALL be able to search, add, edit and delete merchant keyword rules from settings. Changes SHALL affect subsequent classifications only.

#### Scenario: Modify a rule
- **WHEN** a user changes a merchant keyword's category
- **THEN** future matching transactions use the new category and existing transactions remain unchanged

#### Scenario: Search rules
- **WHEN** the user searches by keyword or category
- **THEN** matching persisted rules are displayed in classification precedence order
