//
//  SignView.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 3/6/2026.
//

import SwiftUI

struct SignView: View {
    @EnvironmentObject var navVM: NavigationViewModel
    @State var Email = ""
    @State var Password = ""
    @State var Remember = false
    var body: some View {
        ZStack{
            BackgroundSky()
            
            ScrollView(.vertical, showsIndicators: false){
                if navVM.showSignUp {
                    SignUp(Email: $Email, Password: $Password, Remember: $Remember, showSignUp: $navVM.showSignUp, action:{})
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                } else {
                    SignIn(Email: $Email, Password: $Password, Remember: $Remember, showSignUp: $navVM.showSignUp, action:{})
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                }
            }
            
        }

    }
}

#Preview {
    SignView()
        .environmentObject(NavigationViewModel())
}
