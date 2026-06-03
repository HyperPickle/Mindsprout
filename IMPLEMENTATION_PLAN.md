# Mindsprout — Implementation Plan

> Phased build plan for the Mindsprout iOS app. Read alongside [`AGENTS.md`](./AGENTS.md) (conventions, build/run, repo map) and [`travel-growth-app-brief.md`](./travel-growth-app-brief.md) (product intent).
> **Design source of truth:** the screenshots in `UI-Scaffold/`. Build to the designs that exist; do not invent UI for undesigned screens.

---

## 1. Product in one paragraph

Mindsprout turns travel into personal growth for 18–35 year-olds via a ~10-minute daily "game." Two intertwined systems: **(1) Trips & Reflections** — the user creates a trip (Solo/Friends/Family/Business, each with an expectations step) and logs one reflection per day against the active trip; **(2) The Sprout** — a single companion creature that gains XP from each reflection, levels up, and *evolves* at milestone levels through a cinematic level-up flow. The Sprout is the retention hook; reflection should never feel like homework. Design priorities: **Reflective + Engaging**, retention via lowered emotional friction.

---

## 2. Resolved decisions (from grilling session)

These are settled. Do not relitigate without updating this section.

### Data & persistence
- **SwiftData** for all local models. No Core Data, no third-party DB.
- **Local-only, sync-ready.** All data on-device for MVP; model layer designed so CloudKit can be layered on later (avoid patterns that would block it).
- **Core loop is fully offline.** AI-backed features (growth insight, postcard, trip theme, mood tags) use the network *when available* and **degrade gracefully** — entries always save offline; AI-derived fields fill in later.
- Photos and audio are stored as **files in the app container** (Documents/`media/...`), referenced by relative path/URL from SwiftData models — not as large blobs in the store.

### Architecture
- **MVVM + Observation** (`@Observable` view-models). One VM per feature/flow; SwiftData models are the source of truth.
- **Navigation:** root `TabView` (Adventures / Home / Profile) with a **per-tab `NavigationStack`** driven by **enum routes**. Multi-step flows (New Trip, Reflection, Level-up) are **self-contained modal coordinators**.
- **Folder organisation:** feature-based (see §4).

### Platform & scope
- **iOS 18.0 minimum** (lower the current `IPHONEOS_DEPLOYMENT_TARGET = 26.5`, an accidental default).
- **iPhone-only, portrait-locked.** Set `TARGETED_DEVICE_FAMILY = 1`.
- **Capabilities:** Camera, Photo Library, Microphone. **No location.** Add the corresponding `Info.plist` usage strings.
- **No third-party dependencies** for MVP.

### Trips
- A **Trip** holds: destination (city) + country, date range, type (`solo`/`friends`/`family`/`business`), **expectations** (multi-select from presets **+** custom free-text), cover image, AI-derived **theme**, AI-derived **headline memory** (fallback: most-recent reflection text), active status, derived **memory count**.
- **Many trips; one active at a time** — active = trip whose date range contains today (else most recently created). Reflections attach to the active trip. Past trips appear under **REVISIT**.
- **Cover image** auto-selects from reflection photos (first/striking), user-editable. No cover picker at creation.
- **Expectations** stored as a list; presets are per-type (see screenshots).

### Reflection
- **One reflection per calendar day per active trip (soft).** Re-entering the same day continues/edits that day's entry; UI nudges one/day but does not hard-lock. "Day N" derived from trip start.
- A **Reflection** holds: chosen highlight prompt; **one body that is EITHER typed text (≤200 chars) OR an audio recording** (Type/Record toggle); **0..n attached photos**; AI-derived mood tags; draft flag; XP awarded.
- **Highlight & inspiration prompts** live in a **bundled curated content pack (JSON)**, keyed by trip type/context. The dice **"Pull to refresh"** reshuffles the displayed subset. Fully offline; copy editable without code.
- **Mood tags** (e.g. Serenity, Curiosity) are **AI-derived** (online, graceful degrade).
- **Save To Draft** = persists, **no XP**. **Feed Sprout** = commits the reflection **and awards XP**.

