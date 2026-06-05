
import SwiftUI
import Combine

class OnboardingCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedTravelType: TravelType?
    @Published var selectedExpectations: [String] = []
    
    enum TravelType: String, Hashable, CaseIterable {
        case solo = "Solo"
        case family = "Family"
        case friends = "Friends"
        case business = "Business"
        
        var icon: String {
            switch self {
            case .solo: return "Solo"
            case .family: return "Family"
            case .friends: return "Friends"
            case .business: return "Business"
            }
        }
    }
    
    enum Route: Hashable {
        case travelTypeDetail(TravelType)
    }
    
    func goToDetail() {
        guard let type = selectedTravelType else { return }
        path.append(Route.travelTypeDetail(type))
    }
}
