import SwiftUI
import SwiftData

struct HomeTab: View {
    private let tripPillWidth: CGFloat = 98

    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: AppTab

    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.appEnvironment) private var env

    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    @Query(sort: \Sprout.createdAt) private var sprouts: [Sprout]

    private var pillTextColor: Color {
        colorScheme == .dark ? .white : AppColor.ink
    }

    private var activeTrip: Trip? {
        TripResolver.active(in: trips)
    }

    private var sprout: Sprout? {
        sprouts.first
    }

    private var displaySprout: Sprout {
        sprout ?? Sprout()
    }

    private var ctaAction: HomeDashboardCTAAction {
        HomeDashboardState(hasActiveTrip: activeTrip != nil).ctaAction
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                dashboardBackground
                dashboardContent
                bottomPanel
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, Spacing.xl + 75)
            }
            .task {
                ensureSproutExists()
            }
        }
    }

    private var dashboardBackground: some View {
        Image("dashboard_background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var dashboardContent: some View {
        GeometryReader { proxy in
            let layout = HomeDashboardLayout(size: proxy.size)

            ZStack {
                tripPill
                    .frame(width: layout.tripGroupWidth, height: layout.tripPillHeight)
                    .position(x: layout.tripGroupCenterX, y: layout.topRowCenterY)

                currencyButton
                    .frame(width: layout.currencyPillWidth, height: layout.currencyPillHeight)
                    .position(x: layout.currencyPillCenterX, y: layout.topRowCenterY)

                sproutStage(layout: layout)
                    .frame(width: layout.sproutWidth, height: layout.sproutHeight)
                    .position(x: layout.sproutCenterX, y: layout.sproutCenterY)
            }
        }
    }

    private var tripPill: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(activeTrip?.destination ?? "No trip yet")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(pillTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
                Text(activeTrip?.country ?? "Start an adventure")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(pillTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            Spacer()
        }
        .padding(.leading, 16)
        .frame(width: tripPillWidth, height: 48)
        .background(alignment: .leading) {
            Color.clear
                .frame(width: tripPillWidth * 1.3, height: 48)
                .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(alignment: .trailing) {
            if let activeTrip {
                dayBadge(day: displayedDayIndex(for: activeTrip), totalDays: tripDuration(for: activeTrip))
                    .offset(x: 39, y: 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func dayBadge(day: Int, totalDays: Int) -> some View {
        ZStack {
            Image(systemName: "cloud.fill")
                .font(.system(size: 43, weight: .medium))
                .foregroundStyle(AppColor.cardSurface)
                .shadow(color: AppColor.ink.opacity(0.08), radius: 4, x: 0, y: 2)
                .offset(y: 5)

            VStack(spacing: 0) {
                Text("day")
                    .font(.system(size: 6, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColor.inkSecondary)
                    .textCase(.uppercase)
                    .offset(y: 7)
                Text("\(day) / \(totalDays)")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.ink)
                    .monospacedDigit()
                    .offset(y: 7)
            }
        }
        .frame(width: 40, height: 26)
    }

    private var currencyButton: some View {
        Button {
            modalCoordinator.present(.shop)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(pillTextColor)
                Text("\(displaySprout.currency)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(pillTextColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open shop")
    }

    private func sproutStage(layout: HomeDashboardLayout) -> some View {
        SproutView(state: displaySprout.state.homeDisplayState)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private var bottomPanel: some View {
        VStack(spacing: Spacing.sm) {
            ctaButton
        }
    }

    private var ctaButton: some View {
        Button {
            switch ctaAction {
            case .startReflection:
                selection = .reflect
            case .createTrip:
                modalCoordinator.present(.newTrip)
            }
        } label: {
            Text(ctaLabel)
                .font(AppFont.button)
                .textCase(.uppercase)
                .foregroundStyle(AppColor.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .glassEffect(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(.white.opacity(0.35))
                        .allowsHitTesting(false)
                }
        }
        .buttonStyle(.plain)
        .containerRelativeFrame(.horizontal) { w, _ in w * 0.75 }
    }

    private var ctaLabel: LocalizedStringKey {
        switch ctaAction {
        case .startReflection: return "Reflect to Feed"
        case .createTrip: return "Create a Trip"
        }
    }

    private func ensureSproutExists() {
        guard sprouts.isEmpty else { return }
        context.insert(Sprout())
        try? context.save()
    }

    private func tripDuration(for trip: Trip) -> Int {
        let components = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate)
        return max(1, (components.day ?? 0) + 1)
    }

    private func displayedDayIndex(for trip: Trip) -> Int {
        min(dayIndex(for: trip), tripDuration(for: trip))
    }
}

private struct HomeDashboardLayout {
    let topRowCenterY: CGFloat
    let tripGroupCenterX: CGFloat
    let tripGroupWidth: CGFloat
    let tripPillHeight: CGFloat
    let currencyPillCenterX: CGFloat
    let currencyPillWidth: CGFloat
    let currencyPillHeight: CGFloat
    let sproutCenterX: CGFloat
    let sproutCenterY: CGFloat
    let sproutWidth: CGFloat
    let sproutHeight: CGFloat

    init(size: CGSize) {
        let referenceWidth: CGFloat = 402
        let referenceHeight: CGFloat = 874
        let scaleX = size.width / referenceWidth
        let scaleY = size.height / referenceHeight

        topRowCenterY = 95 * scaleY
        tripGroupCenterX = 106 * scaleX
        tripGroupWidth = 192 * scaleX
        tripPillHeight = 52 * scaleY

        currencyPillCenterX = 338 * scaleX
        currencyPillWidth = 112 * scaleX
        currencyPillHeight = 42 * scaleY

        sproutCenterX = 201 * scaleX
        sproutCenterY = 455 * scaleY
        sproutWidth = 260 * scaleX
        sproutHeight = 360 * scaleY
    }
}

private enum HomeTabPreviewData {
    static func makeContainer(activeTrip: Bool, fedToday: Bool) -> ModelContainer {
        let container = PersistenceController.makeInMemoryContainer()
        let context = ModelContext(container)

        let sprout = Sprout(xp: fedToday ? 10 : 0, level: 1, currency: activeTrip ? 1_500 : 0)
        context.insert(sprout)

        if activeTrip {
            let trip = Trip(
                destination: "Kyoto",
                country: "Japan",
                startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
            )
            context.insert(trip)

            if fedToday {
                let reflection = Reflection(
                    tripID: trip.id,
                    dayIndex: dayIndex(for: trip),
                    date: Date(),
                    highlightPrompt: "A quiet morning walk",
                    bodyKind: .text,
                    text: "I slowed down enough to notice details.",
                    isDraft: false
                )
                reflection.xpAwarded = 10
                context.insert(reflection)
            }
        }

        try? context.save()
        return container
    }
}

#Preview("Home - Active Trip") {
    HomeTab(selection: .constant(.home))
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: true, fedToday: false))
        .frame(width: 402, height: 874)
}

#Preview("Home - Resting") {
    HomeTab(selection: .constant(.home))
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: true, fedToday: true))
        .frame(width: 430, height: 932)
}

#Preview("Home - No Trip Small") {
    HomeTab(selection: .constant(.home))
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: false, fedToday: false))
        .frame(width: 320, height: 568)
}
