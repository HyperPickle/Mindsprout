//
//  HomeView.swift
//  MindSprout
//
//  Created by Changrila Souksamlane on 2/6/2026.
//

import SwiftUI
import SceneKit
import WebKit

struct GIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        if let url = Bundle.main.url(forResource: gifName,
                                      withExtension: "gif") {
            let data = try! Data(contentsOf: url)
            webView.load(data, mimeType: "image/gif",
                        characterEncodingName: "UTF-8",
                        baseURL: url)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct HomeView: View {
    @State private var animate = false
//    @State private var showOnBoarding = false
    @EnvironmentObject var navVM: NavigationViewModel
    var body: some View {
        
        
        ZStack {
            ZStack {
                BackgroundSky()
                
                Spacer()
                GIFView(gifName: "Earth2")
                    .frame(width: 800, height: 600)
                    .offset(x:-100, y: 400)
                
            }
            
            // 2. Your actual content layer
            VStack {
                Spacer()
                TitleView()
                    .frame(width: .infinity, alignment: .center)
                //Spacer()
                Spacer()
                
                //Button GET STARTED
                Button {
                    // Action
                    withAnimation{
                        navVM.showSignUp = true
                        navVM.showSignView = true
                    }
                } label: {
                    Text("GET STARTED")

                }
                .buttonStyle(DepthButtonStyle())
                .padding(.horizontal, 24)
                
                Spacer().frame(height:18) // space
                
                // BUTTON "I already have an account"
                Button {
                    // Action
                    //                    showOnBoarding = true
                    withAnimation{
                        navVM.showSignUp = false
                        navVM.showSignView = true
                    }
                } label: {
                    Text("I already have an account")
                        .foregroundColor(Color.white)
                        .font(
                            Font.custom("Nunito-Medium", size: 15)
                        )
                }
            }
        }
        .fullScreenCover(isPresented: $navVM.showSignView){
            SignView()
                .environmentObject(navVM)
        }
    }
}



struct TitleView: View {
    var body: some View {
        Image("Sprout_sit_home")
            .resizable()
            .scaledToFit()
            .aspectRatio(contentMode: .fit)
            .frame(width: 70, alignment: .center)

        Text("mindsprout")
        .font(.system(size: 40, weight: .bold, design: .rounded))
        .foregroundColor(.white)
        .frame(alignment: .center)
        

        Text("see the world, to see yourself").italic()
            .font(
                Font.custom("Nunito-MediumItalic", size: 15))
            .foregroundColor(.white)
            .frame(alignment: .center)
    }
    
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}


#Preview {
    HomeView()
        .environmentObject(NavigationViewModel())
}
