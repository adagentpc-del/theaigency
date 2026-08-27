import Foundation

@MainActor
final class StarterViewModel: ObservableObject {
    @Published private(set) var action: StarterAction
    /// 0 = showing the primary action. N>0 = showing `smallerActions[N-1]`.
    @Published private(set) var reductionLevel: Int = 0

    let originalInput: String
    private let engine: TaskStarterEngine

    init(originalInput: String, engine: TaskStarterEngine) {
        self.originalInput = originalInput
        self.engine = engine
        self.action = engine.starterAction(for: originalInput)
    }

    var displayedActionText: String {
        guard reductionLevel > 0, reductionLevel - 1 < action.smallerActions.count else {
            return action.primaryAction
        }
        return action.smallerActions[reductionLevel - 1]
    }

    var reassurance: String? {
        action.reassurance
    }

    var canMakeSmaller: Bool {
        reductionLevel < action.smallerActions.count
    }

    var canOfferDifferentStart: Bool {
        action.category != .general || !action.smallerActions.isEmpty
    }

    func makeSmaller() {
        guard canMakeSmaller else { return }
        reductionLevel += 1
    }

    func requestDifferentStart() {
        action = engine.alternateAction(current: action, originalInput: originalInput)
        reductionLevel = 0
    }
}
