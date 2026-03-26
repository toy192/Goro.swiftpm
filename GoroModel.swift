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

    struct DigitItem: Identifiable {
        let id: Int
        let digit: Character
    }

    static func digitItems(from number: String) -> [DigitItem] {
        number.filter { $0.isNumber }
            .enumerated()
            .map { DigitItem(id: $0.offset, digit: $0.element) }
    }
}
