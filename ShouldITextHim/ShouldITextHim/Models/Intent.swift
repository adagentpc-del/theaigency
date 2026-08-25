import Foundation

/// What the user is actually trying to accomplish with a rewrite.
enum Intent: String, Codable, CaseIterable, Identifiable, Hashable {
    case flirt
    case makePlans
    case getClarity
    case apologize
    case setBoundary
    case getClosure
    case sayLess

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flirt: return "Flirt"
        case .makePlans: return "Make plans"
        case .getClarity: return "Get clarity"
        case .apologize: return "Apologize"
        case .setBoundary: return "Set a boundary"
        case .getClosure: return "Get closure"
        case .sayLess: return "Say less"
        }
    }
}
