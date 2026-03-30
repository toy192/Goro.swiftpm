import Foundation

struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let inputNumber: String
    let result: String
    let mergedGroups: [String: Int]
    let selectedReadings: [String: String]
    let customWords: [String: String]
}

class HistoryStore: ObservableObject {
    @Published var items: [HistoryItem] = []

    private let key = "gorobell_history"

    init() { load() }

    func add(inputNumber: String, result: String,
             mergedGroups: [Int: Int],
             selectedReadings: [Int: String],
             customWords: [Int: String]) {
        let item = HistoryItem(
            id: UUID(),
            date: Date(),
            inputNumber: inputNumber,
            result: result,
            mergedGroups: Dictionary(uniqueKeysWithValues: mergedGroups.map { (String($0.key), $0.value) }),
            selectedReadings: Dictionary(uniqueKeysWithValues: selectedReadings.map { (String($0.key), $0.value) }),
            customWords: Dictionary(uniqueKeysWithValues: customWords.map { (String($0.key), $0.value) })
        )
        items.insert(item, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    // Int キーに変換して返す
    func intMergedGroups(_ item: HistoryItem) -> [Int: Int] {
        Dictionary(uniqueKeysWithValues: item.mergedGroups.compactMap {
            guard let k = Int($0.key) else { return nil }
            return (k, $0.value)
        })
    }
    func intSelectedReadings(_ item: HistoryItem) -> [Int: String] {
        Dictionary(uniqueKeysWithValues: item.selectedReadings.compactMap {
            guard let k = Int($0.key) else { return nil }
            return (k, $0.value)
        })
    }
    func intCustomWords(_ item: HistoryItem) -> [Int: String] {
        Dictionary(uniqueKeysWithValues: item.customWords.compactMap {
            guard let k = Int($0.key) else { return nil }
            return (k, $0.value)
        })
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([HistoryItem].self, from: data)
        else { return }
        items = saved
    }
}
