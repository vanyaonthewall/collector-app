import Foundation
import SwiftData

@Model
class Folder {
    var name: String
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}
