import SwiftUI
import Combine
import CoordinatorMacro

// MARK: - Services Coordinator

enum ServicesAction: Sendable {
    case goToServiceList
    case showServiceInfo
}

enum ServiceListAction: Sendable {
    case goToServiceDetail(id: String)
    case popBack
}

enum ServiceDetailAction: Sendable {
    case goToBooking(serviceId: String)
    case popBack
    case popToRoot
}

enum ServiceBookingAction: Sendable {
    case confirmAlert(AlertContent)
    case confirm
    case popBack
    case popToRoot
    case popToList
}

enum BookingConfirmationAction: Sendable {
    case goToServiceBenefits
    case popToList
    case done
    case dismiss
}

enum ServicesRoute: NavigationRoute {
    case services
    case serviceList(acting: SubjectActing<ServiceListAction>)
    case serviceDetail(id: String, acting: SubjectActing<ServiceDetailAction>)
    case serviceBooking(serviceId: String, acting: SubjectActing<ServiceBookingAction>)
    case bookingConfirmation(serviceId: String, acting: SubjectActing<BookingConfirmationAction>)
    case serviceBenefits
    
    func build(navigationActing: SubjectActing<ServicesAction>) -> some View {
        switch self {
        case .services:
            ServicesScreen(acting: navigationActing)
        case .serviceList(let acting):
            ServiceListScreen(acting: acting)
        case .serviceDetail(let id, let acting):
            ServiceDetailScreen(id: id, acting: acting)
        case .serviceBooking(let serviceId, let acting):
            ServiceBookingScreen(serviceId: serviceId, acting: acting)
        case .bookingConfirmation(let serviceId, let acting):
            BookingConfirmationScreen(serviceId: serviceId, acting: acting)
        case .serviceBenefits:
            ServiceBenefitsScreen()
        }
    }
}

extension ServicesRoute: Equatable {
    
    var id: String {
        switch self {
        case .services, .serviceList, .serviceBenefits:
            return "\(self)"
        case .serviceDetail(let id, _), .serviceBooking(let id, _), .bookingConfirmation(let id, _):
            return "\(caseName)-\(id)"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ServicesRoute, rhs: ServicesRoute) -> Bool {
        switch (lhs, rhs) {
        case (.services, .services), (.serviceList, .serviceList), (.serviceBenefits, .serviceBenefits):
            return true
        case (.serviceDetail(let lhsId, _), .serviceDetail(let rhsId, _)), (.serviceBooking(let lhsId, _), .serviceBooking(let rhsId, _)), (.bookingConfirmation(let lhsId, _), .bookingConfirmation(let rhsId, _)):
            return lhsId == rhsId
        case (.services, _), (.serviceList, _), (.serviceDetail, _), (.serviceBooking, _), (.bookingConfirmation, _), (.serviceBenefits, _):
            return false
        }
    }
}

@Coordinator(ServicesRoute.self)
final class ServicesCoordinator: NavigationCoordinator {
    
    let root: ServicesRoute = .services
    
    func handle(_ action: ServicesAction) {
        switch action {
        case .goToServiceList:
            goToServiceList()
        case .showServiceInfo:
            showServiceInfo()
        }
    }
    
    private func goToServiceList() {
        let acting = SubjectActing<ServiceListAction> { [weak self] action in
            switch action {
            case .goToServiceDetail(let id):
                self?.goToServiceDetail(id: id)
            case .popBack:
                self?.pop()
            }
        }
        push(.serviceList(acting: acting))
    }
    
    private func goToServiceDetail(id: String) {
        let acting = SubjectActing<ServiceDetailAction> { [weak self] action in
            switch action {
            case .goToBooking(let serviceId):
                self?.goToBooking(serviceId: serviceId)
            case .popBack:
                self?.pop()
            case .popToRoot:
                self?.popToRoot()
            }
        }
        push(.serviceDetail(id: id, acting: acting))
    }
    
    private func goToBooking(serviceId: String) {
        let acting = SubjectActing<ServiceBookingAction> { [weak self] action in
            switch action {
            case .confirmAlert(let content):
                self?.presentAlert(content)
            case .confirm:
                self?.showBookingConfirmation(serviceId: serviceId)
            case .popBack:
                self?.pop()
            case .popToRoot:
                self?.popToRoot()
            case .popToList:
                self?.popTo {
                    if case .serviceList = $0 {
                        return true
                    }
                    return false
                }
            }
        }
        push(.serviceBooking(serviceId: serviceId, acting: acting))
    }
    
