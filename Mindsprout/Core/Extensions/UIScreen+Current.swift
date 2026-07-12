import UIKit

extension UIScreen {
    /// The screen backing the app's active window scene.
    ///
    /// Replacement for the deprecated `UIScreen.main` (iOS 26). Returns `nil`
    /// if no connected `UIWindowScene` is available yet.
    static var current: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen
    }
}
