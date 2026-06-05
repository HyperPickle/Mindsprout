
import SwiftUI
import WebKit

struct GIFView: UIViewRepresentable {
    let gifName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        if let url = Bundle.main.url(forResource: gifName, withExtension: "gif"),
           let data = try? Data(contentsOf: url) {
            webView.load(data, mimeType: "image/gif",
                        characterEncodingName: "UTF-8",
                        baseURL: url)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct WelcomeView: View {
    @EnvironmentObject var navVM: NavigationViewModel
    
    var body: some View {
        ZStack {
            ZStack {
                BackgroundSky()
                GIFView(gifName: "Earth2")
                    .frame(width: 800, height: 600)
                    .offset(x: -100, y: 400)
            }
            
            VStack {
                Spacer()
                TitleView()
                Spacer()
                
                Button {
                    withAnimation {
                        navVM.showSignUp = true
                        navVM.showSignView = true
                    }
                } label: {
                    Text("GET STARTED")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .buttonStyle(DepthButtonStyle())
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 18)
                
                Button {
                    withAnimation {
                        navVM.showSignUp = false
                        navVM.showSignView = true
                    }
                } label: {
                    Text("I already have an account")
                        .foregroundColor(Color.white)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                
                Spacer().frame(height: 40)
            }
        }
    }
}

struct TitleView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("Sprout_sit_home")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
            
            Text("mindsprout")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("see the world, to see yourself").italic()
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(NavigationViewModel())
}
