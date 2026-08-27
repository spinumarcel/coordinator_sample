@attached(member, names:
    named(Route),
    named(Action),
    named(path),
    named(sheet),
    named(fullScreenSheet),
    named(alert),
    named(parent),
    named(childs),
    named(navigationActing),
    named(makeNavigationActing)
)
public macro Coordinator(_ route: Any.Type) = #externalMacro(
    module: "CoordinatorMacroImpl",
    type: "CoordinatorMacro"
)
