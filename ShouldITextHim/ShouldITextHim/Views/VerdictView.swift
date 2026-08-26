import SwiftUI

struct VerdictView: View {
    let viewModel: JudgeViewModel
    let request: JudgmentRequest
    let result: JudgmentResult

    private var shareText: String {
        "Verdict: \(result.verdict.headline)\nJudged by Should I Text Him?"
    }

    private var rewriteButtonTitle: String {
        result.recommendedAction == .direct ? "SEND SOMETHING DIRECT" : "HELP ME REWRITE IT"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Goal: \(request.goal.title)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            if result.isLocalFallback {
                localFallbackBanner
            }

            Spacer(minLength: 4)

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

            Spacer(minLength: 4)

            VStack(spacing: 12) {
                if !result.isSafetyRouted {
                    Button {
                        Haptics.tap()
                        viewModel.startRewrite()
                    } label: {
                        Text(rewriteButtonTitle)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: Theme.minimumTapTarget)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityHint("Get rewrite options for \(request.goal.title.lowercased())")
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
                    .accessibilityHint("Shares only the verdict, not your original message or context")
                }
            }
        }
        .padding(20)
        .onAppear {
            Haptics.verdictRevealed(for: result.verdict)
        }
    }

    /// Shown only when this result came from the on-device fallback
    /// because the AI judgment service was unavailable — never faking
    /// confidence about a result we couldn't fully verify. See
    /// `AI_SAFETY.md` and `DECISIONS.md`.
    private var localFallbackBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("I can't judge this properly right now — this is a limited, local-only check.", systemImage: "wifi.slash")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                Haptics.tap()
                Task { await viewModel.retryJudgment() }
            } label: {
                Text("Try again for full analysis")
                    .font(.footnote.weight(.semibold))
            }
            .accessibilityHint("Retries the full analysis, useful once you have a connection")
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

#Preview {
    VerdictView(
        viewModel: JudgeViewModel(),
        request: JudgmentRequest(
            proposedMessage: "Hey stranger lol",
            goal: .getClarity,
            context: .quick(QuickContext(
                whoTextedLast: .me,
                timeSinceLastMessage: .oneToThreeDays,
                didHeRespond: .no,
                additionalNotes: ""
            ))
        ),
        result: JudgmentResult(
            verdict: .dontSend,
            reason: "You already asked a direct question and haven't gotten an answer. Another casual check-in probably won't get you the clarity you're looking for.",
            riskFlags: [],
            isSafetyRouted: false
        )
    )
}
