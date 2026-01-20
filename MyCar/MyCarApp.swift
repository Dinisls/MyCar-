import SwiftUI
import GoogleMobileAds

@main
struct MyCarApp: App {
    
    init() {
        // CORREÇÃO:
        // 1. GADMobileAds passa a MobileAds
        // 2. sharedInstance() passa a .shared (sem parênteses)
        MobileAds.shared.start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}
