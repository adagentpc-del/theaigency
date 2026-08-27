import Foundation

/// Which completion screen to show: the end of the initial 60 seconds, or
/// the end of a 5-minute "keep going" continuation.
enum CompletionContext: Equatable {
    case initial
    case continuation
}
