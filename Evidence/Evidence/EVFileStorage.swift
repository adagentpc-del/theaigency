import Foundation
import UIKit

enum EVFileStorage {
    private static var fileURL: URL? {
        let manager = FileManager.default
        guard let root = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let directory = root.appendingPathComponent("Evidence", isDirectory: true)
        try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("vault.json")
    }

    static func save<T: Encodable>(_ value: T) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(value) else { return }
        do {
            try data.write(to: url, options: .atomic)
            try? FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        } catch {
            return
        }
    }

    static func load<T: Decodable>(_ type: T.Type) -> T? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

enum EVImagePipeline {
    static func normalizedJPEG(_ data: Data?) -> Data? {
        guard let data, let image = UIImage(data: data) else { return data }
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > 0 else { return data }
        let scale = min(1, 1800 / largestSide)
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return rendered.jpegData(compressionQuality: 0.88) ?? data
    }
}