### Sprout & gamification
- **One global Sprout.** XP/level accrue across **all** trips (long-term companion). Trip context (e.g. "Kyoto") is just where it's displayed. Per-trip narrative lives in insights/postcards, not separate sprouts.
- **XP:** base XP per Feed Sprout + **configurable bonuses** (photo / audio / streak). **Level thresholds in one tunable `GameConfig`** (gently escalating). All economy constants centralized.
- **Evolution:** stages and their trigger levels are **data-driven** (a stage table mapped to art asset sets). Adding a stage = drop art + add a config row. Start with the stages we have art for; exact trigger levels are tunable placeholders.
- **Sprout states:** `sleeping` / `idle` / `hungry` (reflection available) / `readyToEvolve` / `evolving`. States drive the Home animation.
- **Currency** (the "1,500" counter) accrues alongside XP and is displayed; **spending is deferred to the Shop** (placeholder).

### Art & AI
- **Static image sets + SwiftUI animation** (transitions, `phaseAnimator`, sprite swaps; evolution "morph" = crossfade between stage images). **No Lottie/Rive/3D.**
- **No final Sprout art exists yet.** Build against **placeholder/programmer art** behind a **documented asset-catalog naming convention** (`sprout_stage{n}_{state}`) so the artist drops finals in with **zero code changes**.
- **AI generation:** an `AIGenerationService` **protocol**. MVP ships a **deterministic on-device template/rule-based generator** (works fully offline). A documented **seam + config** allows a real LLM (Claude via a future backend proxy) to be swapped in without touching feature code. "Online" AI = when that seam is wired.

### Auth & accounts
- **Local single-user, no auth.** All data on-device. Design a seam for **Sign in with Apple** + accounts later (needed when sync/Shop purchases arrive); do not build it now.

### Tabs & placeholders
- **Adventures tab → Trips** (overview/detail). **Home tab → functional Sprout home**, reconstructed from `levelup-sleeping-*` and `levelup-evo-finished` (Sprout, XP bar, currency, active-trip context, "Reflect To Feed" CTA) — **flagged as subject to revision** when a dedicated Home design lands. **Profile tab → placeholder.**
- **Placeholders (navigable, empty + TODO):** **Profile** (3rd tab), **Shop** (tap the currency/coin counter on Home), **Onboarding** (first-launch gate, flag-controlled, skippable, before the tab bar). Wire nav, invent no UI.

### Non-functionals
- **Testing:** **Swift Testing** for domain logic (XP math, level curve, evolution triggers, cadence rules, AI-fallback templates). SwiftUI `#Preview`s for visual checks. **No XCUITest suite** for MVP.
- **No analytics** (future).
- **No formal accessibility pass** for MVP **except honor Reduce Motion** in the animation-heavy level-up flow (provide a reduced variant).
- **English-only**, but route all user-facing copy through a **String Catalog (`.xcstrings`)** + the externalized content pack so localization is later a content task, not a refactor.

### Process
- **Simple imperative commit messages**, **one PR per phase**, PR description references the plan phase. Squash-merge to `main`. Agent commits include a co-author trailer.

---

## 3. Screen → screenshot map

| Screen / flow | Screenshot(s) | Phase |
|---|---|---|
| Trips overview (cards, ACTIVE, memory count, headline, theme, REVISIT) | `UI-Scaffold/Trips/trips-overview.png` | P1 |
| Trip detail (Day N, reflection text, audio playback, photo album) | `UI-Scaffold/Trips/trip-detail.png`, `trips-image-selected.png` | P1 |
| New Trip — basics (destination, dates, type) | `UI-Scaffold/Trips/New-Trip/newtrip-firstscreen.png` | P1 |
| New Trip — expectations (per type) | `newtrip-soloexpectation.png`, `-friendsexpectation.png`, `-familyexpectation.png`, `-businessexpectation.png` | P1 |
| Reflection — highlight picker (presets + own + dice) | `UI-Scaffold/Reflection/reflection-initalscreen.png` | P2 |
| Reflection — Type entry (≤200 chars, Inspiration) | `UI-Scaffold/Reflection/Reflection-type.png` | P2 |
| Reflection — Record (audio waveform) | `UI-Scaffold/Reflection/Reflection screen-record.png` | P2 |
| Reflection — attach photo / placeholder; Draft vs Feed Sprout | `Reflection-attachphoto.png`, `Reflection-photoattachedplaceholder.png` | P2 |
| Home / Sprout (reconstructed) | `UI-Scaffold/Dashboard/Level-up/levelup-sleeping-1.png`, `levelup-sleeping-2.png`, `levelup-evo-finished.png` | P3 |
| Level-up — sleeping → transition → evolve → level | `levelup-sleeping-1/2.png`, `levelup-transition-card.png`, `levelup-transitioncard-2.png`, `levelup-evoprompt.png`, `levelup-evo-finished.png` | P4 |
| Level-up — growth insight (trait word) | `levelup-growth-insight.png` | P4 / P5 |
| Level-up — postcard (narrative summary) | `levelup-postcard1.png` | P4 / P5 |
| Profile / Shop / Onboarding | *(no designs — placeholder)* | P6 |

