import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Thin haptic wrapper. Haptics are a bonus channel only — nothing in the
/// app relies on feeling a haptic to understand state, so this has no
/// effect on accessibility or Reduce Motion compliance.
enum Haptics {
    static func verdictRevealed(for verdict: Verdict) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        switch verdict {
        case .send:
            generator.notificationOccurred(.success)
        case .rewrite, .sleep:
            generator.notificationOccurred(.warning)
        case .dontSend:
            generator.notificationOccurred(.error)
        }
        #endif
    }

    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
