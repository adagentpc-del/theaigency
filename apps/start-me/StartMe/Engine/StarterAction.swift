import Foundation

/// A single tiny physical first step, plus the reassurance line shown with it
/// and the (optional) chain of even-smaller steps "Make it even smaller" walks through.
struct StarterAction: Equatable {
    let primaryAction: String
    let reassurance: String?
    let smallerActions: [String]
    let category: TaskCategory
}
