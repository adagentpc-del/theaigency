import Foundation
import Combine

/// The only two persisted user preferences Start Me needs: whether haptics
/// are on, and (indirectly, via `StatsStore`) local data. Kept deliberately
/// tiny — see docs/PRODUCT_SPEC.md, "Keep Settings small."
final class SettingsStore: ObservableObject {
    private let defaults: UserDefaults
    private static let hapticsEnabledKey = "startme.settings.hapticsEnabled.v1"

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Self.hapticsEnabledKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Self.hapticsEnabledKey) == nil {
            self.hapticsEnabled = true
        } else {
            self.hapticsEnabled = defaults.bool(forKey: Self.hapticsEnabledKey)
        }
    }
}