---

## 4. Target folder structure (feature-based)

```
Mindsprout/
  App/                 MindsproutApp, root TabView, app-level routing
  Core/
    Persistence/       SwiftData ModelContainer setup, migration plan
    Services/          AIGenerationService (+ Template impl), MediaStore, ContentPack loader
    GameConfig/        XP curve, bonuses, evolution stage table, currency constants
    Extensions/        small shared helpers
  DesignSystem/        Colors, Typography/fonts, ButtonStyles, CardStyle, spacing, backgrounds
  Models/              SwiftData @Model types: Trip, Reflection, MediaAsset, Sprout, ...
  Features/
    Trips/             overview, detail, New-Trip coordinator + VMs
    Reflection/        capture coordinator (highlight → entry → media → feed) + VMs
    Sprout/            Home view, Sprout view, feeding + leveling
    LevelUp/           evolution flow coordinator
    Insights/          growth insight + postcard presentation
    Profile/           placeholder
    Shop/              placeholder
    Onboarding/        placeholder + first-launch gate
  Resources/
    ContentPacks/      prompts.json, expectations.json, insight templates
    Localizable.xcstrings
  Assets.xcassets/     sprout_stage{n}_{state}, backgrounds, icons
MindsproutTests/       Swift Testing target (domain logic)
```
*Folder names are a guide; keep features self-contained so an agent can find a feature's whole stack in one place.*

---

## 5. Phased plan

Each milestone lists **Objective · Screens · Models touched · Definition of Done (DoD)**. Phases are dependency-ordered.

### Phase 0 — Foundation
> Goal: a runnable, well-structured shell everything else builds on. No feature UI yet.

- **0.1 Project configuration**
  - *Objective:* Correct the project settings. Lower `IPHONEOS_DEPLOYMENT_TARGET` to **18.0**, set `TARGETED_DEVICE_FAMILY = 1`, portrait-only. Add `Info.plist` usage strings for Camera, Photo Library, Microphone. Replace the stock `ContentView` with the app shell.
  - *Models:* none. *DoD:* app builds & launches to an empty `TabView` (Adventures / Home / Profile) on an iOS 18 iPhone simulator.
- **0.2 DesignSystem**
  - *Objective:* Colors, typography (register the rounded display font), primary green `ButtonStyle`, card style, spacing tokens, grass/sky background treatments — matching the screenshots.
  - *DoD:* a `#Preview` gallery renders all tokens/components; used by later phases.
- **0.3 SwiftData stack**
  - *Objective:* `ModelContainer` setup + app injection; empty `@Model` stubs for `Trip`, `Reflection`, `MediaAsset`, `Sprout`. `MediaStore` service for writing/reading photo & audio files in the app container.
  - *Models:* all (skeletal). *DoD:* container initializes; a unit test can insert/fetch a `Trip`.
- **0.4 Navigation shell**
  - *Objective:* Root `TabView`; per-tab `NavigationStack` with enum routes; modal-coordinator scaffolding. Map Adventures→Trips, Home→Sprout, Profile→placeholder.
  - *DoD:* tabs switch; routes compile; placeholder destinations reachable.
- **0.5 GameConfig + service protocols**
  - *Objective:* `GameConfig` (XP base, bonuses, level thresholds, evolution stage table, currency constants — all placeholder values). `AIGenerationService` protocol + **template/rule-based** default impl. `ContentPack` loader for bundled JSON. `AnalyticsService`/auth seams documented but unimplemented.
  - *DoD:* config + template service unit-tested; injectable via environment.

