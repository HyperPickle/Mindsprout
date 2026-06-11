import SwiftUI
import SwiftData
import MapKit

struct NewTripFlow: View {
    @Environment(\.modelContext) private var context
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
        case .business: return "briefcase.fill"
        }
    }
}

struct NewTripHeader: View {
    let title: LocalizedStringKey
    var onLeading: (() -> Void)?

    var body: some View {
        ZStack {
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(.white)
            HStack {
                if let onLeading {
                    Button(action: onLeading) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 52)
        .glassEffect(in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(.horizontal, Spacing.sm)
        .padding(.top, Spacing.xs + 20)
        .padding(.bottom, Spacing.xs)
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
                    .buttonStyle(.primary)
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
                .foregroundStyle(.white)
            DestinationPickerView(
                selectedCity: $viewModel.destination,
                onCoordinateSelected: { lat, lng in
                    viewModel.latitude = lat
                    viewModel.longitude = lng
                }
            )
        }
    }

    private var dates: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Select Travel Dates")
                    .font(AppFont.bodyEmphasized)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(viewModel.durationDays) days")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.ink)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 6)
                    .glassEffect(.regular.tint(.white), in: Capsule())
            }
            RangeCalendarView(startDate: $viewModel.startDate, endDate: $viewModel.endDate)
                .padding(Spacing.md)
                .glassEffect(.regular.tint(.white), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Type of Travel")
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(.white)
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
                            .foregroundStyle(.white)
                            .padding(.top, Spacing.xs)
                        ForEach(presets, id: \.self) { preset in
                            ExpectationRow(text: preset, isSelected: viewModel.selectedExpectations.contains(preset)) {
                                viewModel.toggle(preset)
                            }
                        }
                        TextField("Write your own…", text: $viewModel.customExpectation)
                            .font(AppFont.body)
                            .multilineTextAlignment(.center)
                            .padding(Spacing.md)
                            .background(RoundedRectangle(cornerRadius: CornerRadius.pill).fill(.white.opacity(0.7)))
                    }
                    .padding(Spacing.screenEdge)
                }
                Button("Save", action: onSave)
                    .buttonStyle(.primary)
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
        case .business: return "Business Trip"
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
                .font(AppFont.callout)
                .foregroundStyle(isSelected ? .white : AppColor.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .padding(.horizontal, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
                        .fill(isSelected ? AppColor.primary : .white)
                )
                .contentShape(RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum TripTypeOption: CaseIterable, Identifiable {
    case solo, family, friends, business
    var id: Self { self }

    var type: TripType {
        switch self {
        case .solo: return .solo
        case .family: return .family
        case .friends: return .friends
        case .business: return .business
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .solo: return "Solo"
        case .family: return "Family"
        case .friends: return "Friends"
        case .business: return "Business"
        }
    }

    var systemImage: String { type.systemImage }
}

struct TripTypeCell: View {
    let option: TripTypeOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: option.systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkSecondary)
                Text(option.title)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.ink)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(isSelected ? AppColor.primary : .clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
