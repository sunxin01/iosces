import SwiftUI

@main
struct ShiGuangApp: App {
    @StateObject private var store = MomentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
