import SwiftUI
import UIKit

/// Small, centralized style constants. Deliberately thin — this app has
/// four screens, not a design system.
enum Theme {
    /// Distinct color per verdict. Never the *only* signal for meaning —
    /// every verdict also has a headline string and a symbol.
    static func color(for verdict: Verdict) -> Color {
        switch verdict {
        case .send: return .green
        case .rewrite: return .orange
        case .sleep: return .blue
        case .dontSend: return .red
        case .needContext: return .purple
        }
    }

    static let cornerRadius: CGFloat = 20
    static let minimumTapTarget: CGFloat = 44
}

extension View {
    /// Respects Reduce Motion by disabling the transition/animation
    /// entirely rather than substituting a "lesser" animation, per Apple's
    /// guidance that Reduce Motion means motion should stop, not shrink.
    @ViewBuilder
    func reduceMotionAware(_ animation: Animation?, value: some Equatable) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }
}
