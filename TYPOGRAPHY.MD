# Typography

This file explains how typography works in Mindsprout and how to choose the right text style when editing or adding UI.

## 1. Source of Truth

The typography system lives in `[Mindsprout/DesignSystem/Typography.swift](/Users/rishisinghal/Documents/Projects/Mindsprout/Mindsprout/DesignSystem/Typography.swift:1)`.

All app text should start from `AppFont`.

```swift
Text("Feed Sprout")
    .font(AppFont.button)
```

The visual reference for these styles is `[Mindsprout/DesignSystem/DesignSystemGallery.swift](/Users/rishisinghal/Documents/Projects/Mindsprout/Mindsprout/DesignSystem/DesignSystemGallery.swift:13)`.

## 2. How the system adapts

`AppFont` is built on top of SwiftUI text styles such as `.largeTitle`, `.title`, `.body`, and `.footnote`, instead of fixed sizes for normal text.

That matters because it means:

- type scales with the system's text settings
- the hierarchy stays consistent across screens
- changing the app's font choices can happen in one place

Most styles use the rounded system design. Metrics and timers are the only special cases:

- `metricLarge` and `metric` use `monospacedDigit()` so numbers do not jump around
- `timerLarge` and `timerCompact` use a monospaced design for stable time readouts

## 3. Font roles

Use the role that matches the job of the text, not the screen it appears on.


| `AppFont`        | Base style           | Use it for                                                 |
| ---------------- | -------------------- | ---------------------------------------------------------- |
| `display`        | `.largeTitle`        | hero copy, key moments, big celebratory text               |
| `screenTitle`    | `.title`             | top-level screen headings                                  |
| `sectionTitle`   | `.title3`            | section headings inside a screen or card                   |
| `bodyEmphasized` | `.body` medium       | important body copy, selected values, primary card content |
| `body`           | `.body` regular      | standard reading text                                      |
| `callout`        | `.callout` medium    | supporting copy, short helper text, secondary content      |
| `caption`        | `.footnote` medium   | metadata, small supporting labels                          |
| `eyebrow`        | `.caption2` semibold | overlines, tiny category labels, compact headers           |
| `button`         | `.body` bold         | button labels and strong actions                           |
| `metricLarge`    | `.largeTitle`        | large XP or numeric highlights                             |
| `metric`         | `.headline`          | smaller numeric summaries                                  |
| `timerLarge`     | `.title` monospaced  | main timer readouts                                        |
| `timerCompact`   | `.title3` monospaced | smaller timer readouts                                     |


The definitions are here: `[Typography.swift](/Users/rishisinghal/Documents/Projects/Mindsprout/Mindsprout/DesignSystem/Typography.swift:3)`.

## 4. How to choose a font

Pick in this order:

1. If it is a screen heading, use `screenTitle`.
2. If it is a heading inside a section, card, sheet, or block, use `sectionTitle`.
3. If it is normal reading text, start with `body`.
4. If that text needs a bit more presence without becoming a heading, use `bodyEmphasized` or `callout`.
5. If it is very small supporting information, use `caption` or `eyebrow`.
6. If it is an action label, use `button`.
7. If it is numeric data or time, use one of the metric or timer styles.

When two styles could work, prefer the less dramatic one first.

## 5. How to categorise text in the app

This is the simplest way to sort a piece of text before choosing a style:

- **Primary heading**: the main label for the whole screen. Use `screenTitle`.
- **Local heading**: introduces a subsection, card, modal, or content block. Use `sectionTitle`.
- **Main content**: the text the user is actually reading. Use `body` or `bodyEmphasized`.
- **Support text**: extra context, explanation, or softer secondary copy. Use `callout`.
- **Meta text**: dates, labels, counts, status detail, short notes. Use `caption` or `eyebrow`.
- **Action text**: buttons and direct prompts. Use `button`.
- **Data text**: XP, levels, timers, or anything where numeric alignment matters. Use `metricLarge`, `metric`, `timerLarge`, or `timerCompact`.

## 6. When to use a one-off font

In most cases, do not.

Prefer `AppFont` for any real text content. A raw `.font(.system(size: ...))` should be rare and usually limited to:

- icon-only views
- decorative symbols or emoji
- temporary placeholder UI
- a very specific visual treatment that clearly does not fit an existing role

If the text is meaningful content and the style is likely to be reused, add or adjust an `AppFont` role instead of scattering custom sizes through screens.

