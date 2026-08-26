import SwiftUI
import Combine

enum TabRoute: Hashable, Sendable {
    case home
    case services
    case more
}

enum TabBarAction: Sendable {
    case select(TabRoute)
}

@MainActor
final class TabBarCoordinator: Coordinator {
    
    typealias Action = TabBarAction
    
    @Published var sheet: (any Coordinator)?
    @Published var fullScreenSheet: (any Coordinator)?
    @Published private(set) var currentTab: TabRoute = .home
    
    var parent: (any Coordinator)?
    var childs: [any Coordinator] = []
    
    let homeCoordinator: HomeCoordinator
    let servicesCoordinator: ServicesCoordinator
    let moreCoordinator: HomeCoordinator
    
    private(set) lazy var navigationActing = SubjectActing<TabBarAction> { [weak self] action in
        self?.handle(action)
    }
    
    init() {
        homeCoordinator = HomeCoordinator()
        servicesCoordinator = ServicesCoordinator()
        moreCoordinator = HomeCoordinator()
        
        childs = [
            homeCoordinator,
            servicesCoordinator,
            moreCoordinator
        ]
    }
    
    func handle(_ action: TabBarAction) {
        switch action {
        case .select(let tab):
            currentTab = tab
        }
    }
    
    func eraseToAnyView() -> AnyView {
        AnyView(
            TabBarView(coordinator: self)
        )
    }
}

struct TabBarView: View {
    
    @ObservedObject var coordinator: TabBarCoordinator
    
    var body: some View {
        TabView(
            selection: Binding(
                get: { coordinator.currentTab },
                set: { coordinator.navigationActing.send(.select($0)) }
            )
        ) {
            tabView(
                coordinator: coordinator.homeCoordinator,
                title: "Home",
                image: "house",
                route: .home
            )
            tabView(
                coordinator: coordinator.servicesCoordinator,
                title: "Services",
                image: "square.grid.2x2",
                route: .services
            )
            tabView(
                coordinator: coordinator.moreCoordinator,
                title: "More",
                image: "ellipsis",
                route: .more
            )
        }
    }
    
    private func tabView<T: NavigationCoordinator>(
        coordinator: T,
        title: String,
        image: String,
        route: TabRoute
    ) -> some View {
        CoordinatorView(coordinator: coordinator)
            .tag(route)
            .tabItem {
                Label(title, systemImage: image)
            }
    }
}
