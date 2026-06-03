# AGENTS.md — Mindsprout

Guide for every agent **and** human contributor. Read this first, then `IMPLEMENTATION_PLAN.md`. Keep it accurate as the project evolves.

## What Mindsprout is
A travel-reflection iOS app for 18–35 year-olds that turns travel into personal growth via a ~10-minute daily game. **Core loop:** open the app → reflect on one travel moment → **Feed Sprout** → earn XP → the companion grows/evolves. Two systems:
- **Trips & Reflections** — create a trip (Solo/Friends/Family/Business, each with an expectations step); log one reflection/day against the active trip (text *or* audio + photos).
- **The Sprout** — one global companion that gains XP per reflection, levels up, and evolves through a cinematic level-up flow (sleeping → transition → evolve → level → growth insight → postcard). It's the retention hook.

Tone: **Reflective + Engaging** — reflection must never feel like homework.

## Repository map
| Path | What it is |
|---|---|
| `Mindsprout.xcodeproj` | Xcode project. |
| `Mindsprout/` | App source. Entry point `MindsproutApp.swift`. Organize **feature-based** (see plan §4): `App/`, `Core/`, `DesignSystem/`, `Models/`, `Features/`, `Resources/`, `Assets.xcassets/`. |
| `MindsproutTests/` | Swift Testing target (domain logic). *(Add when Phase 0 lands.)* |
| `UI-Scaffold/` | **Design source of truth** — screenshots, organized by feature (see below). |
| `IMPLEMENTATION_PLAN.md` | Phased build plan + all resolved decisions. **Binding.** |
| `KICKOFF_PROMPT.md` | Ready-to-paste prompt to start an agent on Phase 0. |
| `travel-growth-app-brief.md` | Product brief (intent, audience, priorities). |

### `UI-Scaffold/` naming convention
Folder = feature; file = screen, lowercase-hyphenated. Build screens to match these images pixel-intent, not guesses.
- `Trips/` — `trips-overview`, `trip-detail`, `trips-image-selected`
- `Trips/New-Trip/` — `newtrip-firstscreen`, `newtrip-{solo,friends,family,business}expectation`
- `Reflection/` — `reflection-initalscreen`, `Reflection-type`, `Reflection screen-record`, `Reflection-attachphoto`, `Reflection-photoattachedplaceholder`
- `Dashboard/Level-up/` — `levelup-sleeping-1/2`, `levelup-transition-card`, `levelup-transitioncard-2`, `levelup-evoprompt`, `levelup-evo-finished`, `levelup-growth-insight`, `levelup-postcard1`

**Workflow rule:** if a screen has a screenshot, match it. **Profile, Shop, and Onboarding have NO designs → build navigable placeholders only** (empty screen + `// TODO` for when designs land). The **Home/Sprout** screen is reconstructed from `levelup-sleeping-*` + `levelup-evo-finished` — build it but treat it as **revisable** until a dedicated Home design arrives.

## Build / run / test
- **Xcode:** current stable (iOS 18 SDK or later). **Min deployment target: iOS 18.0.** **iPhone-only, portrait.** (The repo currently ships an accidental `26.5` target — Phase 0.1 fixes it.)
- **No third-party dependencies.** Don't add SPM packages without updating this file and the plan.
- Build (CLI):
  ```sh
  xcodebuild -project Mindsprout.xcodeproj -scheme Mindsprout \
    -destination 'platform=iOS Simulator,name=iPhone 16' build
  ```
- Test (CLI):
  ```sh
  xcodebuild -project Mindsprout.xcodeproj -scheme Mindsprout \
    -destination 'platform=iOS Simulator,name=iPhone 16' test
  ```
- Day-to-day: build/run/preview in Xcode; rely on SwiftUI `#Preview`s for visual checks.

## Architecture & conventions
- **MVVM + Observation** — one `@Observable` view-model per feature/flow; **SwiftData `@Model` types are the source of truth.**
- **Persistence: SwiftData**, local-only but **sync-ready** (don't add patterns that block CloudKit later). Photos/audio are **files in the app container** referenced by path — never large blobs in the store.
- **Navigation:** root `TabView` (Adventures / Home / Profile); **per-tab `NavigationStack` with enum routes**; multi-step flows (New Trip, Reflection, Level-up) as **self-contained modal coordinators**.
- **Offline-first:** the core loop must work with no network. AI-derived content (theme, headline, mood tags, growth insight, postcard) goes behind **`AIGenerationService`**; the default impl is a **deterministic on-device template** generator. A real LLM (Claude via a future backend proxy) plugs into the same protocol — no feature-code changes.
- **Economy:** all XP/level/evolution/currency constants live in **`GameConfig`**. No magic numbers in feature code. Evolution stages are a **data-driven table** mapped to art.
- **Auth:** local single-user, no accounts. Seam for Sign in with Apple later; don't build it now.
- **Capabilities:** Camera, Photo Library, Microphone only. **No location.**

## Naming & style
- Swift API Design Guidelines; descriptive names; small focused types.
- Folders/types: feature-based (`Features/Trips/...`). Asset catalog Sprout art: **`sprout_stage{n}_{state}`** (e.g. `sprout_stage2_idle`). Sprout states: `sleeping`, `idle`, `hungry`, `readyToEvolve`, `evolving`.
- User-facing copy → **String Catalog (`Localizable.xcstrings`)** + content packs in `Resources/ContentPacks/`. No inline string literals for UI text. English-only for now; localization is later a content task.
- **Reduce Motion:** honor it anywhere you animate (the level-up flow needs a reduced variant).

## Testing
- **Swift Testing** for domain logic: XP math, level curve, evolution triggers, daily-cadence rules, AI-fallback templates. SwiftUI `#Preview`s for visuals. **No XCUITest suite** for MVP.

## Git / PR norms
- **Simple imperative commit messages** (e.g. `Add Trip model and repository`).
- **One PR per plan phase**; PR description references the phase/milestone in `IMPLEMENTATION_PLAN.md`.
- **Squash-merge to `main`.** Branch per phase.
- Agent commits include the co-author trailer.

## Golden rules
1. Don't relitigate decisions in `IMPLEMENTATION_PLAN.md` §2 — flag, don't silently diverge.
2. Screenshots in `UI-Scaffold/` are the design source of truth; Profile/Shop/Onboarding stay placeholders until designs land.
3. Keep the core loop offline; AI behind the service seam.
4. Stop at each phase's Definition of Done and report status + open questions.
