import SwiftUI

struct ModalContainer: View {
    let modal: AppModal

    var body: some View {
        switch modal {
        case .newTrip:
            NewTripFlow()
        case .levelUp(let presentation):
            LevelUpFlow(presentation: presentation)
        case .shop:
            ShopView()
        }
    }
}

#Preview {
    ModalContainer(modal: .newTrip)
}
