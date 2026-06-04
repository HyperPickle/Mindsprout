import SwiftUI
import SwiftData

struct ReflectTab: View {
    @Binding var selection: AppTab
    @Environment(\.modelContext) private var context

    private var activeTrip: Trip? {
        try? TripRepository(context: context).activeTrip()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if let trip = activeTrip {
                    ReflectionFlow(tripID: trip.id) {
                        selection = .home
                    }
                } else {
                    SandBackground().ignoresSafeArea()
                    emptyState
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "airplane.circle")
                .font(.system(size: 56))
                .foregroundStyle(AppColor.hairline)
            Text("No active trip")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.ink)
            Text("Start a trip on the Adventures tab to begin reflecting.")
                .font(AppFont.callout)
                .foregroundStyle(AppColor.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
            Spacer()
        }
    }
}

#Preview {
    // Create an in-memory ModelContainer for SwiftData previews
    let schema = Schema([Trip.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])

    // Optionally insert mock data here if needed
    // let context = container.mainContext

    return ReflectTab(selection: .constant(.reflect))
        .environment(\.modelContext, container.mainContext)
}
