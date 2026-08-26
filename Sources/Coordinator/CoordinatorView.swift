import SwiftUI
import Combine

struct CoordinatorView<T: NavigationCoordinator>: View {
    
    @ObservedObject var coordinator: T
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            coordinator.root
                .build(navigationActing: coordinator.navigationActing)
                .navigationDestination(for: T.Route.self) { route in
                    route.build(navigationActing: coordinator.navigationActing)
                }
        }
        .sheet(item: sheetItem) { item in
            item.view
        }
        .fullScreenCover(item: fullScreenItem) { item in
            item.view
        }
    }
    
    private var sheetItem: Binding<IdentifiableCoordinator?> {
        Binding(
            get: { [coordinator] in
                guard let coordinator = coordinator.sheet else {
                    return nil
                }
                return IdentifiableCoordinator(coordinator)
            },
            set: { [coordinator] in
                if $0 == nil {
                    coordinator.sheet = nil
                }
            }
        )
    }
    
    private var fullScreenItem: Binding<IdentifiableCoordinator?> {
        Binding(
            get: { [coordinator] in
                guard let coordinator = coordinator.fullScreenSheet else {
                    return nil
                }
                return IdentifiableCoordinator(coordinator)
            },
            set: { [coordinator] in
                if $0 == nil {
                    coordinator.fullScreenSheet = nil
                }
            }
        )
    }
}

private struct IdentifiableCoordinator: Identifiable {
    let id: ObjectIdentifier
    let view: AnyView
    
    init(_ coordinator: any Coordinator) {
        id = ObjectIdentifier(coordinator as AnyObject)
        view = coordinator.eraseToAnyView()
    }
}
