import SwiftUI

/// Owns the single view model for the whole app and renders whichever
/// screen the current phase calls for. The product is small enough that a
/// full NavigationStack/coordinator layer would be pure overhead — a
/// switch over an enum is the entire navigation model.
struct RootView: View {
    @State private var viewModel = JudgeViewModel()

    var body: some View {
        Group {
            switch viewModel.phase {
            case .input, .judging:
                InputView(viewModel: viewModel)
            case .verdict(let result):
                VerdictView(viewModel: viewModel, result: result)
            case .rewriteIntent:
                RewriteIntentView(viewModel: viewModel)
            case .rewriteResult(let intent, let options):
                RewriteResultView(viewModel: viewModel, intent: intent, options: options)
            }
        }
        .reduceMotionAware(.easeInOut(duration: 0.25), value: phaseIdentity)
    }

    /// A cheap, stable value to animate on since JudgePhase itself carries
    /// associated data we don't want to diff structurally for transitions.
    private var phaseIdentity: Int {
        switch viewModel.phase {
        case .input: return 0
        case .judging: return 1
        case .verdict: return 2
        case .rewriteIntent: return 3
        case .rewriteResult: return 4
        }
    }
}

#Preview {
    RootView()
}