    private func showBookingConfirmation(serviceId: String) {
        let acting = SubjectActing<BookingConfirmationAction> { [weak self] action in
            switch action {
            case .goToServiceBenefits:
                let sheetCoordinator = self?.sheet as? PresentedCoordinator<ServicesCoordinator>
                sheetCoordinator?.push(.serviceBenefits)
            case .popToList:
                self?.dismissAndPopTo {
                    if case .serviceList = $0 {
                        return true
                    }
                    return false
                }
            case .done:
                self?.dismissPresented()
                self?.popToRoot()
            case .dismiss:
                self?.dismissPresented()
            }
        }
        presentSheet(route: .bookingConfirmation(serviceId: serviceId, acting: acting))
    }
    
    private func showServiceInfo() {
        presentSheet(ServiceInfoCoordinator())
    }
}

// MARK: - Service Info Coordinator

enum ServiceInfoAction: Sendable {
    case dismiss
}

enum ServiceInfoRoute: NavigationRoute {
    case info
    
    func build(navigationActing: SubjectActing<ServiceInfoAction>) -> some View {
        switch self {
        case .info:
            ServiceInfoScreen(acting: navigationActing)
        }
    }
}

@Coordinator(ServiceInfoRoute.self)
final class ServiceInfoCoordinator: NavigationCoordinator {
    
    let root: ServiceInfoRoute = .info
    
    func handle(_ action: ServiceInfoAction) {
        switch action {
        case .dismiss:
            dismissSelf()
        }
    }
}

// MARK: - Screens

struct ServicesScreen: View {
    
    let acting: SubjectActing<ServicesAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Services")
            Divider()
            ActionButton("View All Services") {
                acting.send(.goToServiceList)
            }
            ActionButton("Service Info (sheet)") {
                acting.send(.showServiceInfo)
            }
        }
        .padding()
        .navigationTitle("Services")
    }
}

struct ServiceListScreen: View {
    
    let acting: SubjectActing<ServiceListAction>
    
    private let services = ["Cleaning", "Plumbing", "Electrical"]
    
    var body: some View {
        VStack(spacing: 16) {
            label("All Services")
            Divider()
            ForEach(services, id: \.self) { service in
                ActionButton(service) {
                    acting.send(.goToServiceDetail(id: service))
                }
            }
            ActionButton("← Back") {
                acting.send(.popBack)
            }
        }
        .padding()
        .navigationTitle("Service List")
    }
}

struct ServiceDetailScreen: View {
    
    let id: String
    let acting: SubjectActing<ServiceDetailAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label(id)
            Divider()
            ActionButton("Book \(id)") {
                acting.send(.goToBooking(serviceId: id))
            }
            ActionButton("← Back") {
                acting.send(.popBack)
            }
            ActionButton("←← Back to Services") {
                acting.send(.popToRoot)
            }
        }
        .padding()
        .navigationTitle(id)
    }
}

struct ServiceBookingScreen: View {
    
    let serviceId: String
    let acting: SubjectActing<ServiceBookingAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Book \(serviceId)")
            Divider()
            ActionButton("✓ Confirm Booking") {
                acting.send(.confirmAlert(alertContent))
            }
            ActionButton("← Back") {
                acting.send(.popBack)
            }
            ActionButton("←← Back to List") {
                acting.send(.popToList)
            }
            ActionButton("←← Back to Services") {
                acting.send(.popToRoot)
            }
        }
        .padding()
        .navigationTitle("Booking")
    }
    
    private var alertContent: AlertContent {
        .init(
            title: "Confirm Booking",
            message: "Do you want to confirm this booking?",
            actions: [
                .cancel(title: "Cancel"),
                .standard(title: "Confirm") {
                    acting.send(.confirm)
                }
            ]
        )
    }
}

struct ServiceInfoScreen: View {
    
    let acting: SubjectActing<ServiceInfoAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Service Info")
            Divider()
            Text("All services are available 9am–6pm on weekdays.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            ActionButton("Close") {
                acting.send(.dismiss)
            }
        }
        .padding()
        .navigationTitle("Info")
    }
}

struct BookingConfirmationScreen: View {
    
    let serviceId: String
    let acting: SubjectActing<BookingConfirmationAction>
    
    var body: some View {
        VStack(spacing: 16) {
            label("Booking Confirmed!")
            Divider()
            Text("Your booking for \(serviceId) has been confirmed.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            ActionButton("Benefits") {
                acting.send(.goToServiceBenefits)
            }
            ActionButton("←← Back to List") {
                acting.send(.popToList)
            }
            ActionButton("Close") {
                acting.send(.dismiss)
            }
            ActionButton("✓ Done") {
                acting.send(.done)
            }
        }
        .padding()
        .navigationTitle("Confirmation")
    }
}

struct ServiceBenefitsScreen: View {
    
    private let benefits = [
        "Priority booking",
        "Free cancellation",
        "Exclusive member discounts",
        "24/7 customer support"
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            label("Service Benefits")
            Divider()
            benefitsList
        }
        .padding()
        .navigationTitle("Benefits")
    }
    
    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                    Text(benefit)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
