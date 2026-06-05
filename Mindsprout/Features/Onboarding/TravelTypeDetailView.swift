
import SwiftUI

struct TravelTypeDetailView: View {
    let type: OnboardingCoordinator.TravelType
    var onFinish: () -> Void
    @EnvironmentObject var coordinator: OnboardingCoordinator
    
    static let expectations: [OnboardingCoordinator.TravelType: [String]] = [
        .solo: [
            "Find my own rhythm",
            "Disconnect from daily life",
            "Challenge myself",
            "Meet new people",
            "Discover who I really am"
        ],
        .friends: [
            "Create unforgettable memories",
            "Laugh and let go",
            "Strengthen our bond",
            "Try new things together",
            "Have no plans and enjoy it"
        ],
        .family: [
            "Relax without the usual routine stress",
            "Spend real quality time together",
            "Document this stage of our lives",
            "Bring everyone closer together",
            "Create memories that everyone will remember"
        ],
        .business: [
            "Stay productive on the road",
            "Network and make connections",
            "Find balance between work and discovery",
            "Represent my best self",
            "Make this trip meaningful beyond work"
        ]
    ]
    
    @State private var selectedExpectations: Set<String> = []
    @State private var customExpectations: [String] = []
    @State private var showAddField = false
    @State private var newExpectation = ""
    @State private var editingExpectation: String? = nil
    @State private var editingText = ""
    
    var isFormComplete: Bool {
        !selectedExpectations.isEmpty
    }
    
    var title: String {
        switch type {
        case .solo: return "Solo Trip"
        case .friends: return "Friends Trip"
        case .family: return "Family Trip"
        case .business: return "Business Trip"
        }
    }
    
    var body: some View {
        ZStack {
            BackgroundSky()
            
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Spacer()
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text("What's your trip expectation?")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Predefined expectations
                        ForEach(Self.expectations[type] ?? [], id: \.self) { expectation in
                            ExpectationSuggestion(
                                text: expectation,
                                isSelected: selectedExpectations.contains(expectation)
                            ) {
                                withAnimation(.spring()) {
                                    if selectedExpectations.contains(expectation) {
                                        selectedExpectations.remove(expectation)
                                    } else {
                                        selectedExpectations.insert(expectation)
                                    }
                                }
                            }
                        }
                        
                        // Custom expectations with edit
                        ForEach(customExpectations, id: \.self) { expectation in
                            if editingExpectation == expectation {
                                HStack {
                                    TextField("Edit...", text: $editingText)
                                        .font(.system(size: 16, design: .rounded))
                                        .padding()
                                        .background(Color.white.opacity(0.9),
                                            in: .rect(cornerRadius: 99))
                                        .onSubmit {
                                            saveEdit(for: expectation)
                                        }
                                    Button {
                                        saveEdit(for: expectation)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(.white)
                                    }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    ExpectationSuggestion(
                                        text: expectation,
                                        isSelected: selectedExpectations.contains(expectation)
                                    ) {
                                        withAnimation(.spring()) {
                                            if selectedExpectations.contains(expectation) {
                                                selectedExpectations.remove(expectation)
                                            } else {
                                                selectedExpectations.insert(expectation)
                                            }
                                        }
                                    }
                                    Button {
                                        withAnimation(.spring()) {
                                            editingExpectation = expectation
                                            editingText = expectation
                                        }
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                }
                            }
                        }
                        
                        // Add field
                        if showAddField {
                            HStack(spacing: 16) {
                                Circle()
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                TextField("Add your own...", text: $newExpectation)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(Color(hex: 0x5C6A6E))
                                    .onSubmit {
                                        addCustomExpectation()
                                    }
                                
                                Spacer()
                                
                                if !newExpectation.isEmpty {
                                    Button {
                                        addCustomExpectation()
                                    } label: {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color(hex: 0x5C6A6E))
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.9), in: .rect(cornerRadius: 99))
                        }
                        
                        // + Button
                        Button {
                            withAnimation(.spring()) {
                                showAddField.toggle()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 44, height: 44)
                                Image(systemName: showAddField ? "xmark" : "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(Color(hex: 0x5C6A6E))
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                Button("Save") {
                    print("✅ Save tapped")
                       print("✅ selectedExpectations: \(selectedExpectations)")
                       coordinator.selectedExpectations = Array(selectedExpectations)
                       print("✅ calling onFinish")
                       onFinish()
                    
                }
                .buttonStyle(.primary)
                .padding(.horizontal, Spacing.screenEdge)
                .disabled(!isFormComplete)
                .opacity(!isFormComplete ? 0.5 : 1)
                .padding(.bottom, Spacing.lg)
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func addCustomExpectation() {
        guard !newExpectation.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring()) {
            customExpectations.append(newExpectation)
            selectedExpectations.insert(newExpectation)
            newExpectation = ""
            showAddField = false
        }
    }
    
    private func saveEdit(for original: String) {
        guard !editingText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring()) {
            if let index = customExpectations.firstIndex(of: original) {
                customExpectations[index] = editingText
                if selectedExpectations.contains(original) {
                    selectedExpectations.remove(original)
                    selectedExpectations.insert(editingText)
                }
            }
            editingExpectation = nil
            editingText = ""
        }
    }
}

// MARK: - ExpectationSuggestion
struct ExpectationSuggestion: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.black : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color(hex: 0x5C6A6E))
                            .frame(width: 14, height: 14)
                    }
                }
                
                Text(text)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: 0x5C6A6E))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.9), in: .rect(cornerRadius: 99))
        }
    }
}

#Preview {
    TravelTypeDetailView(type: .family, onFinish: {})
        .environmentObject(OnboardingCoordinator())
}
