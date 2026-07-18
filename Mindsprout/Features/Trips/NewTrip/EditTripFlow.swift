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
                        .contentColumn()
                    }
                    HStack {
                        Spacer()
                        Button("Save Changes") {
                            viewModel.save(context: context)
                            dismiss()
                        }
                        .buttonStyle(.tripGlassCTA)
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
        .presentationSizing(.page)
        .task {
            // Loading swaps placeholder state (empty reflections, default dates)
            // for the trip's real data, which changes the form's content height.
            // Suppress animation so the fields settle in place instead of
            // bouncing in on whatever transaction is ambient at present time.
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                viewModel.load(context: context, pack: try? env.contentPackLoader.load())
            }
        }
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
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.label)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColor.label)
                        .frame(width: 36, height: 36)
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
        .contentColumn()
        .transaction { $0.animation = nil }
    }

    // MARK: - Sections

    private var destinationField: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Where did you go?")
            DestinationPickerView(selection: $viewModel.locationSelection)
        }
        .zIndex(999)
    }

    private var dates: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                sectionLabel("Travel Dates")
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
    }

    @ViewBuilder private var featuredReflection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Featured Reflection")
            if viewModel.reflections.isEmpty {
                Text("Reflections you log will appear here to feature one on the trip.")
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.label.opacity(0.85))
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tripGlassSurface(
                        style: .neutral,
                        in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    )
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
        .tripGlassSurface(
            style: .neutral,
            in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
        )
    }

    private var activeToggle: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            sectionLabel("Trip Status")
            Button {
                activeBinding.wrappedValue.toggle()
            } label: {
                HStack(alignment: .center, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set as active trip")
                            .font(AppFont.bodyEmphasized)
                            .foregroundStyle(AppColor.label)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Your reflections feed into the active trip.")
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        if viewModel.makeActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(viewModel.makeActive ? "Active" : "Inactive")
                            .font(AppFont.caption)
                    }
                    .foregroundStyle(AppColor.label)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .tripGlassSurface(
                    style: viewModel.makeActive ? .selected : .neutral,
                    in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.label)
                    .frame(width: 28, height: 28)
                Text("Delete Trip")
                    .font(AppFont.bodyEmphasized)
                    .foregroundStyle(AppColor.label)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColor.secondaryLabel)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tripGlassSurface(
                style: .danger,
                in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AppFont.bodyEmphasized)
            .foregroundStyle(AppColor.label)
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
                    Text(snippet)
                        .font(AppFont.bodyEmphasized)
                        .foregroundStyle(AppColor.label)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Day \(reflection.dayIndex)")
                        .font(AppFont.callout)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                Spacer(minLength: Spacing.sm)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColor.label)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tripGlassSurface(
                style: isSelected ? .selected : .neutral,
                in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview{
    let container = PersistenceController.makeInMemoryContainer()
    let context = ModelContext(container)
      
    let trip = Trip(
          destination: "Kyoto",
          country: "Japan",
          startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
          endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
      )
      context.insert(trip)
      try? context.save()
      
      return EditTripFlow(tripID: trip.id)
          .environment(\.appEnvironment, .preview)
          .modelContainer(container)
    
}
