import SwiftUI
import Combine
import CoordinatorMacro

// MARK: - Home Coordinator

enum HomeAction: Sendable {
    case goToCatalog
    case goToProductDetail(id: String)
    case goToCart
    case popBack
    case popToHome
    case showLogin
    case showOrderConfirmation(orderId: String)
}

enum HomeRoute: NavigationRoute {
    case home
    case catalog
    case productDetail(id: String)
    case cart

    func build(navigationActing: SubjectActing<HomeAction>) -> some View {
        switch self {
        case .home:
            HomeScreen(acting: navigationActing)
        case .catalog:
            CatalogScreen(acting: navigationActing)
        case .productDetail(let id):
            ProductDetailScreen(id: id, acting: navigationActing)
        case .cart:
            CartScreen(acting: navigationActing)
        }
    }
}

@Coordinator(HomeRoute.self)
final class HomeCoordinator: NavigationCoordinator {
    
    let root: HomeRoute = .home
    
    func handle(_ action: HomeAction) {
        switch action {
        case .goToCatalog:
            push(.catalog)
        case .goToProductDetail(let id):
            push(.productDetail(id: id))
        case .goToCart:
            push(.cart)
        case .popBack:
            pop()
        case .popToHome:
            popToRoot()
        case .showLogin:
            presentSheet(AuthCoordinator())
        case .showOrderConfirmation(let orderId):
            presentFullScreen(OrderCoordinator(orderId: orderId))
        }
    }
}

// MARK: - Auth Coordinator

enum AuthAction: Sendable {
    case goToRegister
    case showInfo
    case dismissPresented
    case dismissToRoot
    case pop
}

enum AuthRoute: NavigationRoute {
    case login
    case register
    case info

    func build(navigationActing: SubjectActing<AuthAction>) -> some View {
        switch self {
        case .login:
            LoginScreen(acting: navigationActing)
        case .register:
            RegisterScreen(acting: navigationActing)
        case .info:
            RegisterInfoScreen(acting: navigationActing)
        }
    }
}

@Coordinator(AuthRoute.self)
final class AuthCoordinator: NavigationCoordinator {

    let root: AuthRoute = .login

    func handle(_ action: AuthAction) {
        switch action {
        case .goToRegister:
            push(.register)
        case .showInfo:
            presentSheet(route: .info)
        case .dismissPresented:
            dismiss()
        case .dismissToRoot:
            dismissRootPresentation()
        case .pop:
            pop()
        }
    }
}

// MARK: - Order Coordinator

enum OrderAction: Sendable {
    case goToSuccess
    case popToRoot
    case dismiss
}

enum OrderRoute: NavigationRoute {
    case confirmation(orderId: String)
    case success

    func build(navigationActing: SubjectActing<OrderAction>) -> some View {
        switch self {
        case .confirmation(let id):
            OrderConfirmationScreen(orderId: id, acting: navigationActing)
        case .success:
            OrderSuccessScreen(acting: navigationActing)
        }
    }
}

@Coordinator(OrderRoute.self)
final class OrderCoordinator: NavigationCoordinator {
    
    let root: OrderRoute

    init(orderId: String) {
        root = .confirmation(orderId: orderId)
    }
    
    func handle(_ action: OrderAction) {
        switch action {
        case .goToSuccess:
            push(.success)
        case .popToRoot:
            parent?.dismissPresented()
            (parent as? any NavigationCoordinator)?.popToRoot()
        case .dismiss:
            dismiss()
        }
    }
}

// MARK: - Screens

struct HomeScreen: View {
    
    let acting: SubjectActing<HomeAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Home")
            Divider()
            ActionButton("Go to Catalog") {
                acting.send(.goToCatalog)
            }
            ActionButton("Show Login (sheet)") {
                acting.send(.showLogin)
            }
            ActionButton("Confirm Order (fullscreen)") {
                acting.send(.showOrderConfirmation(orderId: "42"))
            }
        }
        .padding()
        .navigationTitle("Home")
    }
}

struct CatalogScreen: View {
    
    let acting: SubjectActing<HomeAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Catalog")
            Divider()
            ActionButton("Product A") {
                acting.send(.goToProductDetail(id: "product-A"))
            }
            ActionButton("Product B") {
                acting.send(.goToProductDetail(id: "product-B"))
            }
            ActionButton("← Back") {
                acting.send(.popBack)
            }
        }
        .padding()
        .navigationTitle("Catalog")
    }
}

struct ProductDetailScreen: View {
    
    let id: String
    let acting: SubjectActing<HomeAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Order \(id)")
            Divider()
            ActionButton("Add to Cart → Go to Cart") {
                acting.send(.goToCart)
            }
            ActionButton("← Back") {
                acting.send(.popBack)
            }
            ActionButton("←← Back to Home") {
                acting.send(.popToHome)
            }
        }
        .padding()
        .navigationTitle(id)
    }
}

struct CartScreen: View {
    
    let acting: SubjectActing<HomeAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Cart")
            Divider()
            ActionButton("Checkout → Order") {
                acting.send(.showOrderConfirmation(orderId: "99"))
            }
            ActionButton("← Back") {
                acting.send(.popBack)
            }
            ActionButton("←← Back to Home") {
                acting.send(.popToHome)
            }
        }
        .padding()
        .navigationTitle("Cart")
    }
}

struct LoginScreen: View {
    
    let acting: SubjectActing<AuthAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Login")
            Divider()
            ActionButton("Go to Register") {
                acting.send(.goToRegister)
            }
            ActionButton("Dismiss sheet") {
                acting.send(.dismissPresented)
            }
        }
        .padding()
        .navigationTitle("Login")
    }
}

struct RegisterScreen: View {
    
    let acting: SubjectActing<AuthAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Register")
            Divider()
            ActionButton("Show info") {
                acting.send(.showInfo)
            }
            ActionButton("← Back") {
                acting.send(.pop)
            }
        }
        .padding()
        .navigationTitle("Register")
    }
}

struct RegisterInfoScreen: View {
    
    let acting: SubjectActing<AuthAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Register info")
            Divider()
            ActionButton("Dismiss") {
                acting.send(.dismissPresented)
            }
            ActionButton("Dismiss To Root") {
                acting.send(.dismissToRoot)
            }
        }
        .padding()
        .navigationTitle("Info")
    }
}

struct OrderConfirmationScreen: View {
    
    let orderId: String
    let acting: SubjectActing<OrderAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Order #\(orderId)")
            Divider()
            ActionButton("Confirm → Success") {
                acting.send(.goToSuccess)
            }
            ActionButton("Close") {
                acting.send(.dismiss)
            }
        }
        .padding()
        .navigationTitle("Confirm Order")
    }
}

struct OrderSuccessScreen: View {
    
    let acting: SubjectActing<OrderAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Order Placed!")
            Divider()
            ActionButton("←← Back to Home") {
                acting.send(.popToRoot)
            }
        }
        .padding()
        .navigationTitle("Success")
    }
}

// MARK: - Helpers

func label(_ text: String) -> some View {
    Text(text)
        .font(.title2)
        .bold()
}

struct ActionButton: View {
    
    let title: String
    let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
}
