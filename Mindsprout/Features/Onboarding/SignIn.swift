//
//  SignIn.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//

import SwiftUI

struct SignIn: View {
    @State private var animate = false
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState var isActive
    @Binding var Email: String
    @Binding var Password: String
    @Binding var Remember: Bool // we can remove it it's for remember the id
    @Binding var showSignUp: Bool
    @State var showForgotView = false
    
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
        
    var textColor: Color {
        colorScheme == .dark ? Color.white: Color.black
    }
    

    
    var action: () -> Void

    var body: some View {
    
        VStack (alignment: .center, spacing: 30){
            Spacer()
            TopView(title: "Welcome back, traveler", details: "Continue your journey. Sign in.")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            VStack(spacing:30){
                InfoTextField(title: "Email address", text: $Email)
                PasswordTextField(title: "Password", text: $Password)
                HStack{
                    Spacer()
                    Button(action:{
                        showForgotView.toggle()
                    }, label: {
                        Text("Forgot your password?")
                            .foregroundStyle(Color.white)
                            .font(Font.system(size: 15, weight: .medium, design: .rounded))
                            .underline()
                            
                    })
                    
                }


                SignButton(title: "Sign in", action: {
                    guard !Email.isEmpty, !Password.isEmpty else { return }
                    withAnimation {
                        isLoggedIn = true
                        hasCompletedOnboarding = true
                    }
                })
                OrView(title:"or")
                
                HStack (spacing: 90){
                    signAccount(image: .apple, width: 40, height: 40, action: {
                        // action
                    })
                    signAccount(image: .google, width: 32, height: 32, action: {
                        //action
                    })
                    signAccount(image: .facebook, width: 32, height: 32, action: {
                        //action
                    })
                }
                Spacer()
                Button {
                    Email = ""
                    Password = ""
                    withAnimation{
                        showSignUp.toggle()
                    }
                } label : {
                    Text("Don't have an account? Sign up")
                        .font(Font.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(textColor)
                }

            }
            
        }
        .padding(.horizontal, 24)
        .padding(50)
        .sheet(isPresented: $showForgotView, content: {
            ForgotPasswordView()
                .presentationDetents([.fraction(0.40)])
        })
         
    }
    
}

struct TopView: View{
    var title: String
    var details: String
    var body: some View {
        VStack (alignment: .leading) {
            Text(title).font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.white)
                .padding(.vertical)
            Text(details).font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white)
            
        }
        
    }
}

struct InfoTextField: View{
    var title:String
    @Binding var text: String
    @FocusState var isActive
    var body: some View {
        ZStack (alignment: .leading){
            TextField("", text: $text)
                .foregroundStyle(Color(hex: 0x705B4D)) // color typography in the text field
                .padding(.leading, 10)
                .frame(width: 350)
                .frame(height: 55).focused($isActive)
                .background(Color.white, in: .rect(cornerRadius: 20))
            Text(title).padding(.leading)
                .font(.system(size:15, design: .rounded))
                .foregroundStyle(Color(hex: 0x705B4D))
                .opacity(text.isEmpty ? 1 : 0)
        }
    }
}

struct PasswordTextField: View{
    var title:String
    @Binding var text: String
    @FocusState var isActive
    @State var showPassword = false
    var body: some View {
        ZStack (alignment: .leading){
            SecureField("", text: $text)
                .foregroundStyle(Color(hex:0x705B4D)) // color typography in the text field
                .padding(.leading, 10)
                .frame(width: 350)
                .frame(height: 55).focused($isActive)
                .background(Color.white, in: .rect(cornerRadius: 20))
                .opacity(showPassword ? 0 : 1)
            
            TextField("", text: $text)
                .foregroundStyle(Color(hex: 0x705B4D)) // color typography in the text field
                .padding(.leading, 10)
                .frame(width: 350)
                .frame(height: 55).focused($isActive)
                .background(Color.white, in: .rect(cornerRadius: 20))
                .opacity(showPassword ? 1 : 0)
            
            Text(title).padding(.leading)
                .font(.system(size:15, design: .rounded))
                .foregroundStyle(Color(hex: 0x705B4D))
                .opacity(text.isEmpty ? 1 : 0)
            
        }
            .overlay(alignment: .trailing){
                Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(16)
                    .contentShape(Rectangle())
                    .foregroundStyle(showPassword ? Color(hex: 0x705B4D) : Color(hex:0x705B4D))
                    .onTapGesture {
                        showPassword.toggle()
                    }
            }
    }
}

struct ForgotButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(Color.white)
            .frame(width: 320, height: 30)
            .padding(.vertical, 10)
    }
}

struct SignButton: View {
    var title: String
    var color: Color = Color.black
    var text: Color = Color.white
    var action:() -> Void
    var body: some View {
        Button(action: {action()}, label:{
            Text(title).font(Font.system(size: 20, weight: .medium, design: .rounded)).foregroundColor(text)
                .frame(width: 350, height: 30)
                .padding(.vertical, 10)
                .background(color, in: .rect(cornerRadius: 16))
            
        })
            
    }
}

struct OrView: View {
    var title: String
    var body: some View {
        HStack (alignment: .center){
            Rectangle()
                .frame (width: 150, height: 1.5)
                .foregroundStyle(Color.white)
            Text(title)
                .font(Font.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
            Rectangle()
                .frame (width: 150, height: 1.5)
                .foregroundStyle(Color.white)
        }
    }
}

struct signAccount: View{
    @Environment(\.colorScheme) var colorScheme
    var image: ImageResource
    var width:CGFloat
    var height:CGFloat
    var action: () -> Void
    
    var iconColor: Color {
        colorScheme == .dark ? Color(hex: 0x451D76): Color(hex:0x00C0FD)
    }
    
    var shadowColor: Color{
        colorScheme == .dark ? Color(hex:0x411D63): Color(hex: 0x019BC2)
    }
    
    var body: some View {
        //OPTION 1
//        Button(action: {}, label: {
//            ZStack{
//                RoundedRectangle(cornerRadius:12).stroke(lineWidth: 2)
//                    .foregroundStyle(Color.white)
//                    .frame(width:97, height: 73, alignment: .center)
//                Image(image).renderingMode(.template)
//                    .resizable().scaledToFill()
//                    .frame (width: width, height: height)
//                    .foregroundStyle(iconColor)
//                
//            }
//        })
        
        //OPTION 2
        Button (action: action) {
            Image(image).renderingMode(.template)
                .resizable().scaledToFill()
                .frame (width: width, height: height)
                .foregroundStyle(iconColor)
        }
        .buttonStyle(signOtherAccountButton()
            )
    }
}




#Preview {
    SignView()
        .environmentObject(NavigationViewModel())
}
