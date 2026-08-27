import Foundation

/// Lightweight local classification bucket for a typed-in task.
/// Kept intentionally small — this is a compact router to a starter-action
/// library, not a general-purpose task taxonomy.
enum TaskCategory: String, CaseIterable, Codable, Equatable {
    case cleaning
    case laundry
    case dishes
    case studying
    case writing
    case email
    case admin
    case taxes
    case workout
    case leavingHouse
    case packing
    case cooking
    case errands
    case phoneCall
    case organizing
    case computerWork
    case personalCare
    case general
}
