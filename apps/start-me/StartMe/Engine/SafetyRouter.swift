import Foundation

/// A small, deterministic, fully local safety layer.
///
/// Start Me turns free-form task text into an actionable physical first step.
/// If the typed-in text clearly involves self-harm, harming someone else, or
/// another dangerous/illegal act, it must never be turned into an actionable
/// starter step. This is a keyword-based scan — not a moderation backend, not
/// a classifier, and not a crisis-detection system. See `docs/SAFETY.md` for
/// the reasoning and its limits.
struct SafetyRouter {
    /// Returned whenever `isUnsafe` matches. Deliberately generic: it does not
    /// echo the user's text back, and it does not attempt to counsel, diagnose,
    /// or triage — it declines and points toward real help.
    let safeFallbackAction = StarterAction(
        primaryAction: "That's not something this app can help start.",
        reassurance: "If you or someone else may be in danger, please contact local emergency services or a crisis line.",
        smallerActions: [],
        category: .general
    )

    func isUnsafe(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let normalized = " " + trimmed.lowercased() + " "
        return Self.triggerPhrases.contains { normalized.contains($0) }
    }

    /// Deterministic, hand-reviewed trigger phrases. Intentionally short and
    /// conservative — the goal is to catch clear, unambiguous cases, not to
    /// interpret intent. See docs/SAFETY.md before editing this list.
    static let triggerPhrases: [String] = [
        "kill myself",
        "end my life",
        "end it all",
        "suicide",
        "self harm",
        "self-harm",
        "hurt myself",
        "harm myself",
        "kill him",
        "kill her",
        "kill them",
        "kill my",
        "murder",
        "hurt him",
        "hurt her",
        "hurt them",
        "hurt someone",
        "attack someone",
        "attack him",
        "attack her",
        "make a bomb",
        "build a bomb",
        "shoot up",
        "shoot him",
        "shoot her",
        "shoot them",
        "hack into",
        "stalk my",
        "stalk him",
        "stalk her",
        "poison someone",
        "poison him",
        "poison her"
    ]
}
