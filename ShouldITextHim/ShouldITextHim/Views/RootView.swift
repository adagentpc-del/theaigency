import SwiftUI

/// Owns the single view model for the whole app and renders whichever
/// screen the current phase calls for. The product is small enough that a
/// full NavigationStack/coordinator layer would be pure overhead — a
/// switch over an enum is the entire navigation model.
///
/// Flow: message -> goal -> context -> (judging) -> verdict ->
/// optionally rewriteResult. Judgment only ever runs from `.judging`,
/// which is only reachable after all three input steps are complete —
/// see `JudgeViewModel.submitContext()`.
struct RootView: View {
    @State private var viewModel = JudgeViewModel()

    var body: some View {
        Group {
            switch viewModel.phase {
            case .message:
                MessageStepView(viewModel: viewModel)
            case .goal:
                GoalStepView(viewModel: viewModel)
            case .context, .judging:
                ContextStepView(viewModel: viewModel)
            case .verdict(let request, let result):
                VerdictView(viewModel: viewModel, request: request, result: result)
            case .rewriteResult(let goal, let options):
                RewriteResultView(viewModel: viewModel, goal: goal, options: options)
            }
        }
        .reduceMotionAware(.easeInOut(duration: 0.25), value: phaseIdentity)
    }

    /// A cheap, stable value to animate on since JudgePhase itself carries
    /// associated data we don't want to diff structurally for transitions.
    private var phaseIdentity: Int {
        switch viewModel.phase {
        case .message: return 0
        case .goal: return 1
        case .context: return 2
        case .judging: return 3
        case .verdict: return 4
        case .rewriteResult: return 5
        }
    }
}

#Preview {
    RootView()
}
