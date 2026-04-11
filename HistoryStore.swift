import Foundation

struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let date: Date
    let inputNumber: String
    let result: String
    let mergedGroups: [String: Int]
    let selectedReadings: [String: String]
    let customWords: [String: String]
    var comment: String

    init(id: UUID = UUID(), date: Date = Date(),
         inputNumber: String, result: String,
         mergedGroups: [String: Int], selectedReadings: [String: String],
         customWords: [String: String], comment: String = "") {
        self.id = id
        self.date = date
        self.inputNumber = inputNumber
        self.result = result
        self.mergedGroups = mergedGroups
        self.selectedReadings = selectedReadings
        self.customWords = customWords
        self.comment = comment
    }

    // 旧データとの互換性のため comment を省略可能にデコード
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        inputNumber = try c.decode(String.self, forKey: .inputNumber)
        result = try c.decode(String.self, forKey: .result)
        mergedGroups = try c.decode([String: Int].self, forKey: .mergedGroups)
        selectedReadings = try c.decode([String: String].self, forKey: .selectedReadings)
        customWords = try c.decode([String: String].self, forKey: .customWords)
        comment = (try? c.decode(String.self, forKey: .comment)) ?? ""
    }
}

class HistoryStore: ObservableObject {
    @Published var items: [HistoryItem] = []

    private let key = "gorobell_history"

    init() { load() }

    func add(inputNumber: String, result: String,
             mergedGroups: [Int: Int],
             selectedReadings: [Int: String],
             customWords: [Int: String],
             comment: String = "") {
        let item = HistoryItem(
            inputNumber: inputNumber,
            result: result,
            mergedGroups: Dictionary(uniqueKeysWithValues: mergedGroups.map { (String($0.key), $0.value) }),
            selectedReadings: Dictionary(uniqueKeysWithValues: selectedReadings.map { (String($0.key), $0.value) }),
            customWords: Dictionary(uniqueKeysWithValues: customWords.map { (String($0.key), $0.value) }),
            comment: comment
        )
        items.insert(item, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    // 履歴からユーザー独自の候補を digitKey → [word] で返す
    var userSuggestions: [String: [String]] {
        var result: [String: [String]] = [:]
        for item in items {
            let mg = intMergedGroups(item)
            let cw = intCustomWords(item)
            let groups = GoroModel.groupItems(from: item.inputNumber, mergedGroups: mg)
            for group in groups {
                if let word = cw[group.id], !word.isEmpty {
                    if result[group.digitKey] == nil { result[group.digitKey] = [] }
                    if !result[group.digitKey]!.contains(word) {
                        result[group.digitKey]!.append(word)
                    }
                }
            }
        }
        return result
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
