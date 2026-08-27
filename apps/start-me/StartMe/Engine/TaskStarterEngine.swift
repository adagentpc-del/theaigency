import Foundation

/// Turns free-form task text into one tiny, smaller-than-the-task first
/// action. This is the entire "product" of Start Me: do not plan the task,
/// start the task.
struct TaskStarterEngine {
    private let safetyRouter: SafetyRouter

    init(safetyRouter: SafetyRouter = SafetyRouter()) {
        self.safetyRouter = safetyRouter
    }

    /// The canonical starter action for a freshly typed task. Deterministic
    /// per category so the same kind of task reliably produces the same
    /// well-tested first step; use `alternateAction` for variety.
    func starterAction(for rawInput: String) -> StarterAction {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if safetyRouter.isUnsafe(input) {
            return safetyRouter.safeFallbackAction
        }
        let category = classify(input)
        if category == .general {
            return generalFallback(for: input)
        }
        guard let first = StarterActionLibrary.entries[category]?.first else {
            return generalFallback(for: input)
        }
        return StarterAction(
            primaryAction: first.primary,
            reassurance: first.reassurance,
            smallerActions: first.reductions,
            category: category
        )
    }

    /// A different tiny first action in the same category as `current`,
    /// avoiding an immediate repeat where possible.
    func alternateAction(current: StarterAction, originalInput: String) -> StarterAction {
        if safetyRouter.isUnsafe(originalInput) {
            return safetyRouter.safeFallbackAction
        }
        guard let entries = StarterActionLibrary.entries[current.category], entries.count > 1 else {
            return current
        }
        let candidates = entries.filter { $0.primary != current.primaryAction }
        guard let choice = candidates.randomElement() ?? entries.first(where: { $0.primary != current.primaryAction }) else {
            return current
        }
        return StarterAction(
            primaryAction: choice.primary,
            reassurance: choice.reassurance,
            smallerActions: choice.reductions,
            category: current.category
        )
    }

    /// Compact, substring-based local classifier. Not a keyword engine meant
    /// to cover every phrasing — just enough to route to a good default, with
    /// `.general` as a safe, still-useful fallback for anything unmatched.
    func classify(_ input: String) -> TaskCategory {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return .general }
        let padded = " " + trimmed + " "
        for (category, keywords) in Self.classificationRules {
            for keyword in keywords where padded.contains(keyword) {
                return category
            }
        }
        return .general
    }

    /// Two shapes of "unknown" fallback:
    /// - The remainder reads as an actual noun phrase ("the Johnson thing")
    ///   -> the dynamic "Open whatever you need to work on X" sentence.
    /// - Anything else (reflexive slang like "get my shit together", or
    ///   just a bare vague word) -> a generic tiny-start library entry,
    ///   rather than forcing an ungrammatical object onto the template.
    private func generalFallback(for input: String) -> StarterAction {
        if let phrase = Self.fallbackObjectPhrase(from: input) {
            return StarterAction(
                primaryAction: "Open whatever you need to work on \(phrase).",
                reassurance: "Don't finish it. Just open it.",
                smallerActions: ["Find where it is.", "Stand up."],
                category: .general
            )
        }
        let entry = StarterActionLibrary.entries[.general]?.first
        return StarterAction(
            primaryAction: entry?.primary ?? "Do the smallest visible piece.",
            reassurance: entry?.reassurance ?? "The smallest piece counts.",
            smallerActions: entry?.reductions ?? [],
            category: .general
        )
    }

    /// Builds the "the Johnson thing" half of the general fallback sentence,
    /// stripping common lead-in verbs while preserving the user's own
    /// casing. Returns `nil` when what's left doesn't read as a noun phrase
    /// (no article/possessive), so the caller falls back to a library entry
    /// instead of producing something ungrammatical.
    static func fallbackObjectPhrase(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var remainder = trimmed
        var changed = true
        while changed {
            changed = false
            for phrase in leadInPhrases where remainder.lowercased().hasPrefix(phrase) {
                remainder = String(remainder.dropFirst(phrase.count))
                changed = true
            }
        }

        let cleaned = remainder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let lowerCleaned = cleaned.lowercased()
        let nounPhraseStarters = ["the ", "a ", "an ", "my ", "our ", "his ", "her ", "their "]
        guard nounPhraseStarters.contains(where: { lowerCleaned.hasPrefix($0) }) else { return nil }
        return cleaned
    }

    private static let leadInPhrases: [String] = [
        "i need to ", "i have to ", "i've got to ", "i gotta ",
        "finish ", "work on ", "handle ", "deal with ",
        "get through ", "sort out ", "do "
    ]

    private static let classificationRules: [(TaskCategory, [String])] = [
        (.taxes, [" tax", "taxes", " irs "]),
        (.laundry, ["laundry", "washer", "dryer"]),
        (.dishes, ["dish", "dishes", "the sink"]),
        (.studying, ["study", "studying", "homework", "essay", " exam", "textbook", "assignment", "thesis", "flashcard", "read the chapter"]),
        (.writing, ["résumé", "resume", "cover letter", " write ", "writing", "draft a", "blog post", "an article", "my article"]),
        (.email, ["email", "e-mail", "inbox"]),
        (.admin, ["paperwork", " admin", "insurance", " dmv", "renew my", "application", "the bill", "my bills", "invoice", "fill out", "the forms", " a form"]),
        (.workout, [" gym", "workout", "work out", "exercise", "for a run", "go running", " jog", " yoga", " lift ", "cardio", " walk"]),
        (.leavingHouse, ["leave the house", "get out of the house", "get ready to leave", "walk out the door"]),
        (.packing, [" pack ", "packing", "suitcase", "luggage", " travel"]),
        (.cooking, [" cook ", "cooking", " dinner", "meal prep", " recipe", " bake", "baking"]),
        (.errands, ["errand", " grocery", "groceries", "shopping", "post office", "the bank", " the store"]),
        (.phoneCall, ["phone call", " call ", "voicemail", "phone number"]),
        (.organizing, ["organize", "organizing", "declutter", " closet", " garage", "my desk"]),
        (.computerWork, ["spreadsheet", "presentation", "slide deck", "the deck", " code", "coding", " project", " report"]),
        (.personalCare, [" shower", "brush my teeth", "skincare", "get dressed", "self care", "self-care"]),
        (.cleaning, [" clean", " tidy", "declutter", " vacuum", " mop", " kitchen", "bathroom", "bedroom", "living room", "the mess"])
    ]
}
