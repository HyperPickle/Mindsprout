import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    
    @State private var selectedCity: String = ""
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var selectedType: OnboardingCoordinator.TravelType?
    @StateObject private var coordinator = OnboardingCoordinator()
    @State private var showCalendar = false
    @State private var currentMonth = Date()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                BackgroundSky()
                
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Spacer()
                    Text("Add new trip")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading) {
                        Text("Where are we going?")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                        DestinationPickerView(selectedCity: $selectedCity)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Select Travel Dates")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                        DateRangePickerView(
                            showCalendar: $showCalendar,
                            startDate: $startDate,
                            endDate: $endDate
                        )
                    }
                    .zIndex(showCalendar ? 999 : 0)
                    .overlay(alignment: .top) {
                        if showCalendar {
                            CalendarView(
                                currentMonth: $currentMonth,
                                startDate: $startDate,
                                endDate: $endDate
                            )
                            .background(Color.white, in: .rect(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                            .offset(y: 60)
                            .zIndex(999)
                        }
                    }
                    .onChange(of: endDate) { _, newValue in
                        if newValue != nil {
                            withAnimation(.spring()) {
                                showCalendar = false
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Type of Travel")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                        HStack(alignment: .center, spacing: 20) {
                            ForEach(OnboardingCoordinator.TravelType.allCases, id: \.self) { type in
                                TravelTypeButton(
                                    type: type,
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                    coordinator.selectedTravelType = type
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button("Continue") {
                        coordinator.goToDetail()
                    }
                    .buttonStyle(.primary)
                    .padding(.horizontal, Spacing.screenEdge)
                    .disabled(!isFormComplete)
                    .opacity(!isFormComplete ? 0.5 : 1)
                }
                .padding()
            }
            .navigationDestination(for: OnboardingCoordinator.Route.self) { route in
                switch route {
                case .travelTypeDetail(let type):
                    TravelTypeDetailView(type: type, onFinish: onFinish)
                        .environmentObject(coordinator)
                }
            }
        }
        .environmentObject(coordinator)
    }
    
    private var isFormComplete: Bool {
        !selectedCity.isEmpty &&
        startDate != nil &&
        endDate != nil &&
        selectedType != nil
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