### Phase 1 — Trips
> Goal: create, list, and view trips. Depends on P0.

- **1.1 Trip model & repository** — *Objective:* finalize `Trip` (`destination`, `country`, `startDate`, `endDate`, `type`, `expectations: [String]`, `coverAssetID?`, `theme?`, `headlineMemory?`, derived `memoryCount`, computed `isActive`). *DoD:* CRUD covered by tests; active-trip resolution tested.
- **1.2 New Trip flow** — *Objective:* modal coordinator: basics screen (destination, date range w/ duration, type) → per-type expectations screen (multi-select presets from content pack + custom). *Screens:* `newtrip-firstscreen`, `newtrip-{solo,friends,family,business}expectation`. *Models:* `Trip`. *DoD:* completing the flow persists a trip and makes it active.
- **1.3 Trips overview** — *Objective:* list of trip cards (cover, name+country, dates, memory count, ACTIVE badge, headline memory, theme; REVISIT section for past trips). *Screen:* `trips-overview`. *DoD:* live data renders; tap → trip detail; empty state present.
- **1.4 Trip detail** — *Objective:* per-day reflection viewer with text, audio playback, and photo album grid. *Screens:* `trip-detail`, `trips-image-selected`. *Models:* `Trip`, `Reflection`, `MediaAsset` (read). *DoD:* a trip's reflections are browsable with working audio playback and photo viewing. (Renders real reflections once P2 exists; build against seed data first.)

### Phase 2 — Reflection capture
> Goal: the daily core loop end-to-end (minus XP reward, added in P3). Depends on P1.

- **2.1 Reflection model & media** — *Objective:* finalize `Reflection` (`tripID`, `dayIndex`, `date`, `highlightPrompt`, `bodyKind: .text|.audio`, `text?`, `audioAssetID?`, `photoAssetIDs: [..]`, `moodTags: [String]`, `isDraft`, `xpAwarded`) and `MediaAsset`. Implement one-per-day-soft resolution. *DoD:* model + cadence rules unit-tested.
- **2.2 Highlight picker** — *Objective:* prompt list from content pack + "Write your own" + dice reshuffle. *Screen:* `reflection-initalscreen`. *DoD:* selection carries into the entry step; dice reshuffles offline.
- **2.3 Entry — Type & Record** — *Objective:* Type/Record toggle; text editor (≤200 chars, Inspiration prompt) and audio recorder (waveform, timer, pause; mic permission). *Screens:* `Reflection-type`, `Reflection screen-record`. *Models:* `Reflection`, `MediaAsset`. *DoD:* text or audio body captured & persisted; recordings saved to media store.
- **2.4 Photo attach + commit** — *Objective:* Take photo / Choose from album (camera + photo library permissions); attach to entry; **Save To Draft** (no XP) vs **Feed Sprout** (commit; XP wired in P3). *Screens:* `Reflection-attachphoto`, `Reflection-photoattachedplaceholder`. *DoD:* completing the flow writes a committed reflection visible in trip detail; drafts resumable.

### Phase 3 — Sprout & XP (Home)
> Goal: feeding the Sprout grants XP and levels it up; the Home tab is alive. Depends on P2.

- **3.1 Sprout model & leveling engine** — *Objective:* `Sprout` (`xp`, `level`, `currentStageIndex`, `state`, `currency`). Pure leveling engine reading `GameConfig`: apply XP, compute level, detect stage/evolution thresholds, award currency. *DoD:* engine fully unit-tested across edge cases (multi-level jumps, exact thresholds).
- **3.2 Home / Sprout screen** — *Objective:* functional Home: Sprout (state-driven art), XP progress bar, currency counter, active-trip context, "Reflect To Feed" CTA launching the P2 flow. Sleeping/idle states. *Screens:* `levelup-sleeping-1/2`, `levelup-evo-finished` (as reference). *DoD:* feeding updates XP/level/currency live; Home reflects Sprout state. **Marked revisable pending a dedicated Home design.**
- **3.3 Feed → reward wiring** — *Objective:* connect "Feed Sprout" to the engine (base XP + photo/audio/streak bonuses); set `xpAwarded`; trigger level-up flow (P4) when a level/evolution boundary is crossed. *DoD:* a fed reflection deterministically moves the Sprout per `GameConfig`.

