import SwiftUI

struct ContentView: View {
    @StateObject private var historyStore = HistoryStore()
    @State private var inputNumber = ""
    @State private var mergedGroups: [Int: Int] = [:]  // 開始インデックス → グループサイズ
    @State private var selectedReadings: [Int: String] = [:]
    @State private var customWords: [Int: String] = [:]
    @State private var copied = false
    @State private var saved = false
    @State private var showingHistory = false
    @State private var showingHelp = false
    @State private var showingResistor = false
    @State private var showingBase493 = false

    var groupItems: [GoroModel.GroupItem] {
        GoroModel.groupItems(from: inputNumber, mergedGroups: mergedGroups)
    }

    func groupReading(_ group: GoroModel.GroupItem) -> String {
        group.digits.enumerated().map { offset, digit in
            selectedReadings[group.id + offset]
                ?? GoroModel.readings[digit]?.first
                ?? String(digit)
        }.joined()
    }

    var isMyNumber: Bool {
        let digits = inputNumber.filter { $0.isNumber }
        return digits.count == 12 && !inputNumber.contains("-")
    }

    var isPhoneNumber: Bool {
        let digits = inputNumber.filter { $0.isNumber }
        guard digits.count == 11 && !inputNumber.contains("-") else { return false }
        let prefix = String(digits.prefix(3))
        return ["090", "080", "070"].contains(prefix)
    }

    var isLandline: Bool {
        let digits = inputNumber.filter { $0.isNumber }
        guard digits.count == 10 && !inputNumber.contains("-") else { return false }
        return digits.hasPrefix("0")
    }

    // 固定電話のグループ: 4+2+4
    var landlineGroups: [Int: Int] { [0: 4, 4: 2, 6: 4] }

    var result: String {
        let words = groupItems.map { group in
            let word = customWords[group.id] ?? ""
            return word.isEmpty ? groupReading(group) : word
        }
        return words.joined(separator: (isMyNumber || isPhoneNumber || isLandline) ? " " : "")
    }

