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
            ShopComingSoonModal()
        case .themeSettings:
            ThemeSettingsModal()
        case .helpSupport:
            HelpSupportModal()
        case .aboutSettings:
            AboutSettingsModal()
        case .profilePhoto:
            ProfilePhotoModal()
        }
    }
}

#Preview {
    ModalContainer(modal: .newTrip)
}
