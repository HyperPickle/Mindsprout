import Foundation
import SwiftUI
import SwiftData
import UIKit

struct HomeTab: View {
    private let fabBarHorizontalInset: CGFloat = 21
    private let floatingTabReservedHeight: CGFloat = 75

    @Binding var selection: AppTab

    @Environment(\.modelContext) private var context
    @Environment(ModalCoordinator.self) private var modalCoordinator
    @Environment(\.appEnvironment) private var env

    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]
    @Query(sort: \Sprout.createdAt) private var sprouts: [Sprout]

    @State private var bubbleOffset: CGFloat = 0
    @State private var showWardrobe = false

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
                    .padding(.horizontal, fabBarHorizontalInset)
                    .padding(.bottom, floatingTabReservedHeight)
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
        .fullScreenCover(isPresented: $showWardrobe) {
            WardrobeView(isPresented: $showWardrobe)
                .environment(modalCoordinator)
        }
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

                // Top row: trip pill + day badge
                tripPill(maxWidth: layout.tripGroupMaxWidth)
                    .frame(width: layout.tripGroupMaxWidth, height: layout.tripPillHeight, alignment: .leading)
                    .position(x: layout.tripGroupCenterX, y: layout.topRowCenterY)

                // Style button - top right, top-aligned with trip card
                VStack {
                    HStack {
                        Spacer()
                        styleButton
                            .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .padding(.top, max(0, layout.topRowCenterY - 32))

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

    private func tripPill(maxWidth: CGFloat) -> some View {
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let horizontalPadding: CGFloat = 20
        let cloudReservedWidth: CGFloat = activeTrip == nil ? horizontalPadding : 96
        let cardWidth = tripPillWidth(maxWidth: maxWidth)
        let textMaxWidth = max(72, cardWidth - horizontalPadding - cloudReservedWidth)

        return ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                Text(activeTrip?.destination ?? "No trip yet")
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.label)
                    .lineLimit(2)
                    .truncationMode(.tail)
                Text(activeTrip?.country ?? "Start an adventure")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: textMaxWidth, alignment: .leading)
            .padding(.leading, horizontalPadding)
            .padding(.trailing, cloudReservedWidth)
            .padding(.vertical, 14)
            .frame(width: cardWidth, alignment: .leading)
            .background {
                Color.clear
                    .readableLiquidGlass(in: cardShape)
            }

            if let activeTrip {
                dayBadge(
                    day: displayedDayIndex(for: activeTrip),
                    totalDays: tripDuration(for: activeTrip)
                )
                .offset(x: 28, y: 22)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tripPillWidth(maxWidth: CGFloat) -> CGFloat {
        let destination = activeTrip?.destination ?? "No trip yet"
        let country = activeTrip?.country ?? "Start an adventure"
        let reservedChrome: CGFloat = activeTrip == nil ? 40 : 104
        let estimatedDestinationWidth = CGFloat(destination.count) * 13
        let estimatedCountryWidth = CGFloat(country.count) * 7.5
        let contentWidth = max(estimatedDestinationWidth, estimatedCountryWidth) + reservedChrome
        let minWidth: CGFloat = activeTrip == nil ? 220 : 204

        return min(maxWidth, max(minWidth, contentWidth))
    }

    private func dayBadge(day: Int, totalDays: Int) -> some View {
        ZStack {
            Image("Cloud")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: 96, height: 70)
                .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            VStack(spacing: 0) {
                Text("day")
                    .font(AppFont.eyebrow)
                    .foregroundStyle(AppColor.graphite.opacity(0.72))
                    .textCase(.uppercase)
                Text("\(day) / \(totalDays)")
                    .font(AppFont.metric)
                    .foregroundStyle(AppColor.graphite)
            }
            .offset(y: 3)
        }
        .accessibilityLabel("Day \(day) of \(totalDays)")
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
        ctaButton
    }

    private var styleButton: some View {
        Button {
            showWardrobe = true
        } label: {
            HStack(spacing: 2) {
                Image("Style icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 43, height: 43)
                    .offset(x: -4, y: -4)
                Text("Style")
                    .font(AppFont.callout)
            }
            .foregroundStyle(AppColor.label)
            .frame(height: 41)
            .padding(.trailing, 15)
            .glassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
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

    private func tripDuration(for trip: Trip) -> Int {
        let components = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate)
        return max(1, (components.day ?? 0) + 1)
    }

    private func displayedDayIndex(for trip: Trip) -> Int {
        min(dayIndex(for: trip), tripDuration(for: trip))
    }
}

// MARK: - Layout

struct HomeDashboardLayout {
    static let sproutAspectRatio: CGFloat = 507.0 / 800.0
    static let referenceCTAHeight: CGFloat = HomeCTAButton.referenceHeight
    static let ctaScale: CGFloat = HomeCTAButton.widthScale

    let topRowCenterY: CGFloat
    let tripGroupCenterX: CGFloat
    let tripGroupMaxWidth: CGFloat
    let tripPillHeight: CGFloat
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

    init(size: CGSize) {
        let referenceWidth: CGFloat = 402
        let referenceHeight: CGFloat = 874
        let scaleX = size.width / referenceWidth
        let scaleY = size.height / referenceHeight

        // Trip pill
        topRowCenterY = 50 * scaleY
        let tripGroupLeadingX = 8 * scaleX
        let screenSafeTripWidth = max(180, size.width - tripGroupLeadingX - 54)
        tripGroupMaxWidth = min(max(236, 340 * scaleX), screenSafeTripWidth)
        tripGroupCenterX = tripGroupLeadingX + (tripGroupMaxWidth / 2)
        tripPillHeight = 104 * scaleY

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
