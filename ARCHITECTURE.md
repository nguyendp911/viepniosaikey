# ViePN AI Keyboard — Source map

- `Sources/App/ContentView.swift`: host state, lifecycle, dashboard composition.
- `Sources/App/Navigation`, `Components`, `Couple`, `AI`, `KeyboardStudio`, `Profiles`, `Setup`: feature views and helpers.
- `Sources/App/AdvancedAssistantView.swift`: assistant state and section composition.
- `Sources/App/Assistant`: OCR, voice, writing, history, calendar, diagnostics.
- `Sources/Keyboard/KeyboardViewController.swift`: extension state and UIKit lifecycle.
- `Sources/Keyboard/Layout`, `Input`, `Suggestions`, `Glide`, `AI`, `Clipboard`: keyboard features grouped by responsibility.
- `Sources/Shared/Settings`: preferences, credential storage, privacy, personal writing, appearance and learning.
- `Sources/Shared/Typing`: predictions, glide, tone variants, geometric scoring and snippets.
- `Sources/Shared/Conversation`, `Privacy`, `Diagnostics`: offline conversation services, clipboard and safe data handling.
- Remaining shared source files: existing provider adapters, composition engines, model catalog, preferences backup and reusable primitives.

## Rules
Keep UIKit lifecycle overrides and stored controller state in the primary class. Use extensions for feature methods, avoid unrelated changes during structural migrations, and preserve user settings keys. Use private access for helpers within a module file where possible; cross-file members use internal scope. Keep app-only frameworks out of command-line Swift verification targets. New files in Sources are discovered by XcodeGen; update explicit Swift CLI test lists in the workflow when splitting shared files.

### Premium Toolbar
`Shared/Intelligence/ToolbarPreferences.swift` defines stable action IDs and validated persisted configuration. `ToolbarLayoutEngine.swift` is pure Foundation, shared by SwiftUI preview and UIKit keyboard. `Keyboard/Toolbar/` contains the scroll container, button, palette and selector router; the controller binds actions by ID rather than position. `IntelligenceToolCell` and `SuggestionChipView` handle reusable theme-aware visuals. `verify_toolbar.swift` checks width, ordering, mode and migration.

### Premium 2.0
`Shared/Premium/` separates command catalog, deterministic offline utilities, bounded stores and cloud workflow service. `App/Premium/` contains Command, workflow/macro, vault and experience studios. `Keyboard/Premium/` binds tools through Intelligence Hub, an independent search/calculator panel, and bounded input gestures. `verify_premium.swift` validates pure logic offline; physical-device UI, network responses and installation require device testing.

### Personal Intelligence 3.0
`Shared/PersonalIntelligence/` contains scoped memory with iOS file protection, catalog, tone presets, arena transport, offline units/diff/password/date parsing, and scheduler. `App/PersonalIntelligence/` provides full studios and Mini Apps; `Keyboard/PersonalIntelligence/` exposes explicit actions in Hub/Command with cancellation and document checks, and scheduled theme presentation. QR/password/reminders/photo import are app-only. `verify_personal_intelligence.swift` covers deterministic logic without provider keys.

### Offline Pro 4.0
`Shared/OfflinePro/` holds pure layout/config, Hangul, guarded history and text utilities, profiles and sound path. `Keyboard/OfflinePro/` handles actual typing/gesture/history, capped visuals and Hub menus. `App/OfflinePro/` contains editors and offline tools, including local media rendering. `verify_offline_pro.swift` tests deterministic logic without network. No new entitlement or extension.
