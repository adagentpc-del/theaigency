import Foundation

/// What the user is actually trying to accomplish with the message.
/// Collected once, up front (Step 2 of the flow), and used both to judge
/// the proposed message in context and, later, to generate rewrites —
/// the user is never asked to restate it.
enum Goal: String, Codable, CaseIterable, Identifiable, Hashable {
    case flirt
    case makePlans
    case getClarity
    case apologize
    case setBoundary
    case getClosure
    case checkingIn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flirt: return "Flirt"
        case .makePlans: return "Make plans"
        case .getClarity: return "Get clarity"
        case .apologize: return "Apologize"
        case .setBoundary: return "Set a boundary"
        case .getClosure: return "Get closure"
        case .checkingIn: return "Just checking in"
        }
    }
}
