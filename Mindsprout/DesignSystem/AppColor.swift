import SwiftUI
import UIKit

enum AppColor {
    static let cardSurface = Color.white
    static let graphite = Color(hex: 0x040E10)
    static let skyTop = Color(hex: 0xBFE3EF)
    static let skyBottom = Color(hex: 0xE9F4F2)
    static let grassTop = Color(hex: 0x9BC56A)
    static let grassBottom = Color(hex: 0x5E8C3C)

    static let primary = Color(hex: 0x7FB84F)
    static let primaryEdge = Color(hex: 0x4F7A2E)
    static let currency = Color(hex: 0xE8B84B)

    static let label = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 4/255, green: 14/255, blue: 16/255, alpha: 1)
    })

    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let placeholder = Color(UIColor.placeholderText)
    static let separator = Color(UIColor.separator)

    static let inverseLabel = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 4/255, green: 14/255, blue: 16/255, alpha: 1)
            : .white
    })


    static let destructive = Color(hex: 0xC0392B)

    static let hairline = Color(hex: 0xD9CFBF)
    static let pillSelected = Color(hex: 0x6E5A48)
    static let pillUnselected = Color(hex: 0xE7DECF)

    static let headerBrown = Color(hex: 0x7C6A58)
    static let calendarSelected = Color(hex: 0x2E2A26)
    static let calendarInRange = Color(hex: 0xC9BEAE)
}
