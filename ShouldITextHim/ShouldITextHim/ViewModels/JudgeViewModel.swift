import Foundation
import Observation

/// Abstraction over the system clipboard so the view model stays unit
/// testable without pulling in UIKit in the test target.
protocol ClipboardWriting {
    func write(_ text: String)
}

/// Screens the user can be on. Modeling this as one enum keeps navigation
/// state impossible to desync (no separate "isShowingX" booleans that can
/// contradict each other).
enum JudgePhase: Equatable {
    case input
    case judging
    case verdict(JudgmentResult)
    case rewriteIntent
    case rewriteResult(Intent, [RewriteOption])
}

@MainActor
@Observable
final class JudgeViewModel {
    var inputText: String = ""
    private(set) var phase: JudgePhase = .input
    var lastCopiedConfirmation: Bool = false

    private let clipboard: ClipboardWriting
    /// Small artificial delay so the loading state is perceivable and the
    /// verdict feels considered rather than instantaneous. Kept short to
    /// respect the "verdict in under ~10 seconds" success target.
    private let judgingDelayNanoseconds: UInt64

    init(
        clipboard: ClipboardWriting = SystemClipboard(),
        judgingDelayNanoseconds: UInt64 = 500_000_000
    ) {
        self.clipboard = clipboard
        self.judgingDelayNanoseconds = judgingDelayNanoseconds
    }

    var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isJudging: Bool {
        if case .judging = phase { return true }
        return false
    }

    func judge() async {
        guard isInputValid else { return }
        phase = .judging
        if judgingDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: judgingDelayNanoseconds)
        }
        let result = JudgmentEngine.judge(inputText)
        // The pasted message is only ever held in memory for this call and
        // is never written to disk or logs. See PRIVACY_DATA_MAP.md.
        phase = .verdict(result)
    }

    func reset() {
        inputText = ""
        phase = .input
        lastCopiedConfirmation = false
    }

    func startRewrite() {
        guard case .verdict = phase else { return }
        phase = .rewriteIntent
    }

    func selectIntent(_ intent: Intent) {
        let options = RewriteEngine.options(for: intent)
        phase = .rewriteResult(intent, options)
    }

    func copy(_ text: String) {
        clipboard.write(text)
        lastCopiedConfirmation = true
    }
}

#if canImport(UIKit)
import UIKit

struct SystemClipboard: ClipboardWriting {
    func write(_ text: String) {
        UIPasteboard.general.string = text
    }
}
#else
struct SystemClipboard: ClipboardWriting {
    func write(_ text: String) {
        // No-op outside iOS; kept so the type still exists for non-UIKit
        // builds/tooling.
    }
}
#endif
