import SwiftUI

@main
struct CoordinatorSampleApp: App {
    
    @StateObject private var coordinator = TabBarCoordinator()
    
    var body: some Scene {
        WindowGroup {
            TabBarView(coordinator: coordinator)
        }
    }
}