### Phase 4 — Level-up & Evolution flow
> Goal: the cinematic reward sequence. Depends on P3.

- **4.1 Level-up coordinator** — *Objective:* modal sequence: sleeping → transition card (sky/earth) → evolution morph (crossfade) → "Level Up N" → evolved Home. Honor **Reduce Motion** (reduced variant). *Screens:* `levelup-sleeping-1/2`, `levelup-transition-card`, `levelup-transitioncard-2`, `levelup-evoprompt`, `levelup-evo-finished`. *DoD:* crossing a level/evolution boundary plays the sequence and lands on updated Home; reduced-motion path verified.
- **4.2 Insight & postcard presentation** — *Objective:* present growth-insight (trait word) and postcard (narrative) screens within the flow, fed by `AIGenerationService` (template impl for now). *Screens:* `levelup-growth-insight`, `levelup-postcard1`. *DoD:* screens render generated/templated content and dismiss back to Home.

### Phase 5 — AI-derived content
> Goal: populate theme, headline memory, mood tags, insight, postcard. Depends on P1/P2/P4. Uses the template impl; LLM seam stays swappable.

- **5.1 Generation orchestration** — *Objective:* trigger generation on commit/level-up; persist results onto `Trip`/`Reflection`/insight records; graceful offline degradation + later backfill. *Models:* `Trip`, `Reflection`. *DoD:* fields populate via template service offline; values surface in overview/detail/level-up.
- **5.2 LLM seam (documented, not built)** — *Objective:* document the request/response contract and config flag for swapping in Claude via a backend proxy. *DoD:* `AGENTS.md`/code comments describe how to enable real AI without touching feature code.

### Phase 6 — Placeholder destinations
> Goal: complete the nav graph with honest placeholders. Can start any time after P0.

- **6.1 Profile placeholder** — 3rd tab, empty screen + `// TODO: Profile design pending`. *DoD:* reachable, clearly placeholder.
- **6.2 Shop placeholder** — opened by tapping the Home currency counter; empty + TODO. *DoD:* reachable from Home.
- **6.3 Onboarding placeholder** — first-launch gate (flag-controlled, skippable) before the tab bar; empty + TODO. *DoD:* shows once on first launch, skippable, gated by a persisted flag.

### Phase 7 — Polish
> Goal: ship-quality core loop. Depends on P1–P5.

- **7.1 States & resilience** — empty/loading/error states across Trips, Reflection, Home; media permission-denied handling; draft recovery.
- **7.2 Motion & feel** — finalize animations, Reduce Motion variants, haptics on feed/level-up.
- **7.3 Test & content sweep** — fill domain-logic test gaps; finalize content-pack copy; route all strings through the String Catalog.
- *DoD:* full daily loop (create trip → reflect → feed → level/evolve → see insight/postcard) is smooth, offline-safe, and tested.

---

## 6. Open questions

Track these explicitly; most need product/art/balancing input, not engineering.

1. **Economy balancing** — exact XP base/bonus values, level thresholds, currency amounts. (Placeholders in `GameConfig` until tuned.)
2. **Evolution specifics** — total number of stages and exact trigger levels; depends on final art count.
3. **Final art** — Sprout stage×state image sets + level-up animation assets (artist deliverable). Naming convention defined; finals pending.
4. **Dedicated Home/Dashboard design** — currently reconstructed from level-up screens; confirm or supersede.
5. **Profile, Shop, Onboarding designs** — placeholders until delivered.
6. **Backend + real LLM** — if/when to stand up a proxy and enable Claude; exact prompts/templates and content guidelines for insight/postcard/theme/tags.
7. **Currency sources & sinks** — finalize once the Shop is designed.
8. **Streak rules** — grace days, timezone handling for "a day," what counts toward a streak.
9. **CloudKit sync** — timing, multi-device conflict strategy.
10. **Accounts** — Sign in with Apple timing (tied to sync/Shop purchases).
11. **Media lifecycle** — storage limits, retention, export/delete, privacy copy.
12. **Localization** — target languages and when.
13. **Reflection edit/delete** — can a committed reflection be edited/deleted, and does that reverse XP? (Assumed: editable; XP not clawed back. Confirm.)
