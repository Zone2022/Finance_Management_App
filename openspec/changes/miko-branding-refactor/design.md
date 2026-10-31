## Context

This is an existing local-first Flutter finance app. Android is the primary tested platform. Existing repository mirrors and lockfile edits must be retained.

## Goals / Non-Goals

Preserve financial behavior, existing data, application identifiers, notification channel and navigation. Clarify control flow and add specs. Launcher image is a static cartoon interpretation; platform masks may crop the edges. This change does not implement animated launcher icons or add features.

## Decisions

Use explicit navigation constants and helper methods and keep classification precedence and fallbacks unchanged. Use a single reviewed square source illustration to generate platform-specific launcher sizes. Keep the original Android package and iOS bundle identifiers to preserve upgrade compatibility.

## Risks / Verification

Visual launcher crop and platform builds require device verification. Run Dart format, analyzer and existing tests; run Android debug build and inspect emulator when available. No network secrets or generated build output are committed.
