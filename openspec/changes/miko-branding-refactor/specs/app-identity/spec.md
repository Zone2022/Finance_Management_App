## ADDED Requirements

### Requirement: Miko Finance display name
The app SHALL display the name Miko Finance on supported platform launchers and in application metadata without changing its application identifiers.

#### Scenario: Android launcher
- **WHEN** the application is installed on Android
- **THEN** the launcher displays Miko Finance and the supplied character-inspired static icon

### Requirement: Legible launcher artwork
Launcher icons SHALL use a static, simplified cartoon interpretation of the supplied image and remain recognizable at small sizes.

#### Scenario: Launcher mask
- **WHEN** Android applies a launcher mask
- **THEN** the character remains centered within the visible area
