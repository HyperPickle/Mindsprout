import SwiftUI

extension View {
    /// Caps content to a readable column and centers it inside the available
    /// width. On iPhone widths the cap never binds, so layout is unchanged;
    /// on iPad it keeps screens from stretching edge-to-edge.
    func contentColumn(maxWidth: CGFloat = 560) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
