import SwiftUI
import SwiftData
import MapKit

struct NewTripFlow: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewTripViewModel()
    @State private var showExpectations = false
    
    var body: some View {
        NavigationStack {
            NewTripBasicsView(viewModel: viewModel) { showExpectations = true }
                .navigationDestination(isPresented: $showExpectations) {
                    NewTripExpectationsView(viewModel: viewModel) {
                        viewModel.save(context: context)
                        dismiss()
                    }
                }
        }
        .presentationCornerRadius(36)
        .presentationDragIndicator(.visible)
    }
}

extension TripType {
    var systemImage: String {
        switch self {
        case .solo: return "person.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .friends: return "person.2.fill"
        case .work: return "briefcase.fill"
        }
    }
}

struct NewTripHeader: View {
    let title: LocalizedStringKey
    var onLeading: (() -> Void)?

    var body: some View {
        ZStack {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
            HStack {
                if let onLeading {
                    Button(action: onLeading) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColor.label)
                            .frame(width: 36, height: 36)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 52)
        .readableLiquidGlass(in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.xs + 20)
        .padding(.bottom, Spacing.xs)
        .transaction { $0.animation = nil }
    }
}

private struct NewTripBasicsView: View {
    @Bindable var viewModel: NewTripViewModel
    @Environment(\.dismiss) private var dismiss
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            BackgroundSky()
            LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                NewTripHeader(title: "New Trip", onLeading: { dismiss() })
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        field
                        dates
                        typePicker
                    }
                    .padding(Spacing.screenEdge)
                }
                Button("Continue", action: onContinue)
                    .buttonStyle(.tripGlassCTA)
                    .disabled(!viewModel.canContinue)
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, Spacing.xs)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var field: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Where are we going?")
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(AppColor.label)
            DestinationPickerView(
                selectedCity: $viewModel.destination,
                onCoordinateSelected: { lat, lng in
                    viewModel.latitude = lat
                    viewModel.longitude = lng
                }
            )
        }
        .zIndex(999)
    }
    

    private var dates: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Select Travel Dates")
                    .font(AppFont.bodyEmphasized)
                    .foregroundStyle(AppColor.label)
                Spacer()
                Text("\(viewModel.durationDays) days")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.label)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .tripGlassSurface(style: .neutral, in: Capsule())
            }
            RangeCalendarView(startDate: $viewModel.startDate, endDate: $viewModel.endDate)
                .padding(Spacing.md)
                .readableLiquidGlass(
                    in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                )
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Type of Travel")
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(AppColor.label)
            HStack(spacing: Spacing.sm) {
                ForEach(TripTypeOption.allCases) { option in
                    TripTypeCell(option: option, isSelected: viewModel.type == option.type) {
                        viewModel.type = option.type
                    }
                }
            }
        }
    }
}

struct NewTripExpectationsView: View {
    @Bindable var viewModel: NewTripViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnvironment) private var env
    let onSave: () -> Void

    @State private var presets: [String] = []

    var body: some View {
        ZStack {
            BackgroundSky()
            LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                NewTripHeader(
                    title: titleKey,
                    onLeading: { dismiss() }
                )
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("What's your trip expectation?")
                            .font(AppFont.bodyEmphasized)
                            .foregroundStyle(AppColor.label)
                            .padding(.top, Spacing.xs)
                        ForEach(presets, id: \.self) { preset in
                            ExpectationRow(text: preset, isSelected: viewModel.selectedExpectations.contains(preset)) {
                                viewModel.toggle(preset)
                            }
                        }
                        TextField(
                            text: $viewModel.customExpectation,
                            prompt: Text("Write your own…").foregroundStyle(AppColor.placeholder)
                        ) {}
                            .font(AppFont.body)
                            .multilineTextAlignment(.center)
                            .padding(Spacing.md)
                            .foregroundStyle(AppColor.label)
                            .tint(AppColor.label)
                            .tripGlassSurface(
                                style: .neutral,
                                in: RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                            )
                    }
                    .padding(Spacing.screenEdge)
                }
                Button("Save", action: onSave)
                    .buttonStyle(.tripGlassCTA)
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, Spacing.xs)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if let pack = try? env.contentPackLoader.load() {
                presets = viewModel.presets(from: pack)
            }
        }
    }

    private var titleKey: LocalizedStringKey {
        switch viewModel.type {
        case .solo: return "Solo Trip"
        case .friends: return "Friends Trip"
        case .family: return "Family Trip"
        case .work: return "Work Trip"
        case .none: return "New Trip"
        }
    }
}

struct ExpectationRow: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(AppFont.button)
                .foregroundStyle(AppColor.label)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.md)
                .tripGlassSurface(
                    style: isSelected ? .selected : .neutral,
                    in: RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum TripTypeOption: CaseIterable, Identifiable {
    case solo, family, friends, work
    var id: Self { self }

    var type: TripType {
        switch self {
        case .solo: return .solo
        case .family: return .family
        case .friends: return .friends
        case .work: return .work
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .solo: return "Solo"
        case .family: return "Family"
        case .friends: return "Friends"
        case .work: return "Work"
        }
    }

    var systemImage: String { type.systemImage }
}

struct TripTypeCell: View {
    let option: TripTypeOption
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: option.systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(AppColor.label)
                Text(option.title)
                    .font(AppFont.bodyEmphasized)
                    .foregroundStyle(AppColor.label)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, 2)
            .background {
                Color.clear
                    .tripGlassSurface(
                        style: .neutral,
                        in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .strokeBorder(isSelected ? (colorScheme == .dark ? Color.white.opacity(0.72) : AppColor.graphite) : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(.plain)
    }
}

#Preview("New Trip - Basics") {
    NewTripFlow()
        .environment(\.appEnvironment, .preview)
        .modelContainer(PersistenceController.makeInMemoryContainer())
}

#Preview("New Trip - Expectations") {
    NavigationStack {
        NewTripExpectationsView(
            viewModel: NewTripViewModel(),
            onSave: {}
        )
        .environment(\.appEnvironment, .preview)
    }
}

#Preview("Trip Type Cell") {
    HStack(spacing: 12) {
        TripTypeCell(option: .solo, isSelected: true, action: {})
        TripTypeCell(option: .friends, isSelected: false, action: {})
        TripTypeCell(option: .family, isSelected: false, action: {})
        TripTypeCell(option: .work, isSelected: false, action: {})
    }
    .padding()
    .background(Color.blue)
}

#Preview("Expectation Row") {
    VStack(spacing: 8) {
        ExpectationRow(text: "Discover new cultures", isSelected: true, action: {})
        ExpectationRow(text: "Rest and recharge", isSelected: false, action: {})
        ExpectationRow(text: "Meet new people", isSelected: false, action: {})
    }
    .padding()
    .background(Color.blue)
}
