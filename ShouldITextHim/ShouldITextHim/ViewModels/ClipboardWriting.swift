import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Abstraction over the system clipboard so the view model stays unit
/// testable without pulling in UIKit in the test target.
protocol ClipboardWriting {
    func write(_ text: String)
}

#if canImport(UIKit)
struct SystemClipboard: ClipboardWriting {
    func write(_ text: String) {
        UIPasteboard.general.string = text
    }
}
#else
struct SystemClipboard: ClipboardWriting {
    func write(_ text: String) {
        // No-op outside iOS; kept so the type still exists for non-UIKit
        // builds/tooling.
    }
}
#endif
