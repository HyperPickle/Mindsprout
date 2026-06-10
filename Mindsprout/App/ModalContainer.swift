import SwiftUI

struct ModalContainer: View {
    let modal: AppModal

    var body: some View {
        switch modal {
        case .newTrip:
            NewTripFlow()
        case .editTrip(let tripID):
            EditTripFlow(tripID: tripID)
        case .levelUp(let presentation):
            LevelUpFlow(presentation: presentation)
        case .shop:
            ShopView()
        case .themeSettings:
            ThemeSettingsModal()
        case .notificationsSettings:
            NotificationsSettingsModal()
        case .helpSupport:
            HelpSupportModal()
        case .aboutSettings:
            AboutSettingsModal()
        }
    }
}

#Preview {
    ModalContainer(modal: .newTrip)
}
