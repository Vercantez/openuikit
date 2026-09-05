import Foundation

extension Tips {
    @resultBuilder
    public enum RuleBuilder {
        public static func buildBlock() -> [Tips.Rule] { [] }

        public static func buildBlock(_ components: Tips.Rule...) -> [Tips.Rule] {
            Array(components)
        }

        public static func buildOptional(_ component: Tips.Rule?) -> [Tips.Rule] {
            component.map { [$0] } ?? []
        }
    }

    @resultBuilder
    public enum ActionBuilder {
        public static func buildBlock() -> [Tips.Action] { [] }

        public static func buildBlock(_ components: Tips.Action...) -> [Tips.Action] {
            Array(components)
        }
    }

    @resultBuilder
    public enum OptionsBuilder {
        public static func buildBlock() -> [any TipOption] { [] }

        public static func buildBlock(_ components: any TipOption...) -> [any TipOption] {
            Array(components)
        }
    }

    @resultBuilder
    public enum GroupBuilder {
        public static func buildBlock() -> [any Tip] { [] }

        public static func buildBlock(_ components: any Tip...) -> [any Tip] {
            Array(components)
        }
    }
}
