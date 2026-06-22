import Foundation
import SwiftUI
import SwiftData
import UIKit

struct HomeTab: View {
    private let homeCTAHorizontalPadding: CGFloat = Spacing.screenEdge
    private let progressionEngine = SproutProgressionEngine()

    @Binding var selection: AppTab

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.appEnvironment) private var env

    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    @Query(sort: \Sprout.createdAt) private var sprouts: [Sprout]

    @State private var bubbleOffset: CGFloat = 0

    private var pillTextColor: Color { AppColor.label }

    private var activeTrip: Trip? { TripResolver.active(in: trips) }
    private var sprout: Sprout? { sprouts.first }
    private var displaySprout: Sprout { sprout ?? Sprout() }

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

    private var tripPillWidth: CGFloat {
        activeTrip == nil ? 200 : 150
    }

    // MARK: - Hungry State

    private var sproutDisplayState: SproutState {
        let hour = Calendar.current.component(.hour, from: Date())
        if !reflectedToday() && hour >= 20 {
            return .hungry
        }
        return displaySprout.state.homeDisplayState
    }

    private func reflectedToday() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return reflections.contains { reflection in
            Calendar.current.startOfDay(for: reflection.date) == today
            && !reflection.isDraft
        }
    }

    // MARK: - Body

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
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(3600))
                }
            }
            .background(dashboardBackground)
        }
        .ignoresSafeArea()
        .toolbarBackground(.hidden, for: .tabBar)
    }

    // MARK: - Background

    private var dashboardBackground: some View {
        Image("HomeBackground")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        GeometryReader { proxy in
            let layout = HomeDashboardLayout(size: proxy.size)

            ZStack {
                // Sprout
                sproutStage(layout: layout)

                // Top row: trip pill + day badge + currency
                tripPill
                    .frame(width: layout.tripGroupWidth, height: layout.tripPillHeight)
                    .position(x: layout.tripGroupCenterX, y: layout.topRowCenterY)

                currencyButton
                    .frame(height: layout.currencyPillHeight)
                    .position(x: layout.currencyPillCenterX, y: layout.topRowCenterY)

                // ✅ DropBubble uniquement si hungry
                if sproutDisplayState == .hungry {
                    Button {
                        if let activeTrip {
                            modalCoordinator.present(.reflection(tripID: activeTrip.id))
                        }
                    } label: {
                        Image("DropBubble")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .offset(y: bubbleOffset)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 0.8)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    bubbleOffset = -8
                                }
                            }
                            .onDisappear {
                                bubbleOffset = 0
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height / 2 - 160
                    )
                    .transition(.scale.combined(with: .opacity))
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6),
                        value: sproutDisplayState == .hungry
                    )
                }
            }
        }
    }

    // MARK: - Trip Pill

    private var tripPill: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(activeTrip?.destination ?? "No trip yet")
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color(hex: 0xFFFFFF) : Color(hex: 0x6B4C2A))
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
                Text(activeTrip?.country ?? "Start an adventure")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color(hex: 0xFFFFFF) : Color(hex: 0x705A4D))
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)
            }
            Spacer()
        }
        .padding(.leading, 16)
        .padding(.trailing, activeTrip == nil ? 16 : 0)
        .frame(width: tripPillWidth, height: 48)
        .background(alignment: .leading) {
            Color.clear
                .frame(width: activeTrip == nil ? tripPillWidth : tripPillWidth * 1.3, height: 60)
                .glassEffect(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(alignment: .trailing) {
            if let activeTrip {
                dayBadge(
                    day: displayedDayIndex(for: activeTrip),
                    totalDays: tripDuration(for: activeTrip)
                )
                .scaleEffect(1.35)
                .offset(x: 46, y: 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func dayBadge(day: Int, totalDays: Int) -> some View {
        ZStack {
            Image("Cloud")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(pillTextColor)
            VStack(spacing: 0) {
                Text("day")
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x705A4D))
                    .textCase(.uppercase)
                Text("\(day) / \(totalDays)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x705A4D))
                    .monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Currency Button

    private var currencyButton: some View {
        Button {
            modalCoordinator.present(.shop)
        } label: {
            HStack(spacing: 4) {
                Image("Points")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .offset(x: -4, y: -4)
                Text("\(displaySprout.currency)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color(hex: 0xFFFFFF) : Color(hex: 0x6B4C2A))
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .frame(height: 36)
            .padding(.trailing, 13)
            .glassEffect(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open shop")
    }

    // MARK: - Sprout Stage

    private func sproutStage(layout: HomeDashboardLayout) -> some View {
        SproutView(
            state: sproutDisplayState,
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    // MARK: - Bottom Panel

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

    // MARK: - Helpers

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

    private func tripDuration(for trip: Trip) -> Int {
        let components = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate)
        return max(1, (components.day ?? 0) + 1)
    }

    private func displayedDayIndex(for trip: Trip) -> Int {
        min(dayIndex(for: trip), tripDuration(for: trip))
    }

    private func abbreviatedXP(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }
        let abbreviated = Double(value) / 1_000
        if value.isMultiple(of: 1_000) { return "\(Int(abbreviated))K" }
        return String(format: "%.1fK", abbreviated)
    }
}

// MARK: - Layout

struct HomeDashboardLayout {
    static let sproutAspectRatio: CGFloat = 507.0 / 800.0
    static let referenceCTAHeight: CGFloat = HomeCTAButton.referenceHeight
    static let ctaScale: CGFloat = HomeCTAButton.widthScale

    let topRowCenterY: CGFloat
    let tripGroupCenterX: CGFloat
    let tripGroupWidth: CGFloat
    let tripPillHeight: CGFloat
    let currencyPillCenterX: CGFloat
    let currencyPillHeight: CGFloat
    let sproutVerticalOffset: CGFloat
    let sproutViewportSize: CGSize
    let sproutWidth: CGFloat
    let sproutHeight: CGFloat
    let ctaWidth: CGFloat
    let ctaHeight: CGFloat

    // Propriétés pour topRow (version 1)
    let topRowTopInset: CGFloat
    let topRowHorizontalInset: CGFloat
    let topRowSpacing: CGFloat
    let topCardMinHeight: CGFloat
    let topCardHorizontalPadding: CGFloat
    let topCardVerticalPadding: CGFloat
    let topCardTextSpacing: CGFloat
    let tripCardMinWidth: CGFloat
    let tripCardMaxWidth: CGFloat
    let progressCardMinWidth: CGFloat
    let progressCardMaxWidth: CGFloat

    init(size: CGSize) {
        let referenceWidth: CGFloat = 402
        let referenceHeight: CGFloat = 874
        let scaleX = size.width / referenceWidth
        let scaleY = size.height / referenceHeight

        // Trip pill + currency
        topRowCenterY = 50 * scaleY
        tripGroupCenterX = (220 * scaleX / 2) + (8 * scaleX)
        tripGroupWidth = 250 * scaleX
        tripPillHeight = 60 * scaleY
        currencyPillCenterX = 338 * scaleX
        currencyPillHeight = 42 * scaleY

        // Sprout
        let sproutCenterY = 455 * scaleY
        sproutHeight = 400 * scaleY
        sproutWidth = sproutHeight * Self.sproutAspectRatio
        sproutVerticalOffset = (size.height / 2) - sproutCenterY
        sproutViewportSize = size

        // CTA
        let currentCTAWidth = max(0, size.width - (Spacing.screenEdge * 2))
        ctaWidth = currentCTAWidth * Self.ctaScale
        ctaHeight = Self.referenceCTAHeight * Self.ctaScale

        // Top row cards
        topRowTopInset = max(18, 26 * scaleY)
        topRowHorizontalInset = max(14, Spacing.screenEdge * scaleX)
        topRowSpacing = max(8, 10 * scaleX)
        topCardMinHeight = max(72, 80 * scaleY)
        topCardHorizontalPadding = max(12, 14 * scaleX)
        topCardVerticalPadding = max(10, 12 * scaleY)
        topCardTextSpacing = Spacing.xxs

        let availableWidth = max(0, size.width - (topRowHorizontalInset * 2) - topRowSpacing)
        tripCardMinWidth = min(max(120, 132 * scaleX), availableWidth)
        tripCardMaxWidth = availableWidth * 0.55
        progressCardMinWidth = min(max(132, 144 * scaleX), availableWidth)
        progressCardMaxWidth = availableWidth - tripCardMaxWidth
    }
}

// MARK: - Preview Data

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

// MARK: - Previews

#Preview("Home - Active Trip") {
    HomeTab(selection: .constant(.home))
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: true, fedToday: false))
        .frame(width: 402, height: 874)
}

#Preview("Home - Today's Reflection") {
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

#Preview("Home - Hungry") {
    HomeTab(selection: .constant(.home))
        .environment(ModalCoordinator())
        .environment(\.appEnvironment, .preview)
        .modelContainer(HomeTabPreviewData.makeContainer(activeTrip: true, fedToday: false))
        .frame(width: 402, height: 874)
}
