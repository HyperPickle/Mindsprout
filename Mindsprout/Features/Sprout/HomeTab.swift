import Foundation
import SwiftUI
import SwiftData

struct HomeTab: View {
    private let homeCTAHorizontalPadding: CGFloat = Spacing.screenEdge
    private let progressionEngine = SproutProgressionEngine()

    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.appEnvironment) private var env

    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    @Query(sort: \Sprout.createdAt) private var sprouts: [Sprout]

    private var pillTextColor: Color {
        AppColor.label
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

    private var todayCompletedReflection: Reflection? {
        guard let activeTrip else { return nil }
        return todaysCompletedReflection(for: activeTrip, in: context)
    }

    private var ctaAction: HomeDashboardCTAAction {
        HomeDashboardState(
            hasActiveTrip: activeTrip != nil,
            completedTodayReflectionID: todayCompletedReflection?.id
        ).ctaAction
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                dashboardContent
                bottomPanel
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, Spacing.md)
            }
            .task {
                ensureSproutExists()
            }
            .background(
                dashboardBackground
            )
        }
    }

    private var dashboardBackground: some View {
        Image("HomeBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var dashboardContent: some View {
        GeometryReader { proxy in
            let layout = HomeDashboardLayout(size: proxy.size)

            ZStack {
                sproutStage(layout: layout)

                VStack {
                    topRow(layout: layout)
                    Spacer()
                }
                .padding(.top, layout.topRowTopInset)
            }
        }
    }

    private func topRow(layout: HomeDashboardLayout) -> some View {
        HStack(alignment: .top, spacing: layout.topRowSpacing) {
            tripCard
                .frame(width: layout.tripCardWidth, height: layout.topCardHeight, alignment: .topLeading)

            xpProgressButton
                .frame(width: layout.progressCardWidth, alignment: .topLeading)
        }
        .padding(.horizontal, layout.topRowHorizontalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tripCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(activeTrip?.destination ?? "No trip yet")
                .font(AppFont.sectionTitle)
                .foregroundStyle(pillTextColor)
                .lineLimit(1)

            Text(activeTrip?.country ?? "Start a trip")
                .font(AppFont.callout)
                .foregroundStyle(pillTextColor.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var xpProgressButton: some View {
        Button {
            modalCoordinator.present(.xpDetail)
        } label: {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(xpProgressValueText)
                    .font(AppFont.metric)
                    .foregroundStyle(pillTextColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View experience details")
    }

    private func sproutStage(layout: HomeDashboardLayout) -> some View {
        SproutView(
            state: displaySprout.state.homeDisplayState,
            restingVerticalOffset: layout.sproutVerticalOffset
        )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }

    private var bottomPanel: some View {
        VStack(spacing: Spacing.sm) {
            ctaButton
        }
    }

    private var ctaButton: some View {
        HomeCTAButton(title: ctaLabel, widthScale: 1) {
            switch ctaAction {
            case .createTrip:
                modalCoordinator.present(.newTrip)
            case .startReflection:
                guard let activeTrip else { return }
                modalCoordinator.present(.reflection(tripID: activeTrip.id))
            case .viewTodayReflection(let reflectionID):
                modalCoordinator.present(.todayReflection(reflectionID: reflectionID))
            }
        }
        .padding(.horizontal, homeCTAHorizontalPadding)
    }

    private var ctaLabel: LocalizedStringKey {
        switch ctaAction {
        case .createTrip: return "Create a Trip"
        case .startReflection: return "Reflect to Feed"
        case .viewTodayReflection: return "View Reflection"
        }
    }

    private func ensureSproutExists() {
        guard sprouts.isEmpty else { return }
        context.insert(Sprout())
        try? context.save()
    }

    private var xpProgressValueText: String {
        guard let xpRemainingToNextLevel else { return "Max level reached" }
        return "\(abbreviatedXP(xpRemainingToNextLevel)) XP to Level Up"
    }

    private var xpRemainingToNextLevel: Int? {
        let level = max(displaySprout.level, progressionEngine.level(forTotalXP: displaySprout.xp))
        guard level < progressionEngine.config.maxLevel else { return nil }
        let progress = progressionEngine.levelProgress(totalXP: displaySprout.xp, level: level)
        return max(progress.span - progress.within, 0)
    }

    private func abbreviatedXP(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }

        let abbreviated = Double(value) / 1_000
        if value.isMultiple(of: 1_000) {
            return "\(Int(abbreviated))K"
        }

        return String(format: "%.1fK", abbreviated)
    }
}

struct HomeDashboardLayout {
    static let sproutAspectRatio: CGFloat = 507.0 / 800.0
    static let referenceCTAHeight: CGFloat = HomeCTAButton.referenceHeight
    static let ctaScale: CGFloat = HomeCTAButton.widthScale

    let topRowTopInset: CGFloat
    let topRowHorizontalInset: CGFloat
    let topRowSpacing: CGFloat
    let topCardHeight: CGFloat
    let tripCardWidth: CGFloat
    let progressCardWidth: CGFloat
    let sproutWidth: CGFloat
    let sproutHeight: CGFloat
    let sproutVerticalOffset: CGFloat
    let sproutViewportSize: CGSize
    let ctaWidth: CGFloat
    let ctaHeight: CGFloat

    init(size: CGSize) {
        let referenceWidth: CGFloat = 402
        let referenceHeight: CGFloat = 874
        let scaleX = size.width / referenceWidth
        let scaleY = size.height / referenceHeight

        topRowTopInset = max(18, 26 * scaleY)
        topRowHorizontalInset = max(14, Spacing.screenEdge * scaleX)
        topRowSpacing = max(10, 12 * scaleX)
        topCardHeight = max(88, 94 * scaleY)

        let availableWidth = max(0, size.width - (topRowHorizontalInset * 2) - topRowSpacing)
        tripCardWidth = availableWidth * 0.55
        progressCardWidth = availableWidth - tripCardWidth

        let sproutCenterY = 455 * scaleY
        sproutHeight = 400 * scaleY
        sproutWidth = sproutHeight * Self.sproutAspectRatio
        sproutVerticalOffset = (size.height / 2) - sproutCenterY
        sproutViewportSize = size

        let currentCTAWidth = max(0, size.width - (Spacing.screenEdge * 2))
        ctaWidth = currentCTAWidth * Self.ctaScale
        ctaHeight = Self.referenceCTAHeight * Self.ctaScale
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
    HomeTab()
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: true, fedToday: false))
        .frame(width: 402, height: 874)
}

#Preview("Home - Today's Reflection") {
    HomeTab()
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: true, fedToday: true))
        .frame(width: 430, height: 932)
}

#Preview("Home - No Trip Small") {
    HomeTab()
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: false, fedToday: false))
        .frame(width: 320, height: 568)
}
