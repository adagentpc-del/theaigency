import Foundation

/// Deterministic, message-level tone signals extracted from the proposed
/// text alone — no context, no goal. This is "layer 2a" of the judgment
/// architecture: obvious, bounded, testable signal extraction. It answers
/// "how does this message read on its own," not "should it be sent" —
/// that combination happens in `DeterministicJudgmentRules`.
struct MessageSignals: Equatable {
    let wordCount: Int
    let angerScore: Int
    let anxietyScore: Int
    let bigDecisionScore: Int
    let warmthScore: Int
    let endsWithQuestion: Bool

    private static let angerTerms = [
        "hate you", "you always", "you never", "i'm so done", "i am so done",
        "screw you", "f*** you", "fuck you", "idiot", "pathetic", "grow up",
        "what is wrong with you", "you're unbelievable", "you are unbelievable"
    ]

    /// A small, explicitly-scoped set of passive-aggressive markers,
    /// scored as a form of anger rather than as their own category —
    /// deliberately narrow rather than an attempt at general sarcasm
    /// detection.
    private static let passiveAggressiveTerms = [
        "must be nice", "must be so busy", "must be busy", "no worries i guess",
        "cool, cool, cool", "guess i'll just", "whatever, it's fine"
    ]

    private static let anxietyPhrases = [
        "please respond", "please answer", "please reply", "did you see my last",
        "did you see this", "are you ignoring me", "why haven't you",
        "you read my message", "left on read", "i know you saw this",
        "hello?", "u there", "you there"
    ]

    /// Late-night / impulsive-send markers — scored into anxiety rather
    /// than treated as a separate category, since the product response
    /// (rewrite/sleep on it) is the same either way.
    private static let impulsiveTerms = [
        "it's 2am", "it's 3am", "it's 4am", "i know it's late",
        "probably a bad idea", "i shouldn't be texting", "can't sleep and",
        "i've had a few drinks", "i'm a little drunk"
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
        endsWithQuestion = text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("?")

        var anger = Self.angerTerms.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
        anger += Self.passiveAggressiveTerms.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
        let capsWordCount = words.filter { word in
            let letters = String(word.filter { $0.isLetter })
            return letters.count >= 3 && letters == letters.uppercased() && letters != letters.lowercased()
        }.count
        if capsWordCount >= 2 { anger += 1 }
        let exclamationRun = text.contains("!!") || text.filter { $0 == "!" }.count >= 3
        if exclamationRun { anger += 1 }
        angerScore = anger

        var anxiety = Self.anxietyPhrases.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
        anxiety += Self.impulsiveTerms.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
        let questionMarkCount = text.filter { $0 == "?" }.count
        if questionMarkCount >= 3 { anxiety += 1 }
        let sorryCount = lower.components(separatedBy: "sorry").count - 1
        if sorryCount >= 3 { anxiety += 1 }
        anxietyScore = anxiety

        bigDecisionScore = Self.bigDecisionPhrases.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
        warmthScore = Self.warmthTerms.reduce(0) { lower.contains($1) ? $0 + 1 : $0 }
    }
}