    var numberBase493: String {
        let digits = inputNumber.filter { $0.isNumber }
        guard !digits.isEmpty else { return "" }
        // 先頭ゼロを保持: 各先頭ゼロをアルファベット[0]('0')で表現
        let leadingZeroCount = digits.prefix(while: { $0 == "0" }).count
        let leadingPrefix = String(repeating: String(shortHashAlphabet[0]), count: leadingZeroCount)
        let rest = String(digits.drop(while: { $0 == "0" }))
        guard !rest.isEmpty else { return leadingPrefix }
        guard let value = UInt64(rest) else { return "" }
        let base = UInt64(shortHashAlphabet.count)
        var n = value
        var result: [Character] = []
        while n > 0 {
            result.append(shortHashAlphabet[Int(n % base)])
            n /= base
        }
        return leadingPrefix + String(result.reversed())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("GoroBell")
                        .foregroundColor(.orange)
                        .font(.system(size: 24, weight: .bold))
                    Spacer()
                    Button {
                        showingBase493.toggle()
                    } label: {
                        Text("B493")
                            .foregroundColor(showingBase493 ? .orange : Color(white: 0.6))
                            .font(.system(size: 14, weight: .bold))
                    }
                    Button {
                        showingResistor.toggle()
                    } label: {
                        Text("Ω")
                            .foregroundColor(showingResistor ? .orange : Color(white: 0.6))
                            .font(.system(size: 22, weight: .bold))
                    }
                    Button {
                        showingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(Color(white: 0.6))
                            .font(.title2)
                    }
                    Button {
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(historyStore.items.isEmpty ? Color(white: 0.4) : .orange)
                            .font(.title2)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                HStack(spacing: 12) {
                    TextField("数字を入力...", text: $inputNumber)
                        .keyboardType(.numbersAndPunctuation)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .onChange(of: inputNumber) {
                            // 数字とハイフン以外を除去
                            let stripped = inputNumber.filter { $0.isNumber || $0 == "-" }
                            let digits = stripped.filter { $0.isNumber }
                            let digitCount = digits.count
                            let hasHyphen = stripped.contains("-")
                            // ハイフンなしの場合はモードに応じてスペースを自動挿入
                            let formatted: String
                            if !hasHyphen {
                                var tmp = ""
                                for (i, c) in stripped.enumerated() {
                                    if digitCount == 11 {
                                        // 携帯番号モード: 3+4+4
                                        if i == 3 || i == 7 { tmp.append(" ") }
                                    } else if digitCount == 10 && stripped.hasPrefix("0") {
                                        // 固定電話モード: 4+2+4
                                        if i == 4 || i == 6 { tmp.append(" ") }
                                    } else {
                                        // デフォルト: 4桁ごと
                                        if i > 0 && i % 4 == 0 { tmp.append(" ") }
                                    }
                                    tmp.append(c)
                                }
                                formatted = tmp
                            } else {
                                formatted = stripped
                            }
                            if formatted != inputNumber { inputNumber = formatted }
                            mergedGroups = [:]
                            selectedReadings = [:]
                            customWords = [:]
                            // モード別自動グループ設定
                            if !hasHyphen {
                                if digitCount == 12 {
                                    mergedGroups = [0: 4, 4: 4, 8: 4]         // マイナンバー
                                } else if digitCount == 11 {
                                    let prefix = String(digits.prefix(3))
                                    if ["090", "080", "070"].contains(prefix) {
                                        mergedGroups = [0: 3, 3: 4, 7: 4]     // 携帯番号
                                    }
                                } else if digitCount == 10 && digits.hasPrefix("0") {
                                    mergedGroups = [0: 4, 4: 2, 6: 4]         // 固定電話(4+2+4)
                                }
                            }
                        }

                    if !inputNumber.isEmpty {
                        Button {
                            inputNumber = ""
                            mergedGroups = [:]
                            selectedReadings = [:]
                            customWords = [:]
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(white: 0.6))
                                .font(.title2)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if showingResistor && !inputNumber.isEmpty {
                    let numericDigits = Array(inputNumber.filter { $0.isNumber })
                    let groups = stride(from: 0, to: numericDigits.count, by: 4).map {
                        Array(numericDigits[$0..<min($0 + 4, numericDigits.count)])
                    }
                    let total = groups.compactMap { resistorRawValue(digits: $0) }.reduce(0, +)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                                VStack(spacing: 4) {
                                    HStack(spacing: 3) {
                                        ForEach(Array(group.enumerated()), id: \.offset) { _, digit in
                                            Text(String(digit))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(resistorTextColor(for: digit))
                                                .frame(width: 32, height: 48)
                                                .background(resistorColor(for: digit))
                                        }
                                    }
                                    .cornerRadius(4)
                                    if group.count >= 3 {
                                        Text(resistorValue(digits: group))
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            if groups.filter({ $0.count >= 3 }).count > 1 {
                                VStack(spacing: 4) {
                                    Text("合計")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.5))
                                    Text(formatResistance(total))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.yellow)
                                }
                                .padding(.leading, 4)
                                .frame(height: 48 + 4 + 16, alignment: .bottom)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                }

                if showingBase493 && !inputNumber.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        let digits = inputNumber.filter { $0.isNumber }
                        Text("base\(shortHashAlphabet.count)変換（可逆）: \(digits.count)桁 → \(numberBase493.count)文字")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 16)
                        Text(numberBase493)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 8)
                }

                if isMyNumber {
                    HStack(spacing: 6) {
                        Image(systemName: "person.text.rectangle")
                        Text("マイナンバーモード（4+4+4）")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(20)
                    .padding(.bottom, 8)
                } else if isPhoneNumber {
                    HStack(spacing: 6) {
                        Image(systemName: "iphone")
                        Text("携帯番号モード（3+4+4）")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.2, green: 0.7, blue: 0.4))
                    .cornerRadius(20)
                    .padding(.bottom, 8)
                } else if isLandline {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("固定電話モード（4+2+4）")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.4, green: 0.6, blue: 1.0))
                    .cornerRadius(20)
                    .padding(.bottom, 8)
                }

                if groupItems.isEmpty {
                    Spacer()
                    Text("数字を入力してください")
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(groupItems.enumerated()), id: \.element.id) { index, group in
                                GroupRowView(
                                    group: group,
                                    selectedReadings: selectedReadings,
                                    customWord: customWords[group.id] ?? "",
                                    userCandidates: historyStore.userSuggestions[group.digitKey] ?? [],
                                    onSelectReading: { absIndex, reading in
                                        selectedReadings[absIndex] = reading
                                        customWords[group.id] = nil
                                    },
                                    onWordChange: { word in
                                        customWords[group.id] = word.isEmpty ? nil : word
                                    },
                                    onSplit: {
                                        mergedGroups.removeValue(forKey: group.id)
                                        customWords[group.id] = nil
                                    }
                                )

                                if index < groupItems.count - 1 {
                                    let next = groupItems[index + 1]
                                    let combined = group.digits.count + next.digits.count
                                    if combined <= 12 {
                                        MergeButton {
                                            mergedGroups[group.id] = combined
                                            customWords[group.id] = nil
                                        }
                                    } else {
                                        Spacer().frame(height: 10)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }

                    VStack(spacing: 12) {
                        Divider()
                            .background(Color(white: 0.3))

                        Text(result)
                            .foregroundColor(.white)
                            .font(.system(size: 34, weight: .bold))
                            .minimumScaleFactor(0.4)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = result
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copied = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    Text(copied ? "コピー済" : "コピー")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }

                            Button {
                                historyStore.add(
                                    inputNumber: inputNumber,
                                    result: result,
                                    mergedGroups: mergedGroups,
                                    selectedReadings: selectedReadings,
                                    customWords: customWords
                                )
                                saved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    saved = false
                                }
                            } label: {
                                HStack {
                                    Image(systemName: saved ? "checkmark" : "bookmark")
                                    Text(saved ? "保存済" : "保存")
                                }
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color(white: 0.25))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(store: historyStore) { item in
                inputNumber = item.inputNumber
                mergedGroups = historyStore.intMergedGroups(item)
                selectedReadings = historyStore.intSelectedReadings(item)
                customWords = historyStore.intCustomWords(item)
                showingHistory = false
            }
        }
    }
}

