# Mindsprout

Mindsprout is an iOS app about turning travel into a small daily habit of reflection. You create a trip, and each day you write or record one short reflection about a moment from it. Doing that feeds a little plant companion called the Sprout, which grows and changes over time as you keep at it.

The point is to make looking back on a trip feel light rather than like a chore. A reflection takes a couple of minutes, and the Sprout gives you a reason to come back the next day.

For design-system specifics that do not belong in this overview, use `TYPOGRAPHY.MD` for type rules and `ASSET-GUIDE.md` for asset creation, naming, and usage guidance.

## Trips and Reflections

You start a trip and say what you're hoping to get out of it. Trips come in a few kinds, solo, with friends, with family, or for work, and each one asks slightly different things. While the trip is on, you log one reflection a day against it. A reflection can be typed or recorded as audio, and you can attach photos to it.

## The Sprout

There’s a single Sprout that stays with you from trip to trip instead of resetting each time. Each reflection feeds it and earns experience. As that builds up it levels, and at certain points it evolves into a new form with a short animated sequence to mark the moment.

The core of all this works without a connection. A few extras, like a suggested theme for a trip or mood tags on a reflection, fill in when you're online, and your entries save either way.

## Technical Breakdown

- **Platform.** SwiftUI app targeting iOS 26+. iPhone only.
- **Structure.** Grouped by feature, so everything for a given screen tends to live in one place. `App` holds the entry point and tab navigation, `Core` holds shared services, `DesignSystem` holds the visual building blocks, `Models` holds the stored types, and each thing under `Features` is self-contained.
- **Design references.** Use `TYPOGRAPHY.MD` when adjusting fonts, text hierarchy, or type tokens, and `ASSET-GUIDE.md` when adding or updating images, icons, or exported visual assets.

  ```
  Mindsprout/
    App/             Entry point, the tab bar, app-wide routing and flags
    Core/
      Persistence/   SwiftData container setup
      Services/      Generated content, media files, content loading, seams
      GameConfig/    Experience, levels, evolution stages, currency
      Extensions/    Small shared helpers
    DesignSystem/    Colors, type, buttons, cards, spacing, backgrounds
    Models/          Stored types: Trip, Reflection, MediaAsset, Sprout
    Features/
      Trips/         Trip list, detail, and the new-trip flow
      Reflection/    Daily reflection capture
      Sprout/        Home screen and the companion
      Profile/       Placeholder
      Shop/          Placeholder
      Onboarding/    First-run intro placeholder
    Resources/       Bundled content files and the string catalog
    Assets.xcassets/ Images and colors
  MindsproutTests/   Tests for the non-visual logic
  ```

- **State and views.** MVVM with Swift's Observation. The stored data types are the source of truth, and each feature has its own view model driving the UI.
- **Storage.** Local, using SwiftData. The data model is kept simple enough to sync later without reworking it. Photos and audio are written to files and referenced by path, so the database stays small.
- **Game numbers.** Experience, level thresholds, evolution stages, and currency all live in one settings type rather than being spread through the code, which keeps them easy to tune.
- **Generated content.** Anything derived from a reflection, like a theme or mood tags, goes through a single service. The default runs on the device and gives the same result every time; a smarter online version can replace it later without touching the rest of the app.
- **Copy.** User-facing text runs through the string catalog and bundled content files instead of being written inline, so wording can change without code changes.
- **Tests.** The logic that isn't visual, the experience math, level curve, daily rules, and content fallbacks, is covered with Swift Testing. Screens are checked with SwiftUI previews.

## Developed by:
- Rishi Singhal
- Changrila Souksamlane
- Hiu Ying Lee (Ruby) 
- Nam Ng. (Louis)
- Arshiya Banu Varada
