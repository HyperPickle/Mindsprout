import SwiftUI
import SwiftData
import MapKit

struct EditTripFlow: View {
    let tripID: UUID

    @Environment(\.modelContext) private var context
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: EditTripViewModel
    @State private var showActiveConfirm = false
    @State private var showDeleteConfirm = false

    init(tripID: UUID) {
        self.tripID = tripID
        _viewModel = State(initialValue: EditTripViewModel(tripID: tripID))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundSky()
                LinearGradient(colors: [.black.opacity(0.1), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            destinationField
                            dates
                            typePicker
                            expectations
                            featuredReflection
                            activeToggle
                            deleteSection
                        }
                        .padding(Spacing.screenEdge)
                        .padding(.bottom, Spacing.lg)
                    }
                    HStack {
                        Spacer()
                        Button("Save Changes") {
                            viewModel.save(context: context)
                            dismiss()
                        }
                        .buttonStyle(.primary)
                        .disabled(!viewModel.canSave)
                        Spacer()
                    }
                    .padding(.horizontal, Spacing.screenEdge)
                    .padding(.bottom, Spacing.xs)
                    .offset(y: -10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationCornerRadius(36)
        .presentationDragIndicator(.visible)
        .task { viewModel.load(context: context, pack: try? env.contentPackLoader.load()) }
        .confirmationDialog(
            "Switch active trip?",
            isPresented: $showActiveConfirm,
            titleVisibility: .visible
        ) {
            Button("Make this the active trip") { viewModel.makeActive = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(viewModel.activeOtherTripName ?? "Another trip") is currently active. Only one trip can be active at a time.")
        }
        .confirmationDialog(
            "Delete this trip?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Trip", role: .destructive) {
                viewModel.delete(context: context)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the trip and all of its reflections. This can't be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Edit Trip")
                .font(AppFont.headline)
                .foregroundStyle(.white)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
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

    // MARK: - Sections

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            sectionLabel("Where did you go?")
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
                sectionLabel("Travel Dates")
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
            sectionLabel("Type of Travel")
            HStack(spacing: Spacing.sm) {
                ForEach(TripTypeOption.allCases) { option in
                    TripTypeCell(option: option, isSelected: viewModel.type == option.type) {
                        viewModel.type = option.type
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var expectations: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Trip Expectations")
            ForEach(viewModel.presetOptions(), id: \.self) { preset in
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
    }

    @ViewBuilder private var featuredReflection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Featured Reflection")
            if viewModel.reflections.isEmpty {
                Text("Reflections you log will appear here to feature one on the trip.")
                    .font(AppFont.callout)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular.tint(.white.opacity(0.15)), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            } else {
                ForEach(viewModel.reflections) { reflection in
                    FeaturedReflectionRow(
                        reflection: reflection,
                        isSelected: viewModel.featuredReflectionID == reflection.id
                    ) {
                        viewModel.toggleFeatured(reflection.id)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular.tint(.white.opacity(0.15)), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var activeToggle: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Trip Status")
            HStack(alignment: .center, spacing: Spacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set as active trip")
                        .font(AppFont.bodyEmphasized)
                        .foregroundStyle(AppColor.ink)
                    Text("Your reflections feed into the active trip.")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.inkSecondary)
                }
                Spacer()
                Toggle("Set as active trip", isOn: activeBinding)
                    .labelsHidden()
                    .tint(AppColor.primary)
            }
            .padding(Spacing.md)
            .glassEffect(.regular.tint(.white), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
    }

    private var deleteSection: some View {
        VStack(spacing: Spacing.sm) {
            SectionDivider(title: "DANGER ZONE", color: .white.opacity(0.7))
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "trash")
                    Text("Delete Trip")
                }
                .font(AppFont.bodyEmphasized)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                        .fill(Color.red.opacity(0.85))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Spacing.xs)
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppFont.bodyEmphasized)
            .foregroundStyle(.white)
    }

    private var activeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.makeActive },
            set: { newValue in
                if newValue && viewModel.needsActiveConfirmation {
                    showActiveConfirm = true
                } else {
                    viewModel.makeActive = newValue
                }
            }
        )
    }
}

private struct FeaturedReflectionRow: View {
    let reflection: Reflection
    let isSelected: Bool
    let action: () -> Void

    private var snippet: String {
        let text = reflection.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text.isEmpty ? "Photo & audio memory" : text
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Day \(reflection.dayIndex)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColor.primary)
                    Text(snippet)
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: Spacing.sm)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkMuted)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
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
