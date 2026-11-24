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
