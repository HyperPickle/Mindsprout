#if DEBUG
import SwiftUI
import SwiftData

// DEBUG-only deep-link host so screens can be screenshotted in isolation
// during visual QA. Activated via the MS_SCREEN launch environment variable.
struct ScreenshotHost: View {
    let screen: String
    let container: ModelContainer
    @State private var coordinator = ModalCoordinator()

    var body: some View {
        content
            .environment(coordinator)
            .modelContainer(container)
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case "trips":
            TripsTab()
        case "profile":
            ProfileTab()
        case "settings":
            NavigationStack {
                SettingsView()
            }
        case "newtrip":
            NewTripFlow()
        case "expectations":
            ExpectationsHost()
        case "detail":
            DetailHost(container: container)
        default:
            TripsTab()
        }
    }
}

private struct ExpectationsHost: View {
    @State private var viewModel: NewTripViewModel = {
        let vm = NewTripViewModel()
        vm.type = .solo
        return vm
    }()

    var body: some View {
        NavigationStack {
            NewTripExpectationsView(viewModel: viewModel, onSave: {})
        }
    }
}

private struct DetailHost: View {
    let container: ModelContainer

    var body: some View {
        NavigationStack {
            if let id = activeTripID {
                TripDayDetailView(tripID: id, initialDayIndex: 2)
            } else {
                Text("No trips seeded")
            }
        }
    }

    private var activeTripID: UUID? {
        let context = ModelContext(container)
        let trips = (try? context.fetch(FetchDescriptor<Trip>())) ?? []
        return TripResolver.active(in: trips)?.id
    }
}
#endif
