import Foundation

/// Deterministic, template-based rewrite suggestions keyed by the user's
/// stated intent. This intentionally does not attempt to parse or rewrite
/// the user's original wording — it offers three ready-to-edit starting
/// points in a clearly different tone (direct, warm, playful) so the user
/// can pick the one closest to their voice and adjust it themselves.
enum RewriteEngine {

    /// Returns up to 3 rewrite options for the given intent.
    static func options(for intent: Intent) -> [RewriteOption] {
        templates[intent, default: []].map { RewriteOption(text: $0) }
    }

    private static let templates: [Intent: [String]] = [
        .flirt: [
            "Been thinking about you today — what are you up to this week?",
            "Ok not to be dramatic but that was a great time. When are we doing it again?",
            "You've been living in my head rent-free since [event]. Coffee soon?"
        ],
        .makePlans: [
            "Are you free [day]? Want to do [activity] if you're in.",
            "Locking in plans — [day] or [day], which works better for you?",
            "No pressure, just checking: still on for [day]?"
        ],
        .getClarity: [
            "Hey, I want to make sure I'm reading this right — where do you see this going?",
            "Not trying to make it a whole thing, I just want to know where we stand.",
            "Can we talk for a sec? I have a question and I'd rather just ask than guess."
        ],
        .apologize: [
            "I was out of line earlier and I'm sorry. That's on me.",
            "I've been thinking about what I said and I want to apologize — I didn't mean it the way it came out.",
            "Sorry for [what happened]. I should have handled that differently."
        ],
        .setBoundary: [
            "I need us to slow down on [thing]. Can we talk about that?",
            "I'm not comfortable with [thing] and I want to be upfront about that instead of letting it slide.",
            "Just so we're clear going forward: [boundary]. Wanted to say it directly."
        ],
        .getClosure: [
            "I don't need a long conversation, I just want an honest answer: [question].",
            "I think we both know this has run its course. I just wanted to say that clearly instead of fading out.",
            "No hard feelings either way, I'd just like to know where things actually ended up."
        ],
        .sayLess: [
            "[trimmed to one sentence — say the one thing that matters and stop]",
            "Hey — [the actual point]. Talk soon.",
            "[core message only, no justification, no apology, no extra context]"
        ]
    ]
}
