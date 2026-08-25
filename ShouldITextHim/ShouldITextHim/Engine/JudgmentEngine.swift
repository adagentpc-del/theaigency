import Foundation

/// The core "judge my text" logic.
///
/// This is a deterministic, on-device heuristic engine — not a network call
/// to a model. See DECISIONS.md for why: it lets the first release ship
/// with zero backend, zero API keys, zero network access, and zero data
/// leaving the device, while still delivering the product's real promise.
/// A cloud-AI upgrade path is documented in POST_LAUNCH.md and
/// API_CONTRACT.md for when/if it's actually needed.
enum JudgmentEngine {

    /// Judges a single message and returns a structured result.
    /// Safety routing always takes priority over the normal heuristic.
    static func judge(_ rawText: String) -> JudgmentResult {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)

        let riskFlags = SafetyScanner.scan(text)
        if !riskFlags.isEmpty {
            return SafetyScanner.safeResponse(for: riskFlags)
        }

        let signals = Signals(text: text)

        if signals.bigDecisionScore > 0 {
            return JudgmentResult(
                verdict: .sleep,
                reason: "This reads like a big-relationship-decision text, not a quick one. Sleep on it and see if it still feels true tomorrow.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if signals.angerScore >= 2 {
            return JudgmentResult(
                verdict: .dontSend,
                reason: "This is coming from anger, not clarity. You'll want different words once you've cooled off.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if signals.anxietyScore >= 3 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "This reads a little anxious — lots of pressure, not much confidence. Say less and let it breathe.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if signals.wordCount > 120 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "This is a lot of message for a text. Trim it to the one thing you actually want them to know.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if signals.angerScore == 1 || signals.anxietyScore == 2 {
            return JudgmentResult(
                verdict: .rewrite,
                reason: "The core of this is fine, the delivery needs a pass. Tighten the tone before it goes out.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        if signals.warmthScore > 0 {
            return JudgmentResult(
                verdict: .send,
                reason: "Clear, low-drama, and says what you mean. Send it.",
                riskFlags: [],
                isSafetyRouted: false
            )
        }

        return JudgmentResult(
            verdict: .send,
            reason: "Nothing here is going to blow up in your face. Send it.",
            riskFlags: [],
            isSafetyRouted: false
        )
    }

    /// Extracted numeric signals used to decide a verdict. Internal so it
    /// stays unit-testable without exposing engine internals to the UI.
    struct Signals: Equatable {
        let wordCount: Int
        let angerScore: Int
        let anxietyScore: Int
        let bigDecisionScore: Int
        let warmthScore: Int

        private static let angerTerms = [
            "hate you", "you always", "you never", "i'm so done", "i am so done",
            "screw you", "f*** you", "fuck you", "idiot", "pathetic", "grow up",
            "what is wrong with you", "you're unbelievable", "you are unbelievable"
        ]

        private static let anxietyPhrases = [
            "please respond", "please answer", "please reply", "did you see my last",
            "did you see this", "are you ignoring me", "why haven't you",
            "you read my message", "left on read", "i know you saw this",
            "hello?", "u there", "you there"
        ]

        private static let bigDecisionPhrases = [
            "we need to talk", "i think we should break up", "this isn't working",
            "this is over", "i can't do this anymore", "i cant do this anymore",
            "we're done", "we are done", "i want to break up", "let's break up",
            "lets break up", "i don't think we should see each other"
        ]

        private static let warmthTerms = [
            "miss you", "can't wait", "cant wait", "had fun", "thank you",
            "thanks for", "made me smile", "made my day", "hope you're doing well",
            "hope you are doing well"
        ]

        init(text: String) {
            let lower = text.lowercased()
            let words = text.split { $0.isWhitespace || $0.isNewline }
            wordCount = words.count

            var anger = Self.angerTerms.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
            let capsWordCount = words.filter { word in
                let letters = String(word.filter { $0.isLetter })
                return letters.count >= 3 && letters == letters.uppercased() && letters != letters.lowercased()
            }.count
            if capsWordCount >= 2 { anger += 1 }
            let exclamationRun = text.contains("!!") || text.filter { $0 == "!" }.count >= 3
            if exclamationRun { anger += 1 }
            angerScore = anger

            var anxiety = Self.anxietyPhrases.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
            let questionMarkCount = text.filter { $0 == "?" }.count
            if questionMarkCount >= 3 { anxiety += 1 }
            let sorryCount = lower.components(separatedBy: "sorry").count - 1
            if sorryCount >= 3 { anxiety += 1 }
            anxietyScore = anxiety

            bigDecisionScore = Self.bigDecisionPhrases.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
            warmthScore = Self.warmthTerms.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
        }
    }
}
