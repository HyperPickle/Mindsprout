import SwiftUI

struct ModalContainer: View {
    let modal: AppModal

    var body: some View {
        switch modal {
        case .newTrip:
            NewTripFlow()
        case .editTrip(let tripID):
            EditTripFlow(tripID: tripID)
        case .reflection(let tripID):
            ReflectionCoverFlow(tripID: tripID)
        case .todayReflection(let reflectionID):
            TodayReflectionView(reflectionID: reflectionID)
        case .levelUp(let presentation):
            LevelUpFlow(presentation: presentation)
        case .shop:
            ShopComingSoonModal()
        case .themeSettings:
            ThemeSettingsModal()
        case .aboutSettings:
            AboutSettingsModal()
        case .profilePhoto:
            ProfilePhotoModal()
        case .account:
            AccountModal()
        case .xpDetail:
            XPDetailModal()
        }
    }
}

#Preview {
    ModalContainer(modal: .newTrip)
}
