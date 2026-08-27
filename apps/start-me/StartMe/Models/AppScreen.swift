import Foundation

/// The app's single linear flow, modeled as one screen at a time rather than
/// a navigation stack — Start Me is deliberately one-directional:
/// home -> starter -> timer -> completion (-> home).
enum AppScreen: Equatable {
    case home
    case starter(originalInput: String)
    case timer(session: TimerSession, contextLabel: String)
    case completion(context: CompletionContext, contextLabel: String)
}
