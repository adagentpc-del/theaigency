import Foundation
import Observation

/// Which of the two Step 3 context options the user is currently using.
enum ContextMethod: String, CaseIterable, Identifiable, Hashable {
    case quick
    case conversation

    var id: String { rawValue }
}

/// Screens the user can be on. Modeling this as one enum keeps navigation
/// state impossible to desync. Input-collection steps (message/goal/
/// context) carry no associated data — the view model's own properties
/// are the single source of truth for those, which is what makes simple
/// back-navigation between them possible. Only the two "result" phases
/// carry a snapshot, since those are tied to a specific completed
/// request.
enum JudgePhase: Equatable {
    case message
    case goal
    case context
    case judging
    case verdict(JudgmentRequest, JudgmentResult)
    case rewriteResult(Goal, [RewriteOption])
}

@MainActor
@Observable
final class JudgeViewModel {
    // Step 1 — proposed message.
    var proposedMessage: String = ""

    // Step 2 — goal.
    var selectedGoal: Goal?

    // Step 3 — context.
    var contextMethod: ContextMethod = .quick
    var conversationText: String = ""
    var quickWhoTextedLast: WhoTextedLast?
    var quickTimeSinceLastMessage: TimeSinceLastMessage?
    var quickDidHeRespond: DidHeRespond?
    var quickAdditionalNotes: String = ""

    private(set) var phase: JudgePhase = .message
    var lastCopiedConfirmation: Bool = false

    private let provider: JudgmentProvider
    private let clipboard: ClipboardWriting
    /// Small artificial delay so the loading state is perceivable and the
    /// verdict feels considered rather than instantaneous.
    private let judgingDelayNanoseconds: UInt64

    init(
        provider: JudgmentProvider = RemoteAIJudgmentProvider(),
        clipboard: ClipboardWriting = SystemClipboard(),
        judgingDelayNanoseconds: UInt64 = 500_000_000
    ) {
        self.provider = provider
        self.clipboard = clipboard
        self.judgingDelayNanoseconds = judgingDelayNanoseconds
    }

    // MARK: - Validation

    var isMessageValid: Bool {
        !proposedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isContextValid: Bool {
        buildContextInput() != nil
    }

    var isJudging: Bool {
        if case .judging = phase { return true }
        return false
    }

    // MARK: - Step navigation

    func proceedToGoal() {
        guard isMessageValid else { return }
        phase = .goal
    }

    func selectGoal(_ goal: Goal) {
        selectedGoal = goal
        phase = .context
    }

    func backToMessage() {
        phase = .message
    }

    func backToGoal() {
        phase = .goal
    }

    // MARK: - Judging

    func submitContext() async {
        guard isMessageValid, let goal = selectedGoal, let context = buildContextInput() else { return }
        let request = JudgmentRequest(proposedMessage: proposedMessage, goal: goal, context: context)
        phase = .judging
        if judgingDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: judgingDelayNanoseconds)
        }
        // The proposed message and context are only ever held in memory
        // for this call and are never written to disk or logs — see
        // PRIVACY_DATA_MAP.md.
        let result = await provider.judge(request)
        phase = .verdict(request, result)
    }

    private func buildContextInput() -> ContextInput? {
        switch contextMethod {
        case .conversation:
            let trimmed = conversationText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return .conversation(conversationText)
        case .quick:
            guard let who = quickWhoTextedLast,
                  let time = quickTimeSinceLastMessage,
                  let responded = quickDidHeRespond else { return nil }
            return .quick(QuickContext(
                whoTextedLast: who,
                timeSinceLastMessage: time,
                didHeRespond: responded,
                additionalNotes: quickAdditionalNotes
            ))
        }
    }

    // MARK: - Post-verdict actions

    func startRewrite() {
        guard case .verdict(let request, let result) = phase else { return }
        // Prefer the AI's contextual rewrite suggestions when it provided
        // any; fall back to the fixed local templates otherwise (safety
        // routing, mechanical rules, and the offline fallback never
        // populate rewriteOptions).
        let options = result.rewriteOptions.isEmpty
            ? RewriteEngine.options(for: request.goal)
            : result.rewriteOptions
        phase = .rewriteResult(request.goal, options)
    }

    /// Re-runs judgment for the same message/goal/context — offered on the
    /// verdict screen when the last result was a local fallback, so the
    /// user can retry for a full semantic analysis once back online. The
    /// underlying step properties are untouched by a normal verdict, so
    /// this is just `submitContext()` again.
    func retryJudgment() async {
        await submitContext()
    }

    /// Returns to Step 3 after a NEED MORE CONTEXT verdict, so the user can
    /// add detail without losing the message or goal they already entered.
    /// Everything already typed into Step 3 (pasted conversation or quick
    /// answers) is untouched — only `reset()` clears those.
    func returnToAddContext() {
        guard case .verdict = phase else { return }
        phase = .context
    }

    func reset() {
        proposedMessage = ""
        selectedGoal = nil
        contextMethod = .quick
        conversationText = ""
        quickWhoTextedLast = nil
        quickTimeSinceLastMessage = nil
        quickDidHeRespond = nil
        quickAdditionalNotes = ""
        lastCopiedConfirmation = false
        phase = .message
    }

    func copy(_ text: String) {
        clipboard.write(text)
        lastCopiedConfirmation = true
    }
}
