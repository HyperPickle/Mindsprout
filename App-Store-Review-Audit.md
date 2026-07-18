# App Review Audit — 2026-07-18

**App:** Mindsprout (v1.0) · Lifestyle · Universal (iPhone + iPad, family 1,2) · iOS 26.0 min
**Context:** App was **rejected on 2026-07-13 under Guideline 4 (Design)** — "crowded interface / laid out in a way that makes it difficult to complete tasks," reviewed on **iPad Air 11-inch (M3)**. This audit prioritizes that rejection and its likely repeat vectors.
**Guidelines source:** Live page fetched 2026-07-18 (Apple's "living document" — re-fetch before the actual resubmission).

## Summary
**Medium-to-high risk of a repeat rejection** as-is, driven by two concrete issues: (1) the in-progress iPad layout fix (`contentColumn`) was applied to most screens but **skipped the Reflection flow — the app's primary task surface — which still stretches edge-to-edge on iPad**, the exact class of problem Apple flagged; and (2) a reachable **"Shop Coming Soon" placeholder**, a textbook 2.1 rejection that is especially dangerous on a resubmission. Everything else (login, tracking, permissions, account deletion, privacy link) is in good shape. Fix these two and first-pass odds improve substantially.

---

## 🔴 Confirmed Issues (visible in code/config)

### 1. Reflection flow is not width-constrained on iPad — repeat of the Guideline 4 rejection
- **Guideline:** 4 Design / 2.4 Hardware Compatibility (iPad)
- **What I found:** The iPad fix `contentColumn()` (caps content to 560pt and centers) was correctly applied to Profile (`ProfileTab.swift:135`), Settings (`SettingsView.swift:79`), Trips overview/detail/new/edit, and Wardrobe. `HomeTab.swift` separately adapts via `horizontalSizeClass == .regular` (stage scaling, `HomeTab.swift:102-119`). **But the Reflection flow was missed entirely** — `ReflectionFlow.swift:40`, `EntryStep.swift:37,56,77,265…` and sibling steps use `.frame(maxWidth: .infinity)` throughout with **no `contentColumn` and no size-class handling**. `grep` confirms `contentColumn` appears in zero Reflection files.
- **Why it's flagged:** Reflection capture (write / photo / audio) is the app's core task. On the iPad Air 11" — the exact device Apple rejected on — its text fields and content stretch full-width, which is precisely "laid out in a way that makes it difficult to complete tasks."
- **Suggested fix:** Apply `.contentColumn()` to the reflection step content (or wrap the `ReflectionFlow` container). Mirror the treatment already used on Trips. Then re-screenshot the reflection flow on an 11" iPad to confirm.

### 2. "Shop Coming Soon" placeholder is reachable in the shipped UI
- **Guideline:** 2.1 App Completeness (also 2.3 Accurate Metadata)
- **What I found:** `ProfileTab.swift:122-124` renders a "Shop" action button → `modalCoordinator.present(.shop)` → `ShopComingSoonModal` (`SettingsModals.swift:161-177`) displaying **"Shop Coming Soon" / "We're working on bringing you the shop in a future update."** A second dead placeholder exists at `ShopView.swift:8-13` (`PlaceholderScreen`, "Shop design pending").
- **Why it's flagged:** Apple explicitly rejects placeholder and "coming soon" content under 2.1. On a resubmission this is high-risk — reviewers scrutinize previously-rejected apps more closely and this is an easy, unambiguous flag.
- **Suggested fix:** Remove the "Shop" button from `ProfileTab` (and any coin/currency affordance that implies a purchasable shop) until the shop actually ships, or gate it behind a build/feature flag that is off for the App Store build. Delete or exclude the unused `ShopView.swift`. Do not ship any "Coming Soon" screen.

---

## 🟡 Needs Human Check (can't verify from repo alone)

### A. Speech Recognition usage description (moderate — test on device)
- **Guideline:** 2.1 (runtime crash) / 2.5
- **What to verify:** `SpeechTranscriptionService.swift` uses the **iOS 26 `SpeechAnalyzer`/`SpeechTranscriber`** on-device API (not legacy `SFSpeechRecognizer`), and no `NSSpeechRecognitionUsageDescription` is set. The modern API is fully on-device and most likely does **not** require that key — but confirm by running the audio-reflection → transcription flow on a **physical device**. If it prompts for speech permission or crashes, add `NSSpeechRecognitionUsageDescription`. Adding it defensively is harmless. (Microphone/camera/photo strings are present and purpose-specific — good.)

### B. iPad orientation lock
- **Guideline:** 2.4 / 4
- **What to verify:** iPad is locked to portrait + portrait-upside-down (`INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad`). Not strictly required, but Apple encourages landscape on iPad, and a reviewer who rotates the device sees no adaptation. Confirm portrait-only is an intentional design choice; if so it's defensible alongside the `contentColumn` fix.

### C. Privacy policy completeness & wiring
- **Guideline:** 5.1.1
- **What to verify:** In-app link present (`SettingsView.swift:63,85` → `https://mindsprout-website.vercel.app/privacy.html`). Confirm (1) the URL is live, (2) the **same URL is set in App Store Connect**, and (3) it discloses camera, microphone, photo library, and Apple ID (name/email). Disclosures are minimal since analytics is a No-Op and AI is on-device.

### D. Sign-in review access (no demo account needed, but confirm)
- **Guideline:** 2.1
- **What to verify:** App is gated behind Sign in with Apple (`RootView.swift:34` → `OnboardingCoordinatorView` → `WelcomeView`). SIWA works with the reviewer's own Apple ID and `WelcomeView.handleResult` is fully local (no backend call), so no demo account is required — confirm sign-in completes **offline** and doesn't depend on `mindsprout-proxy.vercel.app` (that host is only used for account-deletion revoke).

### E. Account deletion end-to-end
- **Guideline:** 5.1.1(v)
- **What to verify:** In-app deletion exists (`AccountDeletionService`, `AppleCredentialRevocationService`, SIWA re-auth in `SettingsModals`, revoke endpoint in Info.plist). Confirm it deletes **both server and local data** and that the revoke endpoint is live during review.

### F. Age rating / audience
- **Guideline:** 1.3 / 5.1.4
- **What to verify:** The cute gamified sprout may read as kid-appealing. Confirm the age-rating questionnaire is accurate and the app is **not** marketed "for Kids" (it's Lifestyle, not Kids Category). Currently moot for analytics (No-Op), but keep it that way if targeting a general audience.

### G. Metadata / screenshots
- **Guideline:** 2.3
- **What to verify:** Screenshots show real app UI (Home / Trips / Reflection), not splash or login; iPad screenshots reflect the corrected layout; app name "Mindsprout" ≤30 chars (✓).

---

## 🟢 Looks Compliant (explicitly checked)
- **4.8 Login Services:** Sign in with Apple is the **only** login (`WelcomeView`, `SettingsModals`) — the privacy-preserving-alternative requirement is inherently satisfied; no third-party social login present.
- **5.1.2 Data Use / ATT:** No tracking SDKs; `AnalyticsService` ships as `NoOpAnalyticsService`; no IDFA/`ATTrackingManager`. AI generation defaults to on-device `TemplateAIGenerationService` (no third-party-AI data sharing) — no ATT or AI-disclosure obligation triggered.
- **5.1.1 Permission strings:** Camera, microphone, and photo-library usage descriptions present and purpose-specific.
- **1.2 UGC:** Personal journaling only — no inter-user content sharing or social features, so moderation/report/block requirements don't apply.
- **3.1.1 IAP:** No StoreKit/purchase code; nothing currently sold for money → no IAP-bypass. (When the shop ships selling digital goods, it **must** use StoreKit IAP — do not use external keys/currency.)
- **2.4 iPad (target level):** Universal app; `HomeTab` explicitly adapts to regular width.
- **2.5.1 APIs:** Public iOS 26 frameworks only.
- **1.6 Data security:** Keychain used for credentials (`KeychainStore`).
- **5.1.5 Location:** `CLLocationCoordinate2D` used only to render map annotations on trip cards; no `CLLocationManager`/user-location request, so no location permission needed (correctly absent).

---

## Pre-Submission Checklist
- [ ] **Apply `contentColumn` (or size-class handling) to the Reflection flow** and re-screenshot on iPad Air 11"
- [ ] **Remove the "Shop / Shop Coming Soon" placeholder** from the shipped build (and delete unused `ShopView.swift`)
- [ ] Test audio-reflection transcription on a physical device; add `NSSpeechRecognitionUsageDescription` if prompted/crashing
- [ ] Confirm Sign in with Apple completes offline (reviewer uses own Apple ID; no demo account needed)
- [ ] Verify account deletion wipes server + local data; revoke endpoint live at review time
- [ ] Privacy policy URL live, set in App Store Connect, and matches in-app link + actual data practices
- [ ] Screenshots show real app UI (incl. corrected iPad layout), not splash/login
- [ ] Age-rating questionnaire matches actual content; app not marketed "for Kids"
- [ ] In "Notes for Review," describe the specific iPad layout changes made since the 2026-07-13 rejection (Apple requires specificity)
