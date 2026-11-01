## ADDED Requirements

### Requirement: Recognize explicit payment formats
The listener SHALL recognize debit notifications from the approved WeChat, Alipay and China Construction Bank packages, while rejecting refunds and income.

#### Scenario: Screenshot examples
- **WHEN** a Weixin Pay notification contains `¥1.00 paid`, or an Alipay transaction reminder reports `0.01元的支出`
- **THEN** it is queued for import with its source and amount

#### Scenario: Bank account debit
- **WHEN** a China Construction Bank account alert states `支出人民币0.01元`
- **THEN** it is queued as a bank expense

### Requirement: Persist AI settings securely
The application SHALL persist provider selection and keys in device secure storage and hide secrets on the settings page.

#### Scenario: Application restart
- **WHEN** a user saves a provider key and restarts the app
- **THEN** the saved key remains available for classification without being displayed

### Requirement: Explain capture failures
The settings page SHALL expose listener permission, connection state and bounded local diagnostics without persisting notification content or credentials in logs.

#### Scenario: Unsupported notification
- **WHEN** a known source posts a notification that fails the debit format rules
- **THEN** a non-sensitive diagnostic entry explains that the format was not matched
