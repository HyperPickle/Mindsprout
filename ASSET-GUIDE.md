# Asset Guide

This guide covers image assets that ship with the app: PNG, JPG, and frame-by-frame animation art in `[Mindsprout/Assets.xcassets](Mindsprout/Assets.xcassets)`. It is meant to answer three questions in order:

1. Where should a new asset go?
2. What sizes and naming patterns does the app already expect?
3. What should you check before you commit a change?

## 1. Start Here

Most visual assets live in `[Mindsprout/Assets.xcassets](Mindsprout/Assets.xcassets)`.

Use these rules first:

- Keep the asset name exactly aligned with the Swift code. `Image("HomeBackground")` only loads the `HomeBackground` asset name. See `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)` and `[LevelUpFlow.swift](Mindsprout/Features/LevelUp/LevelUpFlow.swift)`.
- For animation sequences, keep frame numbers contiguous with no gaps. The SpriteKit scenes build frames from numbered names such as `Sprout_idle_1`, `Sprout_idle_2`, and so on. See `[SproutScene.swift](Mindsprout/DesignSystem/Animation/SproutAnimation/SproutScene.swift)`, `[SeedScene.swift](Mindsprout/DesignSystem/Animation/SeedScene.swift)`, and `[GlobeScene.swift](Mindsprout/DesignSystem/Animation/GlobeScene.swift)`.
- Keep replacement art on the same canvas size as the current asset unless the code is changed with it.
- Most current image sets store one source file in the `1x` slot and leave `2x` and `3x` empty. Stay consistent with that pattern unless you are intentionally cleaning up the whole catalog.

## 2. What Is Not An Asset File

Some backgrounds are drawn in code, not loaded from the asset catalog.

- The onboarding and many flow backgrounds use `[BackgroundSky](Mindsprout/DesignSystem/Animation/AnimatedMeshGradient.swift)`.
- If you want to change that sky, edit `[AnimatedMeshGradient.swift](Mindsprout/DesignSystem/Animation/AnimatedMeshGradient.swift)`, not `Assets.xcassets`.

This matters because the welcome screen is a mix of both:

- Code background: `[BackgroundSky](Mindsprout/DesignSystem/Animation/AnimatedMeshGradient.swift)`
- Image animation on top: `[GlobeView` in `GlobeScene.swift`](Mindsprout/DesignSystem/Animation/GlobeScene.swift)

## 3. Current Asset Map

### 3.1 Static screen art in active use


| Asset                  | Used in                                                                                                                         | Current file size | Aspect ratio       | Notes                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ----------------- | ------------------ | ------------------------------------------------------------------------ |
| `HomeBackground`       | `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)`                                                                     | `4579x2556` JPG   | `1.79:1` landscape | Full-screen home background, rendered with `.scaledToFill()`             |
| `dashboard_background` | `[LevelUpFlow.swift](Mindsprout/Features/LevelUp/LevelUpFlow.swift)`                                                            | `402x874` PNG     | `1:2.17` portrait  | Matches the home layout reference size exactly                           |
| `Cloud`                | `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)`                                                                     | `432x266` PNG     | `1.62:1`           | Used for the day badge                                                   |
| `Points`               | `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)`, `[ProfileTab.swift](Mindsprout/Features/Profile/ProfileTab.swift)` | `475x622` PNG     | `0.76:1`           | Currency icon                                                            |
| `sprout_stage0_idle`   | `[LevelUpFlow.swift](Mindsprout/Features/LevelUp/LevelUpFlow.swift)`                                                            | `396x668` PNG     | `0.59:1`           | Separate still art for level-up flow, not the SpriteKit animation frames |


### 3.2 Animated globe on the welcome screen

This is the rotating earth on the first screen. The code is in `[WelcomeView.swift](Mindsprout/Features/Onboarding/WelcomeView.swift)` and `[GlobeScene.swift](Mindsprout/DesignSystem/Animation/GlobeScene.swift)`.

Current structure:

