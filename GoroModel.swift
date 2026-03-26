import Foundation

struct GoroModel {
    static let readings: [Character: [String]] = [
        "0": ["れ", "ぜ", "お", "まる"],
        "1": ["い", "ひ", "いち"],
        "2": ["に", "ふ", "ふた"],
        "3": ["さ", "み", "さん"],
        "4": ["し", "よ", "よん"],
        "5": ["ご", "いつ"],
        "6": ["む", "ろ", "りく"],
        "7": ["な", "しち", "なな"],
        "8": ["は", "や", "はち"],
        "9": ["く", "きゅ", "こ"],
    ]

    struct GroupItem: Identifiable {
        let id: Int           // 先頭の絶対インデックス
        let digits: [Character]
        var isMerged: Bool { digits.count > 1 }
    }

    static func groupItems(from number: String, mergedPairs: Set<Int>) -> [GroupItem] {
        let chars = Array(number.filter { $0.isNumber })
        var items: [GroupItem] = []
        var i = 0
        while i < chars.count {
            if mergedPairs.contains(i), i + 1 < chars.count {
                items.append(GroupItem(id: i, digits: [chars[i], chars[i + 1]]))
                i += 2
            } else {
                items.append(GroupItem(id: i, digits: [chars[i]]))
                i += 1
            }
        }
        return items
    }
}
