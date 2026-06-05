//
//  ForgotPasswordView.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//

import SwiftUI

struct ForgotPasswordView: View{
    @Environment(\.colorScheme) var colorScheme
    
    var textColor: Color{
        colorScheme == .dark ? Color.white: Color.black
    }
    
    var backColor: Color {
        colorScheme == .dark ? Color.white: Color.black
    }
    
    var buttonTextColor: Color{
        colorScheme == .dark ? Color.black: Color.white
    }
    
    @State var email = ""
    var body: some View {
        VStack (spacing: 28){
            Spacer()
            VStack(spacing:8){
                Text("Forgot your password?").font(.title.bold())
                    .foregroundStyle(textColor)
                    .font(Font.system(size: 24, weight: .bold, design: .rounded))
                Text("Enter your email address and we will share a link to create a new password").fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(textColor)
                    .font(Font.system(size: 15, weight: .medium, design: .rounded))
            }
            .multilineTextAlignment(.center)
            TextField("Email", text: $email)
                .foregroundStyle(Color(hex:0x705B4D)) // color typography in the text field
                .padding(.leading, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(.gray.opacity(0.4), in: .rect(cornerRadius: 16))

            SignButton(title: "Send", color: backColor, text: buttonTextColor, action: {
                //ACTION
            })
            Spacer()
        }
        .padding()
    }

}
#Preview{
    ForgotPasswordView()
}