- Light mode frames: `[Mindsprout/Assets.xcassets/Globe/Globe Light](Mindsprout/Assets.xcassets/Globe/Globe%20Light)`
- Dark mode frames: `[Mindsprout/Assets.xcassets/Globe/Globe Dark](Mindsprout/Assets.xcassets/Globe/Globe%20Dark)`
- Frame count: `21` per mode
- Naming pattern: `Earth_1 ... Earth_21` and `Earth_dark_1 ... Earth_dark_21`
- Frame size: `1600x1504`
- Source aspect ratio: about `1.06:1`
- Render size in code: `800x800`

Important:

- The code switches between `Earth_` and `Earth_dark_` by prefix, not by automatic asset-catalog dark appearance. See `globePrefix` in `[GlobeScene.swift](Mindsprout/DesignSystem/Animation/GlobeScene.swift)`.
- The SpriteKit node is forced to a square `800x800` size. Keep every frame on the same source canvas or the spin will wobble.
- Keep the subject centered and keep any transparent padding consistent across all frames.

### 3.3 Sprout animation assets

The interactive home sprout is driven by `[SproutScene.swift](Mindsprout/DesignSystem/Animation/SproutAnimation/SproutScene.swift)`.

Base render behavior:

- The scene uses a base sprout height of `400` points.
- Home screen presentation scale is currently `0.90` in `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)`.
- Resting position is also adjusted in code, so the frame canvas must stay stable.

Main canvas groups:


| Group                                                       | Current size pattern      | Aspect ratio | Notes                                                    |
| ----------------------------------------------------------- | ------------------------- | ------------ | -------------------------------------------------------- |
| `Sprout_idle_*`                                             | `507x800`                 | `0.63:1`     | Baseline canvas for most standard sprout motions         |
| `Sprout_blink_*`                                            | `507x800`                 | `0.63:1`     | Used on home and also mirrored in onboarding blink logic |
| `Sprout_happy_*`                                            | `507x800`                 | `0.63:1`     | Same canvas as idle                                      |
| `Sprout_hungry_*`                                           | `507x800`                 | `0.63:1`     | Same canvas as idle                                      |
| `Sprout_walk_*`, `Sprout_walk_start_*`, `Sprout_walk_end_*` | `507x800`                 | `0.63:1`     | Keep footing aligned frame to frame                      |
| `Sprout_levelup_*`                                          | `507x800`                 | `0.63:1`     | Used by jump and level-up sequences                      |
| `Sprout_grabbed_*`, `Sprout_drag_*`, `Sprout_dropped_*`     | `507x800`                 | `0.63:1`     | Drag interaction frames                                  |
| `Sprout_sitdown_*`, `Sprout_sit_idle_*`, `Sprout_standup_*` | `507x800`                 | `0.63:1`     | Sitting cycle                                            |
| `Sprout_sleep_*`                                            | mostly `674x800`          | `0.84:1`     | Sleep pose uses a wider canvas                           |
| `Sprout_yawn_*`, early `Sprout_fall_*`                      | `507x800` to `674x800`    | mixed        | Transition into sleep                                    |
| `Sprout_wakeup_*`                                           | mixed, height stays `800` | mixed        | Wake-up narrows over the sequence                        |
| `Sprout_evolved_1_idle_*`, `Sprout_evolved_1_blink_*`       | `466x800`                 | `0.58:1`     | First evolved form                                       |


Practical rule:

- For any existing sequence, match the current canvas size of that exact sequence.
- Do not resize one frame in isolation. The animation code swaps textures directly and assumes stable alignment.

### 3.4 Seed animation assets

The seed used during transformation lives in `[SeedScene.swift](Mindsprout/DesignSystem/Animation/SeedScene.swift)` and also has helper methods in `[SproutScene.swift](Mindsprout/DesignSystem/Animation/SproutAnimation/SproutScene.swift)`.

Current structure:

- Idle frames: `Seed_idle_1 ... Seed_idle_13`
- Transform frames: `Seed_transform_1 ... Seed_transform_22` are used by code
- Current frame size: `800x800`
- Aspect ratio: `1:1`

Important:

- There is also a `Seed_transform_0` asset in the catalog, but current animation code starts from frame `1`. Do not depend on frame `0` unless you also change the code.

### 3.5 Assets present but not currently wired into production UI

These exist in the catalog but do not have a current code reference in the app source:

