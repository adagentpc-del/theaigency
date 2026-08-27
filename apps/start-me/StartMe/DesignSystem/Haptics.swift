import UIKit

enum HapticEvent {
    case timerStart
    case timerComplete
    case tap
}

/// Thin wrapper over UIKit's feedback generators. Respects the user's
/// Settings > Haptics toggle; does not attempt to infer or override
/// Reduce Motion (haptics and motion are separate accessibility settings).
struct HapticsPlayer {
    var isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func play(_ event: HapticEvent) {
        guard isEnabled else { return }
        switch event {
        case .timerStart:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .timerComplete:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .tap:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
