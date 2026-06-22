# AGENTS.md: Mindsprout

Guide for agents **and** humans. Keep accurate as it evolves.

## What it is

Travel-reflection iOS app (18–35). ~10-min daily loop: reflect on one travel moment (text or audio + photos) → **Feed Sprout** → earn XP → companion grows/evolves. Reflective tone, never homework.

- **Trips/Reflections** — a trip (Solo/Friends/Family/Business + expectations step); one reflection/day vs the active trip.
- **Sprout** — one global companion that levels/evolves via a cinematic level-up flow; the retention hook.

## Layout

- `Mindsprout/` — source (entry `MindsproutApp.swift`), feature-based: `App/`, `Core/` (GameConfig, Persistence, Services), `DesignSystem/`, `Models/`, `Features/` (Trips, Reflection, Sprout, LevelUp, Onboarding, Profile, Shop), `Resources/`, `Assets.xcassets/`.
- `MindsproutTests/` — Swift Testing, domain logic only.
- `TYPOGRAPHY.MD` — typography rules and decisions; consult it before changing type scale, font usage, or text styling patterns.
- `ASSET-GUIDE.md` — asset naming, preparation, and usage guidance; consult it before adding or changing images, icons, or other visual assets.

## Build / test

**Do not run Xcode builds or simulator launches automatically.** Only build or run tests when the user explicitly requests it, or when a build is strictly required to unblock the current task (e.g. resolving a compiler error you introduced). Never validate changes by building "just to be safe" after every prompt.

**No third-party dependencies** without updating this file.

## Conventions

- **MVVM + Observation**: `@Observable` VM per flow; **SwiftData `@Model` = source of truth**, local-only but sync-ready. Photos/audio = files by path, never blobs.
- **Nav:** root `TabView` (Adventures/Reflect/Home/Profile), per-tab `NavigationStack` enum routes; multi-step flows as `ModalCoordinator`; auth + onboarding gate the shell.
- **Offline-first:** core loop needs no network; AI behind `AIGenerationService` (default = on-device templates).
- XP/level/evolution constants in `GameConfig`; stage art `sprout_stage{n}_{state}`. Sign in with Apple, Keychain. Camera/Photos/Mic only — **no location**.
- UI copy → `Localizable.xcstrings`.
- For typography or asset work, defer to `TYPOGRAPHY.MD` and `ASSET-GUIDE.md` rather than duplicating rules here.

Git: Imperative commits; branch per feature, squash-merge to `main`. No co-author trailers unless asked.