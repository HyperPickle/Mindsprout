# AGENTS.md — Mindsprout

Guide for every agent **and** human contributor. Read this first, then `IMPLEMENTATION_PLAN.md`. Keep it accurate as the project evolves.

## What Mindsprout is

A travel-reflection iOS app for 18–35 year-olds that turns travel into personal growth via a ~10-minute daily game. **Core loop:** open the app → reflect on one travel moment → **Feed Sprout** → earn XP → the companion grows/evolves. Two systems:

- **Trips &amp; Reflections** — create a trip (Solo/Friends/Family/Business, each with an expectations step); log one reflection/day against the active trip (text *or* audio + photos).
- **The Sprout** — one global companion that gains XP per reflection, levels up, and evolves through a cinematic level-up flow (sleeping → transition → evolve → level → growth insight → postcard). It's the retention hook.

Tone: **Reflective + Engaging** — reflection must never feel like homework.

## Repository map


| Path                         | What it is                                                                                                                                                                           |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `Mindsprout.xcodeproj`       | Xcode project.                                                                                                                                                                       |
| `Mindsprout/`                | App source. Entry point `MindsproutApp.swift`. Organize **feature-based** (see plan §4): `App/`, `Core/`, `DesignSystem/`, `Models/`, `Features/`, `Resources/`, `Assets.xcassets/`. |
| `MindsproutTests/`           | Swift Testing target (domain logic). Live, covering GameConfig/progression, reflection cadence + view-model, content packs, AI templates, persistence, media store, trip repo, auth, Sprout state, home dashboard.                                |
| `UI-Scaffold/`               | **Design source of truth** — screenshots, organized by feature (see below).                                                                                                          |
| `IMPLEMENTATION_PLAN.md`     | Phased build plan + all resolved decisions. **Binding.**                                                                                                                             |                                                                                                       |
| `travel-growth-app-brief.md` | Product brief (intent, audience, priorities).                                                                                                                                        |


### `UI-Scaffold/` naming convention

Folder = feature; file = screen, lowercase-hyphenated. Build screens to match these images pixel-intent, not guesses.

- `Trips/` — `trips-overview`, `trip-detail`, `trip-day-detail`, `trips-image-selected`; `Trips/Header/` holds the header `bg-graphic` + `SVGs/`.
- `Trips/New-Trip/` — `newtrip-firstscreen`, `newtrip-{solo,friends,family,business}expectation`
- `Reflection/` — `reflection-initalscreen`, `Reflection-type`, `Reflection screen-record`, `Reflection-attachphoto`, `Reflection-photoattachedplaceholder`
- `Dashboard/` — `dashboard-default`, `dashboard-background`, `Sprout`; `Dashboard/Level-up/` — `levelup-sleeping-1/2`, `levelup-transition-card`, `levelup-transitioncard-2`, `levelup-evoprompt`, `levelup-evo-finished`, `levelup-growth-insight`, `levelup-postcard1`
- `Profile/` — `profile`

**Workflow rule:** if a screen has a screenshot, match it. The Home/Sprout (`Dashboard/dashboard-default` + `Sprout`) and Profile (`Profile/profile`) screens now have designs — build to them. **Shop has NO design → navigable placeholder only** (empty screen + `// TODO` for when designs land). **Onboarding/auth** has no `UI-Scaffold` folder but is built (Sign in with Apple + travel-type onboarding) — treat its UI as **revisable** until a dedicated design lands.

## Build / run / test

- **Xcode 26** (iOS 26 SDK). **Min deployment target: iOS 26.0.** **iPhone-only, portrait.**
- **No third-party dependencies.** Don't add SPM packages without updating this file and the plan.
- This machine's `xcode-select` points at CommandLineTools, so prefix every `xcodebuild` with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Only the iOS 26.x simulator runtime is installed — build/test against **iPhone 17**.
- Build (CLI):
  ```sh
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
    -project Mindsprout.xcodeproj -scheme Mindsprout \
    -destination 'platform=iOS Simulator,name=iPhone 17' build
  ```
- Test (CLI):
  ```sh
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
    -project Mindsprout.xcodeproj -scheme Mindsprout \
    -destination 'platform=iOS Simulator,name=iPhone 17' test
  ```
- Day-to-day: build/run/preview in Xcode; rely on SwiftUI `#Preview`s for visual checks or Xcode simulator.

## Architecture &amp; conventions

- **MVVM + Observation** — one `@Observable` view-model per feature/flow; **SwiftData `@Model` types are the source of truth.**
- **Persistence: SwiftData**, local-only but **sync-ready** (don't add patterns that block CloudKit later). Photos/audio are **files in the app container** referenced by path — never large blobs in the store.
- **Navigation:** root `TabView` (Adventures / Reflect / Home / Profile); **per-tab `NavigationStack` with enum routes**; multi-step flows (New Trip, Edit Trip, Reflection, Level-up) as **self-contained modal coordinators** (`ModalCoordinator`). A pre-shell auth gate (`WelcomeView`) and onboarding flow gate the tab shell in `RootView`.
- **Offline-first:** the core loop must work with no network. AI-derived content (theme, headline, mood tags, growth insight, postcard) goes behind `**AIGenerationService**`; the default impl is a **deterministic on-device template** generator. A real LLM (Claude via a future backend proxy) plugs into the same protocol — no feature-code changes.
- **Economy:** all XP/level/evolution/currency constants live in `**GameConfig**`. No magic numbers in feature code. Evolution stages are a **data-driven table** mapped to art.
- **Auth:** single-user, local-first. **Sign in with Apple is built** (`AppleAuthService` / `AuthService` behind a protocol, token in `KeychainStore`); `WelcomeView` is the gate. Still no multi-user accounts/backend — keep the seam, don't expand scope.
- **Capabilities:** Camera, Photo Library, Microphone only. **No location.**

## Naming &amp; style

- Swift API Design Guidelines; descriptive names; small focused types.
- Folders/types: feature-based (`Features/Trips/...`). Asset catalog Sprout art: `**sprout_stage{n}_{state}**` (e.g. `sprout_stage2_idle`). Sprout states: `sleeping`, `idle`, `hungry`, `readyToEvolve`, `evolving`.
- User-facing copy → **String Catalog (`Localizable.xcstrings`)** + content packs in `Resources/ContentPacks/`. No inline string literals for UI text. English-only for now; localization is later a content task.
- **Reduce Motion:** honor it anywhere you animate (the level-up flow needs a reduced variant).

## Testing

- **Swift Testing** for domain logic: XP math, level curve, evolution triggers, daily-cadence rules, AI-fallback templates. SwiftUI `#Preview`s for visuals. **No XCUITest suite** for MVP.

## Git / PR norms

- **Simple imperative commit messages** (e.g. `Add Trip model and repository`).
- **One PR per plan phase**; PR description references the phase/milestone in `IMPLEMENTATION_PLAN.md`.
- **Squash-merge to `main`.** Branch per phase.
- Do not add co-author trailers to agent-authored commits unless explicitly requested.

## Golden rules

1. Don't relitigate decisions in `IMPLEMENTATION_PLAN.md` §2 — flag, don't silently diverge.
2. Screenshots in `UI-Scaffold/` are the design source of truth; Shop stays a placeholder, and onboarding/auth UI stays revisable, until designs land.
3. Keep the core loop offline; AI behind the service seam.
4. Stop at each phase's Definition of Done and report status + open questions.
