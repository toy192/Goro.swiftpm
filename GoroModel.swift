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

    // 2〜3桁の組み合わせに対する覚えやすい候補
    static let suggestions: [String: [String]] = [
        // 2桁
        "14": ["石", "医師"],
        "17": ["稲"],
        "19": ["行く", "育"],
        "24": ["西"],
        "29": ["肉"],
        "31": ["妻", "才", "祭"],
        "36": ["寒"],
        "39": ["咲く", "桜"],
        "43": ["染み"],
        "45": ["仕事"],
        "47": ["品"],
        "49": ["敷く"],
        "56": ["ゴム"],
        "58": ["ご飯"],
        "64": ["虫"],
        "67": ["胸"],
        "72": ["何"],
        "73": ["波", "並み"],
        "74": ["梨", "無し"],
        "79": ["泣く", "鳴く"],
        "81": ["灰", "肺"],
        "84": ["橋", "箸"],
        "86": ["ハム"],
        "87": ["花", "鼻", "話"],
        "88": ["母"],
        "89": ["履く", "吐く"],
        "91": ["杭", "悔い"],
        "92": ["国"],
        "93": ["草", "臭い"],
        "94": ["串"],
        // 3桁
        "168": ["いろは"],
        "291": ["憎い"],
        "312": ["財布"],
        "319": ["細工"],
        "473": ["品々"],
        "583": ["嫌み"],
        "749": ["梨食う"],
        "894": ["白紙", "博士"],
    ]

    struct GroupItem: Identifiable {
        let id: Int
        let digits: [Character]
        var isMerged: Bool { digits.count > 1 }
        var digitKey: String { String(digits) }
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
