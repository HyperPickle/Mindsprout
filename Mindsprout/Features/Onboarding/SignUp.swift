//
//  SignUp.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//
import SwiftUI

struct SignUp: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var navVM: NavigationViewModel
    
    @FocusState var isActive
    @Binding var Email: String
    @Binding var Password: String
    @Binding var Remember: Bool
    @Binding var showSignUp: Bool

    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            Spacer()
            TopView(title: "Get your boarding pass", details: "Sign up to continue.")
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 30) {
                InfoTextField(title: "Email address", text: $Email)
                PasswordCheckField(text: $Password)

                SignButton(title: "Sign up", action: {
                    guard !Email.isEmpty, !Password.isEmpty else { return }
                    withAnimation {
                        isLoggedIn = true
                    }
                })
                
                OrView(title: "or")
                
                HStack(spacing: 90) {
                    signAccount(image: .apple, width: 40, height: 40, action: {})
                    signAccount(image: .google, width: 32, height: 32, action: {})
                    signAccount(image: .facebook, width: 32, height: 32, action: {})
                }
                
                Spacer()
                
                Button {
                    Email = ""
                    Password = ""
                    withAnimation {
                        showSignUp.toggle()
                    }
                } label: {
                    Text("Already have an account? Sign in")
                        .font(Font.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(textColor)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(50)
    }
}

#Preview {
    SignView()
        .environmentObject(NavigationViewModel())
}