- `[trips_header_bg](Mindsprout/Assets.xcassets/trips_header_bg.imageset)`
- `[Sprout_sit_home](Mindsprout/Assets.xcassets/Sprout/Sprout_sit_home.imageset)`
- `[SignIcon](Mindsprout/Assets.xcassets/SignIcon)`
- `[TraveTypeIcon](Mindsprout/Assets.xcassets/TraveTypeIcon)`

Treat these as parked or future assets. Check the code before spending time updating them.

## 4. How To Add Or Replace An Asset

### 4.1 Single static image

Use this for backgrounds, badges, or icons.

1. Open `[Mindsprout/Assets.xcassets](Mindsprout/Assets.xcassets)` in Xcode.
2. Create or select the correct `.imageset`.
3. Drop the source file into the `1x` slot to match the current repo pattern.
4. Keep the asset name identical to the code string.
5. If it is a replacement, keep the same canvas size unless you are changing the code with it.
6. Run the relevant screen and check for cropping, stretching, and safe-area coverage.

### 4.2 Dark mode variant

Use this only when the asset itself changes between light and dark mode.

Current repo examples:

- `[Sprout_sit_home.imageset/Contents.json](Mindsprout/Assets.xcassets/Sprout/Sprout_sit_home.imageset/Contents.json)`

Rules:

- Light and dark files should have the same pixel size.
- If the code already switches assets by name, like the globe does, follow that existing pattern instead of mixing approaches.

### 4.3 Frame-by-frame animation

Use this for the sprout, seed, and globe.

1. Find the loading code first.
2. Copy the exact prefix and frame count from code.
3. Export every frame on the same canvas.
4. Keep the subject aligned in place across the full sequence.
5. Replace the files without renaming the asset sets unless you are also updating code.
6. Run the animation and watch for jitter, clipping, or position jumps.

Reference points:

- Sprout: `[SproutScene.swift](Mindsprout/DesignSystem/Animation/SproutAnimation/SproutScene.swift)`
- Seed: `[SeedScene.swift](Mindsprout/DesignSystem/Animation/SeedScene.swift)`
- Globe: `[GlobeScene.swift](Mindsprout/DesignSystem/Animation/GlobeScene.swift)`

## 5. Screen-Specific Notes

### Home screen

- Background image: `HomeBackground`
- Currency icon: `Points`
- Day badge art: `Cloud`
- Interactive sprout: `SproutView` from `[SproutScene.swift](Mindsprout/DesignSystem/Animation/SproutAnimation/SproutScene.swift)`
- Layout reference size: `402x874` in `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)`

If you change home background art, test on both the `402x874` and `430x932` preview sizes already defined in `[HomeTab.swift](Mindsprout/Features/Sprout/HomeTab.swift)`.

### Welcome screen

- Sky is code, not an asset
- Globe is a `21`-frame SpriteKit sequence
- Sprout above the title uses the blink frames `Sprout_blink_1`, `2`, and `3`

See `[WelcomeView.swift](Mindsprout/Features/Onboarding/WelcomeView.swift)`.

### Level-up flow

- Uses `dashboard_background`
- Uses the still asset `sprout_stage0_idle`

See `[LevelUpFlow.swift](Mindsprout/Features/LevelUp/LevelUpFlow.swift)`.

## 6. Quick Checklist Before Commit

- Asset name matches the code exactly.
- Replacement art kept the same canvas size as the old asset.
- Animated frames have no missing numbers.
- The subject stays aligned across the full sequence.
- Light and dark variants, if used, are matched in size.
- The edited screen was run and checked for stretching, clipping, and safe-area issues.
- If you changed an asset used by SpriteKit, you watched the full animation once.

## 7. If You Need To Add Something New

If the new art does not clearly fit an existing group, prefer one of these:

- New static screen art: add a new top-level `.imageset` in `[Assets.xcassets](Mindsprout/Assets.xcassets)`
- New sprout behavior: add a new sequence under `[Assets.xcassets/Sprout](Mindsprout/Assets.xcassets/Sprout)` and wire it in `[SproutScene.swift](Mindsprout/DesignSystem/Animation/SproutAnimation/SproutScene.swift)`
- New onboarding animation: place it near the current globe or sprout assets and wire it from the onboarding view that owns it

If you are unsure, start from the Swift file for the target screen, find the `Image(...)` or `SKTexture(...)` call, and follow that naming pattern exactly.