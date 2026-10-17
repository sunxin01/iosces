import Foundation

struct Moment: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var note: String
    var date: Date
    var mood: Mood
    var location: String
    var imageFilenames: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        date: Date = Date(),
        mood: Mood = .happy,
        location: String = "",
        imageFilenames: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.date = date
        self.mood = mood
        self.location = location
        self.imageFilenames = imageFilenames
        self.createdAt = createdAt
    }
}