// MARK: - 履歴ビュー

struct HistoryView: View {
    @ObservedObject var store: HistoryStore
    let onRestore: (HistoryItem) -> Void

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text("保存済み語呂合わせ")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 12)

                if store.items.isEmpty {
                    Spacer()
                    Text("保存された語呂合わせはありません")
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                } else {
                    List {
                        ForEach(store.items) { item in
                            Button {
                                onRestore(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.inputNumber)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.orange)
                                        Spacer()
                                        Text(dateFormatter.string(from: item.date))
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(white: 0.5))
                                    }
                                    Text(item.result)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color(white: 0.12))
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }
}

// MARK: - 結合ボタン

struct MergeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "link")
                Text("結合")
                    .font(.system(size: 12))
            }
            .foregroundColor(Color(white: 0.5))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color(white: 0.1))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

// MARK: - 短縮ハッシュ (base493)

private let shortHashAlphabet: [Character] = Array(
    "0123456789" +
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" +
    // ひらがな: 基本46 + 小文字9 + 濁音20 + 半濁音5 = 80
    "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん" +
    "ぁぃぅぇぉっゃゅょ" +
    "がぎぐげござじずぜぞだぢづでどばびぶべぼ" +
    "ぱぴぷぺぽ" +
    // カタカナ: 基本46 + 小文字9 + 濁音20 + 半濁音5 = 80
    "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン" +
    "ァィゥェォッャュョ" +
    "ガギグゲゴザジズゼゾダヂヅデドバビブベボ" +
    "パピプペポ" +
    // ギリシャ文字: 大文字24 + 小文字24 = 48
    "ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ" +
    "αβγδεζηθικλμνξοπρστυφχψω" +
    // キリル文字: 大文字33 + 小文字33 = 66
    "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ" +
    "абвгдежзийклмнопрстуфхцчшщъыьэюя" +
    // 東アラビア数字: ٠١٢٣٤٥٦٧٨٩ = 10
    "٠١٢٣٤٥٦٧٨٩" +
    // 小学1年漢字: 80
    "一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六" +
    // ヘブライ文字: 基本22 + 語末形5 = 27
    "אבגדהוזחטיכלמנסעפצקרשתךםןףץ" +
    // ハングル字母: 子音19 + 母音21 = 40
    "ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎㄲㄸㅃㅆㅉ" +
    "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"
) // 10+52+80+80+48+66+10+80+27+40 = 493文字

private func baseEncode(bytes: [UInt8]) -> String {
    let base = shortHashAlphabet.count
    var digits = [Int]()
    for byte in bytes {
        var carry = Int(byte)
        for i in 0..<digits.count {
            carry += digits[i] << 8
            digits[i] = carry % base
            carry /= base
        }
        while carry > 0 {
            digits.append(carry % base)
            carry /= base
        }
    }
    if digits.isEmpty { digits.append(0) }
    return String(digits.reversed().map { shortHashAlphabet[$0] })
}

// MARK: - 抵抗器カラーコード

private func resistorColor(for digit: Character) -> Color {
    switch digit {
    case "0": return Color(white: 0.08)           // 黒
    case "1": return Color(red: 0.45, green: 0.22, blue: 0.05) // 茶
    case "2": return Color(red: 0.85, green: 0.1, blue: 0.1)   // 赤
    case "3": return Color(red: 1.0, green: 0.5, blue: 0.0)    // 橙
    case "4": return Color(red: 1.0, green: 0.85, blue: 0.0)   // 黄
    case "5": return Color(red: 0.1, green: 0.65, blue: 0.1)   // 緑
    case "6": return Color(red: 0.1, green: 0.2, blue: 0.9)    // 青
    case "7": return Color(red: 0.5, green: 0.0, blue: 0.8)    // 紫
    case "8": return Color(white: 0.55)            // 灰
    case "9": return Color.white                   // 白
    default:  return Color(white: 0.3)
    }
}

