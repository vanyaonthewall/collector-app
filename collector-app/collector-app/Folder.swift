import Foundation
import SwiftData

@Model
class Folder {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var items: [CollectionItem] = []

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
