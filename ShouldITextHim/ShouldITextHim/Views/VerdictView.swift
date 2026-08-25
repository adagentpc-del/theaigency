import SwiftUI

struct VerdictView: View {
    let viewModel: JudgeViewModel
    let result: JudgmentResult

    private var shareText: String {
        "Verdict: \(result.verdict.headline)\nJudged by Should I Text Him?"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            VStack(spacing: 12) {
                Image(systemName: result.verdict.symbolName)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Theme.color(for: result.verdict))
                    .accessibilityHidden(true)

                Text(result.verdict.headline)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.color(for: result.verdict))
                    .accessibilityLabel(result.verdict.accessibilityLabel)
            }

            Text(result.reason)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)

            Spacer(minLength: 8)

            VStack(spacing: 12) {
                if !result.isSafetyRouted {
                    Button {
                        Haptics.tap()
                        viewModel.startRewrite()
                    } label: {
                        Text("HELP ME REWRITE IT")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: Theme.minimumTapTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityHint("Choose what you're trying to do and get rewrite options")
                }

                Button {
                    Haptics.tap()
                    viewModel.reset()
                } label: {
                    Text("START OVER")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if !result.isSafetyRouted {
                    ShareLink(item: shareText) {
                        Label("Share result", systemImage: "square.and.arrow.up")
                            .frame(minHeight: Theme.minimumTapTarget)
                    }
                    .accessibilityLabel("Share result")
                    .accessibilityHint("Shares only the verdict, not your original message")
                }
            }
        }
        .padding(20)
        .onAppear {
            Haptics.verdictRevealed(for: result.verdict)
        }
    }
}

#Preview {
    VerdictView(
        viewModel: JudgeViewModel(),
        result: JudgmentResult(
            verdict: .rewrite,
            reason: "This reads a little anxious — say less and let it breathe.",
            riskFlags: [],
            isSafetyRouted: false
        )
    )
}
