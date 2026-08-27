import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct CoordinatorMacro: MemberMacro, ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard
            let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let routeExpr = arguments.first?.expression,
            let memberAccess = routeExpr.as(MemberAccessExprSyntax.self),
            memberAccess.declName.baseName.text == "self"
        else {
            throw CoordinatorMacroError("@Coordinator requires a route type, e.g. @Coordinator(HomeRoute.self)")
        }

        let routeType = memberAccess.base?.trimmedDescription ?? ""

        guard !routeType.isEmpty else {
            throw CoordinatorMacroError("Could not determine route type from @Coordinator")
        }
        
        return [
            "typealias Route = \(raw: routeType)",
            "typealias Action = \(raw: routeType).Action",
            "@Published var path: [\(raw: routeType)] = []",
            "@Published var sheet: (any Coordinator)?",
            "@Published var fullScreenSheet: (any Coordinator)?",
            "@Published var alert: AlertContent?",
            "weak var parent: (any Coordinator)?",
            "var childs: [any Coordinator] = []",
            "private(set) lazy var navigationActing: SubjectActing<\(raw: routeType).Action> = makeNavigationActing()",
            """
            private func makeNavigationActing() -> SubjectActing<\(raw: routeType).Action> {
                SubjectActing<\(raw: routeType).Action>(receiveValue: { [weak self] action in
                    self?.handle(action)
                })
            }
            """
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let typeName = type.as(IdentifierTypeSyntax.self)?.name.text else {
            throw CoordinatorMacroError("Could not determine type name for @Coordinator extension")
        }
        let ext = try ExtensionDeclSyntax("@MainActor extension \(raw: typeName) {}")
        return [ext]
    }
}

struct CoordinatorMacroError: Error, CustomStringConvertible {
    let description: String
    
    init(_ description: String) {
        self.description = description
    }
}

@main
struct CoordinatorMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CoordinatorMacro.self
    ]
}
