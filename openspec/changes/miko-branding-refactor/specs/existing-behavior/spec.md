## ADDED Requirements

### Requirement: Existing finance behavior
Refactoring SHALL preserve existing finance data, classification precedence and navigation behavior.

#### Scenario: Merchant classification
- **WHEN** a merchant has a matching local rule
- **THEN** its local category takes precedence over AI classification

#### Scenario: Navigation
- **WHEN** the user selects the home shortcut for transactions
- **THEN** the transactions tab opens while the existing tab state is retained
