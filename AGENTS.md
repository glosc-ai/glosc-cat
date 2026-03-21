# AGENTS.md

## Purpose
- This file is for coding agents working in `glosc-cat`.
- Follow repository-specific guidance first, then normal Swift/iOS best practices.
- Optimize for small, correct, warm consumer-product changes rather than abstract architecture work.

## Project Snapshot
- Product: `说猫语` — a cute, companion-like iOS app for cat owners.
- Core loops:
  - 猫语转人话
  - 人话转猫语
- Stack:
  - SwiftUI
  - SwiftData
  - AVFoundation
  - Speech
- Product tone: warm, soft, light, and emotionally aware — never clinical or enterprise.

## Rule Files Present
- `AGENTS.md` exists and is the active repository rule file.
- No `.cursorrules` file found.
- No `.cursor/rules/` directory found.
- No `.github/copilot-instructions.md` file found.

## Source of Truth Files
- `README.md` — product summary, implemented scope, validation command.
- `docs/product-requirements.md` — product goals, UX direction, non-goals, acceptance criteria.
- `glosc-cat/glosc_catApp.swift` — app entry and SwiftData container setup.
- `glosc-cat/ContentView.swift` — current main screen and UI orchestration.
- `glosc-cat/AppModels.swift` — enums, domain structs, SwiftData models.
- `glosc-cat/CatServices.swift` — analysis, recording, transcription, playback services.
- `glosc-cat/CatAudioSamples.swift` — built-in sample metadata and matching helpers.

## Repository Assessment
- The codebase is small and functional.
- Models and services are reasonably disciplined.
- `ContentView.swift` is the main hotspot: large, transitional, and mixes UI, persistence, and orchestration.
- Prefer incremental cleanup over broad rewrites unless explicitly requested.

## Build / Test Commands

### Default simulator
- Use: `-destination 'platform=iOS Simulator,name=iPhone 17'`

### Build app
```bash
xcodebuild build -scheme glosc-cat -project glosc-cat.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Run full test suite
```bash
xcodebuild test -scheme glosc-cat -project glosc-cat.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Run one Swift Testing unit test
```bash
xcodebuild test -scheme glosc-cat -project glosc-cat.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:glosc-catTests/glosc_catTests/quietLongMeowProducesReadableAnalysis
```

### Run one UI test
```bash
xcodebuild test -scheme glosc-cat -project glosc-cat.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:glosc-catUITests/glosc_catUITests/testMainFlowsAreVisible
```

### Run launch performance UI test
```bash
xcodebuild test -scheme glosc-cat -project glosc-cat.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:glosc-catUITests/glosc_catUITests/testLaunchPerformance
```

### List available simulators for this scheme
```bash
xcodebuild -showdestinations -project glosc-cat.xcodeproj -scheme glosc-cat
```

## Lint / Validation
- No `SwiftLint`, `SwiftFormat`, `fastlane`, `Makefile`, or repo-local formatter config exists.
- There is no dedicated lint command.
- Use these quality gates instead:
  1. `lsp_diagnostics` on changed Swift files
  2. `xcodebuild build`
  3. targeted tests first, then broader `xcodebuild test`
- Do not invent fake lint steps in docs, commits, or PR notes.

## Testing Expectations
- Test every functional change.
- Prefer deterministic unit tests for service logic.
- Prefer UI tests for top-level user flows and visibility checks.
- Reuse or extend existing accessibility identifiers when adding UI tests.
- Existing test frameworks:
  - `Testing` for unit tests
  - `XCTest` for UI tests

## Code Style

### Imports
- One import per line.
- Import only what the file uses.
- Match surrounding style when editing an existing file.
- Avoid adding third-party dependencies unless strongly justified.

### Formatting
- Use 4 spaces for indentation.
- Keep braces on the same line.
- Keep SwiftUI modifier chains vertical when non-trivial.
- Prefer readable multiline initializers/builders over dense compact code.
- Preserve nearby trailing-comma style when already used.

