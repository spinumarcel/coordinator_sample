import SwiftUI

struct AlertContent {
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actions: [Action]
    
    struct Action {
        let title: LocalizedStringKey
        let role: ButtonRole?
        let handler: (() -> Void)?
        
        init(
            title: LocalizedStringKey,
            role: ButtonRole? = nil,
            handler: (() -> Void)? = nil
        ) {
            self.title = title
            self.role = role
            self.handler = handler
        }
        
        static func destructive(title: LocalizedStringKey,  handler: (() -> Void)? = nil) -> Self {
            .init(title: title, role: .destructive, handler: handler)
        }
        
        static func cancel(title: LocalizedStringKey,  handler: (() -> Void)? = nil) -> Self {
            .init(title: title, role: .cancel, handler: handler)
        }
        
        static func standard(title: LocalizedStringKey, handler: (() -> Void)? = nil) -> Self {
            .init(title: title, role: nil, handler: handler)
        }
    }
}