private func resistorTextColor(for digit: Character) -> Color {
    switch digit {
    case "3", "4", "9": return .black
    default: return .white
    }
}

private func resistorRawValue(digits: [Character]) -> Double? {
    guard digits.count >= 3,
          let d1 = digits[0].wholeNumberValue,
          let d2 = digits[1].wholeNumberValue,
          let d3 = digits[2].wholeNumberValue else { return nil }
    return Double(d1 * 10 + d2) * pow(10.0, Double(d3))
}

private func formatResistance(_ value: Double) -> String {
    switch value {
    case 1_000_000_000...: return String(format: "%.3gGΩ", value / 1_000_000_000)
    case 1_000_000...:     return String(format: "%.3gMΩ", value / 1_000_000)
    case 1_000...:         return String(format: "%.3gkΩ", value / 1_000)
    default:               return String(format: "%.3gΩ",  value)
    }
}

private func resistorValue(digits: [Character]) -> String {
    guard let value = resistorRawValue(digits: digits) else { return "" }
    return formatResistance(value)
}

// MARK: - グループ行

struct GroupRowView: View {
    let group: GoroModel.GroupItem
    let selectedReadings: [Int: String]
    let customWord: String
    var userCandidates: [String] = []
    let onSelectReading: (Int, String) -> Void
    let onWordChange: (String) -> Void
    let onSplit: () -> Void

    var combinedReading: String {
        group.digits.enumerated().map { offset, digit in
            selectedReadings[group.id + offset]
                ?? GoroModel.readings[digit]?.first
                ?? String(digit)
        }.joined()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(group.digits.enumerated()), id: \.offset) { offset, digit in
                        let absIndex = group.id + offset
                        let selected = selectedReadings[absIndex]
                        HStack(spacing: 8) {
                            Text(String(digit))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(digit == "-" ? .white : resistorTextColor(for: digit))
                                .frame(width: 34, height: 34)
                                .background(digit == "-" ? Color(white: 0.3) : resistorColor(for: digit))
                                .cornerRadius(6)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(GoroModel.readings[digit] ?? [], id: \.self) { kana in
                                        Button(kana) {
                                            onSelectReading(absIndex, kana)
                                        }
                                        .foregroundColor(selected == kana && customWord.isEmpty ? .black : .white)
                                        .fontWeight(selected == kana ? .bold : .regular)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selected == kana && customWord.isEmpty ? Color.orange : Color(white: 0.25))
                                        .cornerRadius(16)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                if group.isMerged {
                    Button(action: onSplit) {
                        Image(systemName: "scissors")
                            .foregroundColor(Color(white: 0.5))
                            .padding(8)
                            .background(Color(white: 0.18))
                            .cornerRadius(8)
                    }
                }
            }

            let builtinCandidates = GoroModel.suggestions[group.digitKey] ?? []
            let filteredUserCandidates = userCandidates.filter { !builtinCandidates.contains($0) }
            if !builtinCandidates.isEmpty || !filteredUserCandidates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(builtinCandidates, id: \.self) { candidate in
                            Button(candidate) { onWordChange(candidate) }
                                .foregroundColor(customWord == candidate ? .black : .orange)
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(customWord == candidate ? Color.orange : Color.orange.opacity(0.15))
                                .cornerRadius(16)
                        }
                        ForEach(filteredUserCandidates, id: \.self) { candidate in
                            Button(candidate) { onWordChange(candidate) }
                                .foregroundColor(customWord == candidate ? .black : Color(red: 0.4, green: 0.8, blue: 1.0))
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(customWord == candidate ? Color(red: 0.4, green: 0.8, blue: 1.0) : Color(red: 0.4, green: 0.8, blue: 1.0).opacity(0.15))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            HStack(spacing: 8) {
                Text(combinedReading)
                    .foregroundColor(.orange)
                    .font(.system(size: 13))
                    .frame(minWidth: 36)

                TextField("「\(combinedReading)」の言葉...", text: Binding(
                    get: { customWord },
                    set: { onWordChange($0) }
                ))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(white: 0.2))
                .cornerRadius(8)
            }
        }
        .padding(group.digits == ["-"] ? 6 : 12)
        .background(group.isMerged ? Color(red: 0.1, green: 0.12, blue: 0.18) : Color(white: 0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(group.isMerged ? Color.blue.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
