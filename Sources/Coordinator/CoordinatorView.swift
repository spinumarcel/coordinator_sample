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
        .alert(
            coordinator.alert?.title ?? "",
            isPresented: isAlertPresented,
            presenting: coordinator.alert,
            actions: {
                alertAction(content: $0)
            },
            message: {
                if let message = $0.message {
                    Text(message)
                }
            }
        )
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
    
    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { [coordinator] in
                coordinator.alert != nil
            },
            set: { [coordinator] in
                if $0 == false {
                    coordinator.alert = nil
                }
            }
        )
    }
    
    @ViewBuilder
    private func alertAction(content: AlertContent) -> some View {
        ForEach(content.actions.indices, id: \.self) { index in
            let action = content.actions[index]
            Button(action.title, role: action.role) {
                action.handler?()
                coordinator.alert = nil
            }
        }
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
