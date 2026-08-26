import SwiftUI
import Combine

protocol NavigationRoute: Hashable {
    associatedtype Destination: View
    associatedtype Action: Sendable
    
    @ViewBuilder
    func build(navigationActing: SubjectActing<Action>) -> Destination
}

extension NavigationRoute {
    var caseName: String {
        Mirror(reflecting: self).children.first?.label ?? "\(self)"
    }
}
