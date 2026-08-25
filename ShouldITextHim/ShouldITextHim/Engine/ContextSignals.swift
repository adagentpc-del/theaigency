import Foundation

/// Deterministic signals extracted from the conversational context —
/// "layer 2b" of the judgment architecture, mirroring `MessageSignals`.
///
/// The two `ContextInput` cases are handled very differently on purpose:
///
/// - **Quick context** (`.quick`) is closed-choice, structured data. Every
///   signal below can be derived from it reliably, so it drives the
///   deterministic rules in `DeterministicJudgmentRules` directly.
/// - **Pasted conversation** (`.conversation`) is free text. Genuinely
///   understanding a conversation (who said what, how long ago, what the
///   emotional arc was) is semantic judgment, not something a keyword
///   scan should pretend to do — see `DECISIONS.md` and `API_CONTRACT.md`
///   for why that's reserved for a future `RemoteAIJudgmentProvider`. The
///   local provider only pulls one narrow, honest signal from it
///   (`mentionsRepeatedContact`, a short list of self-reported phrases
///   like "already texted") and otherwise leaves every structured signal
///   `false`, which `FallbackJudgment` treats as "answer conservatively,
///   not confidently."
struct ContextSignals: Equatable {
    /// The user asked a direct question last time and got no answer.
    let hasPendingUnansweredQuestion: Bool
    /// The other person did not respond to the last message, regardless
    /// of whether it was a question.
    let recentNoResponse: Bool
    /// The user is the one who reached out last, and it's been at least
    /// a day since — i.e. they're the one waiting.
    let longSinceContact: Bool
    /// The user texted very recently and is considering texting again.
    let veryRecentSelfContact: Bool
    /// The other person responded positively/affirmatively.
    let positiveReciprocity: Bool
    /// The other person's response was lukewarm/noncommittal.
    let ambiguousReciprocity: Bool
    /// There was no pending question — the last exchange wasn't left
    /// hanging.
    let noQuestionPending: Bool
    /// True when this context came from a pasted conversation rather than
    /// quick-context answers — signals every structured field above is
    /// conservatively `false` regardless of what the text actually says.
    let isFromPastedConversation: Bool
    /// The user explicitly described reaching out more than once already
    /// (from quick-context notes or the pasted conversation). A narrow,
    /// self-reported signal — not general sentiment analysis.
    let mentionsRepeatedContact: Bool

    /// A short list of phrases people commonly use to self-report that
    /// they've already reached out more than once. Deliberately small and
    /// literal — this is not an attempt at general repetition detection.
    private static let repeatedContactPhrases = [
        "already texted", "texted again", "texted him again", "third time i've",
        "keep texting", "texted a few times", "called twice", "messaged again",
        "texted him twice", "reached out a few times"
    ]

    init(context: ContextInput) {
        switch context {
        case .quick(let quick):
            hasPendingUnansweredQuestion = quick.didHeRespond == .no
            recentNoResponse = quick.didHeRespond == .no
            longSinceContact = quick.whoTextedLast == .me &&
                (quick.timeSinceLastMessage == .oneToThreeDays || quick.timeSinceLastMessage == .fourPlusDays)
            veryRecentSelfContact = quick.whoTextedLast == .me && quick.timeSinceLastMessage == .underAnHour
            positiveReciprocity = quick.didHeRespond == .yes
            ambiguousReciprocity = quick.didHeRespond == .sortOf
            noQuestionPending = quick.didHeRespond == .noQuestion
            isFromPastedConversation = false
            mentionsRepeatedContact = Self.repeatedContactPhrases.contains {
                quick.additionalNotes.lowercased().contains($0)
            }

        case .conversation(let text):
            hasPendingUnansweredQuestion = false
            recentNoResponse = false
            longSinceContact = false
            veryRecentSelfContact = false
            positiveReciprocity = false
            ambiguousReciprocity = false
            noQuestionPending = false
            isFromPastedConversation = true
            let lower = text.lowercased()
            mentionsRepeatedContact = Self.repeatedContactPhrases.contains { lower.contains($0) }
        }
    }
}