### Types
- Prefer strong types over escape hatches.
- Do not weaken types just to silence compiler issues.
- Avoid force unwraps unless impossibility of failure is already guaranteed.
- Prefer `struct` for value types.
- Prefer `final class` for reference types and SwiftData `@Model` types.
- Use enums with raw values for closed domains like app mode and tone.

### Naming
- Types: `UpperCamelCase`.
- Functions, properties, locals: `lowerCamelCase`.
- Booleans should read like booleans: `isRecording`, `isAnalyzingAudio`, `canPlayInApp`.
- Keep accessibility identifiers stable and explicit, following existing patterns such as:
  - `screen.title`
  - `mode.catToHuman`
  - `mode.humanToCat`
  - `record.toggle`
  - `generate.catPhrase`
  - `textInput.human`

### SwiftUI / Architecture
- Keep purely presentational state local to the view.
- Use `@StateObject` for long-lived service owners created by the view.
- Use `@Environment(\.modelContext)` and `@Query` for SwiftData integration.
- If touching `ContentView.swift`, prefer extracting responsibility rather than adding more.
- Preserve the current layering where possible:
  - UI in SwiftUI views
  - business/audio logic in `CatServices.swift`
  - domain and persistence models in `AppModels.swift`
- Good refactor direction:
  - extract reusable components
  - extract orchestration/view-model logic
  - keep persistence writes deliberate and easy to trace
- Bug fixes should stay minimal; do not smuggle in broad refactors.

### Error Handling
- Use typed errors with `LocalizedError` for recoverable domain failures.
- Surface user-facing errors with gentle, understandable copy.
- Avoid empty `catch` blocks.
- Avoid silently swallowing failures.
- `fatalError` is acceptable only for unrecoverable app-start failures already established by repo precedent, such as failing to create the SwiftData container.

### Concurrency
- Keep UI-affecting observable objects on `@MainActor` when appropriate.
- Hand off callback-driven updates back to the main actor explicitly.
- Do not mutate SwiftUI-observed state from background threads.

### Persistence
- Current SwiftData models:
  - `InteractionRecord`
  - `FavoritePhrase`
- Preserve backward-compatible intent when editing stored properties.
- If schema changes are needed, call out migration impact clearly.

## Product / UX Rules
- Default user-facing copy should be Simplified Chinese.
- Preserve the app’s warm, companion-like tone.
- Do not claim scientific or veterinary-grade accuracy.
- Do not turn the product into a cold analysis dashboard.
- First-screen actions should stay obvious: record, analyze, translate, play.
- Results should include interpretation plus actionable care/interaction suggestions.
- Keep the “养宠女孩” visual direction: soft colors, rounded cards, gentle shadows, low-saturation gradients.
- Avoid harsh neon colors, severe contrast, or admin-panel aesthetics.

## Documentation Sync
- If product scope, interaction flow, or feature status changes, update:
  - `README.md`
  - `docs/product-requirements.md`
  - `AGENTS.md` if agent guidance changed
- If the task is documentation-only, do not also change product code.

## Practical Workflow For Agents
1. Read the relevant source file plus `README.md` and `docs/product-requirements.md`.
2. Make the smallest change that fully solves the request.
3. Run `lsp_diagnostics` on changed Swift files.
4. Run targeted tests when possible.
5. Run broader build/test validation for cross-cutting changes.
6. Update docs if behavior or scope changed.

## Do Not
- Do not add heavy dependencies without strong reason.
- Do not replace warm Chinese copy with generic technical wording.
- Do not overstate recognition accuracy.
- Do not expand scope into community, e-commerce, or subscription features unless explicitly asked.
- Do not commit changes unless the user explicitly requests a commit.

## Useful Existing Test Targets
- Unit tests in `glosc_catTests`, including:
  - `quietLongMeowProducesReadableAnalysis`
  - `shortLoudMeowProducesReadableAnalysis`
  - `audioSignatureSimilarityPrefersCloserReference`
  - `phraseComposerKeepsOriginalMeaningAndTone`
- UI tests in `glosc_catUITests`, including:
  - `testMainFlowsAreVisible`
  - `testLaunchPerformance`

## Final Reminder
- This app is not just cat audio tooling; it is a soft consumer experience.
- Preserve warmth while improving clarity, modularity, and reliability.
