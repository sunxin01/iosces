import Foundation
import Combine

final class MomentStore: ObservableObject {
    @Published private(set) var moments: [Moment] = []

    private let fileURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("moments.json")
    }()

    init() {
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            moments = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Moment].self, from: data) {
            moments = decoded.sorted { $0.date > $1.date }
        } else {
            moments = []
        }
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(moments) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func add(_ moment: Moment) {
        moments.append(moment)
        moments.sort { $0.date > $1.date }
        save()
    }

    func update(_ moment: Moment) {
        guard let idx = moments.firstIndex(where: { $0.id == moment.id }) else { return }
        moments[idx] = moment
        moments.sort { $0.date > $1.date }
        save()
    }

    func delete(_ moment: Moment) {
        for name in moment.imageFilenames {
            ImageStore.delete(name)
        }
        moments.removeAll { $0.id == moment.id }
        save()
    }

    func deleteAll() {
        for m in moments {
            for name in m.imageFilenames {
                ImageStore.delete(name)
            }
        }
        moments = []
        save()
    }
}
