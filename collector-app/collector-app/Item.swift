import Foundation
import SwiftData

@Model
class CollectionItem {
    var id: UUID
    var createdAt: Date
    var folder: Folder?

    init(folder: Folder? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.folder = folder
    }

    var imageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("items/\(id.uuidString).png")
    }
}
