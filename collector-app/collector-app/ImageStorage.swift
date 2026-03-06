import UIKit

enum ImageStorageError: Error {
    case encodingFailed
    case directoryCreationFailed
}

struct ImageStorage {
    private static var itemsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("items", isDirectory: true)
    }

    static func save(_ image: UIImage, id: UUID) throws {
        let dir = itemsDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = image.pngData() else { throw ImageStorageError.encodingFailed }
        try data.write(to: dir.appendingPathComponent("\(id.uuidString).png"), options: .atomic)
    }

    static func load(id: UUID) -> UIImage? {
        let url = itemsDirectory.appendingPathComponent("\(id.uuidString).png")
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(id: UUID) throws {
        let url = itemsDirectory.appendingPathComponent("\(id.uuidString).png")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
