import UIKit

/// Configuration for the floating action button (FAB) in FabBar.
///
/// The FAB appears as a circular glass button next to the tab items,
/// morphing with the iOS 26 glass effect.
@available(iOS 26.0, *)
public struct FabBarAction {
    /// The SF Symbol name for the button icon.
    public let systemImage: String

    /// The accessibility label for VoiceOver users.
    public let accessibilityLabel: String

    /// The tint applied to the FAB glass. Pass `nil` for untinted Liquid Glass.
    public let tintColor: UIColor?

    /// The tint applied to the FAB icon.
    public let iconTintColor: UIColor

    /// Optional label text displayed below the FAB glass circle.
    public let title: String?

    /// The action to perform when the button is tapped.
    public let action: () -> Void

    /// Creates a floating action button configuration.
    ///
    /// - Parameters:
    ///   - systemImage: The SF Symbol name for the button icon.
    ///   - accessibilityLabel: The accessibility label for VoiceOver users.
    ///   - title: Optional label displayed below the FAB circle.
    ///   - action: The action to perform when the button is tapped.
    public init(
        systemImage: String,
        accessibilityLabel: String,
        tintColor: UIColor? = .tintColor,
        iconTintColor: UIColor = .white,
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.tintColor = tintColor
        self.iconTintColor = iconTintColor
        self.title = title
        self.action = action
    }
}
