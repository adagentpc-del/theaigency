import Foundation

/// Common shape for the closed-choice answers below, so the context step
/// UI can render any of them with one generic picker view.
protocol QuickChoiceOption: Identifiable, Hashable {
    var title: String { get }
}

/// Step 3, Option B — a few structured questions instead of a pasted
/// conversation. Because these are closed-choice answers rather than free
/// text, the judgment engine can treat them as reliable, deterministic
/// signals (see `ContextSignals`) instead of guessing at meaning.
enum WhoTextedLast: String, Codable, CaseIterable, Identifiable, Hashable, QuickChoiceOption {
    case me
    case him
    case notSure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .me: return "Me"
        case .him: return "Him"
        case .notSure: return "Not sure / mutual"
        }
    }
}

enum TimeSinceLastMessage: String, Codable, CaseIterable, Identifiable, Hashable, QuickChoiceOption {
    case underAnHour
    case today
    case oneToThreeDays
    case fourPlusDays

    var id: String { rawValue }

    var title: String {
        switch self {
        case .underAnHour: return "Under an hour"
        case .today: return "Today"
        case .oneToThreeDays: return "1–3 days"
        case .fourPlusDays: return "4+ days"
        }
    }
}

enum DidHeRespond: String, Codable, CaseIterable, Identifiable, Hashable, QuickChoiceOption {
    case yes
    case no
    case sortOf
    case noQuestion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yes: return "Yes"
        case .no: return "No"
        case .sortOf: return "Sort of"
        case .noQuestion: return "There wasn't a question"
        }
    }
}

struct QuickContext: Codable, Equatable, Hashable {
    var whoTextedLast: WhoTextedLast
    var timeSinceLastMessage: TimeSinceLastMessage
    var didHeRespond: DidHeRespond
    /// Short, optional free text. Only ever scanned for safety and for a
    /// small, explicitly-documented set of self-reported repetition
    /// phrases (see `ContextSignals`) — never used for general tone
    /// analysis, to avoid re-growing a brittle keyword list.
    var additionalNotes: String
}
