import SwiftUI
import Combine

@MainActor
protocol Coordinator: ObservableObject {

    associatedtype Action: Sendable
    
    var sheet: (any Coordinator)? { get set }
    var fullScreenSheet: (any Coordinator)? { get set }
    
    var parent: (any Coordinator)? { get set }
    var childs: [any Coordinator] { get set }
    
    var navigationActing: SubjectActing<Action> { get }
    
    func handle(_ action: Action)
    func eraseToAnyView() -> AnyView
}

extension Coordinator {
    
    /// Present an external coordinator as a sheet.
    func presentSheet<T: Coordinator>(_ coordinator: T) {
        coordinator.parent = self
        addChild(coordinator: coordinator)
        sheet = coordinator
    }
    
    func presentFullScreen<T: Coordinator>(_ coordinator: T) {
        coordinator.parent = self
        addChild(coordinator: coordinator)
        fullScreenSheet = coordinator
    }
    
    // Dismiss the sheet/full-screen presentation owned by this coordinator
    func dismissPresented() {
        if let child = fullScreenSheet {
            removeChild(coordinator: child)
            fullScreenSheet = nil
        } else if let child = sheet {
            removeChild(coordinator: child)
            sheet = nil
        }
    }
    
    // Dismiss this coordinator from its parent, or its own presentation first
    func dismiss() {
        if sheet != nil || fullScreenSheet != nil {
            dismissPresented()
        } else {
            parent?.dismiss()
        }
    }
    
    // Recursively remove the entire child/presentation hierarchy
    func dismissAll() {
        childs.forEach { $0.dismissAll() }
        childs.removeAll()
        sheet = nil
        fullScreenSheet = nil
    }
    
    func dismissRootPresentation() {
        var current: (any Coordinator) = self
        
        while let parent = current.parent {
            current = parent
        }
        current.dismissPresented()
    }
    
    // MARK: Child
    
    func addChild(coordinator: any Coordinator) {
        childs.append(coordinator)
    }
    
    func removeChild(coordinator: any Coordinator) {
        childs.removeAll {
            ObjectIdentifier($0 as AnyObject) == ObjectIdentifier(coordinator as AnyObject)
        }
    }
}

// MARK: - NavigationCoordinator

@MainActor
protocol NavigationCoordinator: Coordinator {

    associatedtype Route: NavigationRoute where Route.Action == Action

    var path: [Route] { get set }
    var root: Route { get }
}

extension NavigationCoordinator {
    
    /// Present a route as a sheet using a child coordinator of the same type.
    func presentSheet(route: Route) {
        let child = SheetCoordinator(root: route, parent: self)
        addChild(coordinator: child)
        sheet = child
    }
    
    func presentFullScreen(route: Route) {
        let child = SheetCoordinator(root: route, parent: self)
        addChild(coordinator: child)
        fullScreenSheet = child
    }
    
    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }
    
    func popTo(_ route: Route) {
        guard let index = path.firstIndex(of: route) else {
            return
        }
        path = Array(path.prefix(through: index))
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    // Dismiss the current presentation and navigate back to the specified route
    func dismissAndPopTo(route: Route) {
        dismissPresented()
        popTo(route)
    }
    
    func eraseToAnyView() -> AnyView {
        AnyView(CoordinatorView(coordinator: self))
    }
}

// MARK: - SheetCoordinator

/// Used  when presenting a route as a sheet or full-screen cover that still
/// belongs to the same flow
@MainActor
private final class SheetCoordinator<Parent: NavigationCoordinator>: NavigationCoordinator {
    typealias Route = Parent.Route
    typealias Action = Parent.Action
    
    weak private var parentCoordinator: Parent?
    
    @Published var path: [Route] = []
    @Published var sheet: (any Coordinator)?
    @Published var fullScreenSheet: (any Coordinator)?
    
    let root: Route
    
    var parent: (any Coordinator)? {
        get { parentCoordinator }
        set { parentCoordinator = newValue as? Parent }
    }
    
    var childs: [any Coordinator] = []
    
    var navigationActing: SubjectActing<Action> {
        return parentCoordinator?.navigationActing ?? .init(receiveValue: { _ in })
    }
    
    init(root: Route, parent: Parent) {
        self.root = root
        self.parentCoordinator = parent
    }
    
    func handle(_ action: Action) {
        parentCoordinator?.handle(action)
    }
}
