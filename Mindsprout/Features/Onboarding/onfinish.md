# WelcomeView integration note

`WelcomeView` needs an `onFinish: () -> Void` parameter so `RootView` can dismiss it and mark onboarding as complete.

If the parameter is missing, add it to the struct:

```swift
struct WelcomeView: View {
    var onFinish: () -> Void

    // rest of implementation...
}
```

Then call it wherever the user completes or skips onboarding:

```swift
Button("Get Started") { onFinish() }
```

`RootView` passes this in automatically — no other changes needed on that side.
