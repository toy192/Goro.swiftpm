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
    @State private var showingBase128 = false
    @State private var copiedBase = false
    @State private var copiedBaseReversed = false
    @State private var inputKanji = ""
    @State private var copiedBaseDecode = false

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

    var numberBase128: String { baseConvert(inputNumber.filter { $0.isNumber }) }

    var numberBase128Reversed: String {
        let digits = inputNumber.filter { $0.isNumber }
        return baseConvert(String(digits.reversed()))
    }

    var baseDecodeResult: String { baseDecode(inputKanji) }

    private func baseDecode(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        let alphabetIndex = Dictionary(uniqueKeysWithValues: base128Alphabet.enumerated().map { ($1, $0) })
        let zeroChar = base128Alphabet[0]
        let leadingZeroCount = text.prefix(while: { $0 == zeroChar }).count
        let rest = String(text.drop(while: { $0 == zeroChar }))
        guard !rest.isEmpty else { return String(repeating: "0", count: leadingZeroCount) }
        let base = UInt64(base128Alphabet.count)
        var value: UInt64 = 0
        for char in rest {
            guard let idx = alphabetIndex[char] else { return "?" }
            let (mul, ov1) = value.multipliedReportingOverflow(by: base)
            if ov1 { return "桁数超過" }
            let (add, ov2) = mul.addingReportingOverflow(UInt64(idx))
            if ov2 { return "桁数超過" }
            value = add
        }
        return String(repeating: "0", count: leadingZeroCount) + String(value)
    }

    private func baseConvert(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }
        let leadingZeroCount = digits.prefix(while: { $0 == "0" }).count
        let leadingPrefix = String(repeating: String(base128Alphabet[0]), count: leadingZeroCount)
        let rest = String(digits.drop(while: { $0 == "0" }))
        guard !rest.isEmpty else { return leadingPrefix }
        guard let value = UInt64(rest) else { return "" }
        let base = UInt64(base128Alphabet.count)
        var n = value
        var result: [Character] = []
        while n > 0 {
            result.append(base128Alphabet[Int(n % base)])
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
                        showingBase128.toggle()
                    } label: {
                        Text("B128")
                            .foregroundColor(showingBase128 ? .cyan : Color(white: 0.6))
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

                if showingBase128 && !inputNumber.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        let digits = inputNumber.filter { $0.isNumber }
                        Text("base\(base128Alphabet.count)変換（可逆）: \(digits.count)桁 → \(numberBase128.count)文字")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 16)
                        HStack(alignment: .bottom) {
                            Text(numberBase128)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                                .padding(.leading, 16)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = numberBase128
                                copiedBase = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedBase = false }
                            } label: {
                                Image(systemName: copiedBase ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(copiedBase ? .green : .cyan)
                            }
                            .padding(.trailing, 16)
                        }
                        Text("逆順: \(String(digits.reversed()))")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        HStack(alignment: .bottom) {
                            Text(numberBase128Reversed)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.teal)
                                .padding(.leading, 16)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = numberBase128Reversed
                                copiedBaseReversed = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedBaseReversed = false }
                            } label: {
                                Image(systemName: copiedBaseReversed ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(copiedBaseReversed ? .green : .teal)
                            }
                            .padding(.trailing, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if showingBase128 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("逆変換（漢字→数字）")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.horizontal, 16)
                        HStack(spacing: 8) {
                            TextField("漢字・かなを入力...", text: $inputKanji)
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(white: 0.15))
                                .cornerRadius(10)
                                .padding(.leading, 16)
                            if !inputKanji.isEmpty {
                                Button { inputKanji = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(white: 0.5))
                                }
                                .padding(.trailing, 16)
                            }
                        }
                        if !inputKanji.isEmpty {
                            HStack(alignment: .bottom) {
                                Text(baseDecodeResult)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.yellow)
                                    .padding(.leading, 16)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = baseDecodeResult
                                    copiedBaseDecode = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedBaseDecode = false }
                                } label: {
                                    Image(systemName: copiedBaseDecode ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(copiedBaseDecode ? .green : .yellow)
                                }
                                .padding(.trailing, 16)
                            }
                        }
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

// MARK: - baseアルファベット（常用漢字・人名用漢字対応）

// ひらがな + 常用漢字（小1〜小6・中学以降）+ 人名用漢字 を含む（数字・英字は除外）
// 重複を自動除去して一意な文字セットを構築
private let base128Alphabet: [Character] = {
    var seen = Set<Character>()
    return Array((
        // ひらがな: 基本46 + 濁音20
        "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん" +
        "がぎぐげござじずぜぞだぢづでどばびぶべぼ" +
        // 小学1年漢字: 80字
        "一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六" +
        // 小学2年漢字: 160字
        "引羽雲園遠何科夏家歌画回会海絵外角楽活間丸岩顔汽記帰弓牛魚京強教近兄形計元言原戸古午後語工公広交光考行高黄合谷国黒今才細作算止市矢姉思紙寺自時室社弱首秋週春冬書少場色食心新親図数西声星晴切雪船線前組走多太体台地池知茶昼長鳥朝直通弟店点電刀東当答頭同道読内南肉馬売買麦半番父風分聞米歩母方北毎妹万明鳴毛門夜野友用曜来里理話" +
        // 小学3年漢字: 200字
        "悪安暗医委意育員院飲運泳駅央横屋温化荷界開階寒感漢館岸起期客究急級宮球去橋業曲局銀区苦具君係軽血決研県庫湖向幸港号根祭皿仕死使始指歯詩次事持式実写者主守取酒受州拾終習集住重宿所暑助昭消商章勝乗植申身神真深進世整昔全想相送息速族他打対待代第題炭短談着注柱丁帳調追定庭笛鉄転都度投豆島湯登等動童農波配倍箱畑発反板悲皮美鼻筆氷表秒病品負部服福物平返勉放味命面問役薬由油有遊予様陽落流旅両緑礼列練路和" +
        // 小学4年漢字: 202字
        "愛案以衣位囲胃印英栄塩億加果貨課芽改械害街各覚完官管関観願希季紀喜旗機議求泣救給挙漁共協鏡競極訓軍郡径型景芸欠結建健験固功好候航康告差菜最材昨散産残氏司試児治辞失借種周祝順初松笑唱焼象照賞城臣信成省清静席積折節説浅戦選然争倉巣束側続卒孫帯隊達単置仲貯腸低底的典伝徒努灯堂働特得毒熱念敗梅博飛費必票標不夫付府副粉兵別辺変便包法望牧末満未民無約勇要養浴利陸良料量輪類令冷例連老労録" +
        // 小学5年漢字: 193字
        "圧移因永営衛易益液演応往恩仮価河過賀快解格確額刊幹慣眼基寄規技義逆久旧居許境均禁句経潔件険検限現減故個護効厚耕鉱構興講混査再妻採際在財罪雑酸賛支志枝師資飼示似識質舎謝授修術述準序招承証条状常情織職制性政勢精製税責績接設舌絶祖素総造像増則測属率損退団断築張提程適統銅導独任燃能破犯比被評布婦富武復複仏編弁保墓報豊暴貿防務夢迷綿輸余預容略留領" +
        // 小学6年漢字: 191字
        "異遺域宇映延沿我灰拡閣革割株干巻看簡危机揮貴疑吸供胸郷勤筋系敬警劇激穴絹権憲源厳己呼誤后孝皇紅降鋼刻穀骨困砂座済裁策冊蚕至私姿視詞誌磁射捨尺若樹収宗就衆従縦縮熟純処署諸除将傷障蒸針仁垂推寸盛聖誠善奏窓創装層操蔵臓存尊宅担探誕段暖値宙忠著庁頂潮賃痛展討党糖届難乳認納脳派拝背肺俳班晩否批秘腹奮並陛閉片補暮宝訪亡忘棒枚幕密盟模訳郵優幼欲翌乱卵覧裏律臨朗論" +
        // 常用漢字（中学以降）
        "亜哀挨曖握扱宛嵐依威為畏尉萎偉椅彙維慰緯壱逸稲芋允姻陰隠韻唄鬱畝浦" +
        "詠影曳疫悦謁越閲宴援艶鉛汚凹奥憶臆虞乙卸穏翁" +
        "禍稼蚊牙瓦雅介廉戒悔怪拐晦概慨蓋該隔核殻郭較閑患陥含頑企岐忌既飢幾棄毀畿稀謹吟" +
        "脅矯凝暁琴斤僅虚拠享凶峡恐恭狂驚虐朽糾拒距巨愚偶隅串窟掘屈" +
        "憩契恵慧傑鍵顕肩嫌謙賢弦懸" +
        "孤弧鼓誇跨溝洪紺恨痕魂" +
        "鎖砕斎催宰彩歳殺刹傘惨巡酢錯削詐" +
        "嗣肢脂賜雌侍慈滋磁汁疾嫉湿漆遮斜蛇爵酌寂赦釈" +
        "秀呪朱儒塾粛瞬旬殉准循潤遵升尚彰衝昇宵症梢硝礁鐘叙徐冗剰壌嬢嘱辱擾譲醸拭飾殖蝕触侵唇娠振紳薪診刃甚尽" +
        "帥醜据杉裾摂籍仙膳繕栓践潜漸禅爽曽喪槽漕捜遭霜騒贈促俗賊" +
        "濯汰胎倦泰滞怠奪択拓沢卓脱棚嘆淡端丹旦胆鍛弾恥逐畜蓄窒嫡脊衷鋳駐徴懲彫勅沈朕椎墜陳賃塚漬坪廷貞帝艇溺迭徹撤哲" +
        "貪頓豚薫窯謡踊羅裸頼雷絡欄濫" +
        "吏履璃隷霊鈴嶺廉恋錬炉露浪郎楼漏籠" +
        "侮僧免凡勾匂尻叱哺喩嗅嘘囚坑垣埋塀墨奉奨妄娯婿嫁孔寂寛寮憾拉拍拘挟捉掌摩擦旺昧枠棺棚椀款欺歓殴沃沸泡淑渓漠炊烏焦煩燥畝痘痩痴瞳睦礁祐祥蚊袖裂褒誓諦謁謙謹賄賂踪辛辱遥郭酌酢醜釈釣鈍錠錬鍵闘阻陵隅雅雄雌霧韻飢駆骸魂鬱鶴" +
        // 常用漢字（中学以降）追加分
        "俺誰亀菊吉却堕妥惰閥斑互鎌鑑劾刈勃勘勧勿匿卑即厭呉喉坐垢壊奔妊悼惑慄慢憤憧憬戯抄挑摘撫掴敏愁愉曹尾峠崩巷巾弛怨惜憂餅葛鍋丼箸諮腺賭貌赴趣軌遣鬼牢牲符綻膨蔑藤褐謂諧謄勲嗜噛喚嘲嚇堅塊塑墳墾媒崇拙搾氾浸渇濁狙猟獲督臭罰" +
        "伐伺剃刺刻剖剰劣勃勤勲匿卑即喚喉喪嗜嗣嘲嚇坐坦垢堕堪堅堰塊塑塚塞墳墾壊壱奔奸妊妬娼孔尾岬峠峰崩嵩巷巾弛彩怨恕悼惑惰惜惧憧憬憤慄慢慶憎愁愉曹棋朽欺殉渇浸氾狙狡猟獣獲瓦痘疾疎督磁禍穿筐篤粛綻腺膝膨蔑藤貌赴趣跡踪軌迭遣鬼鍋" +
        "丁丑丞丹乃乏乖乙亥亨亭亮仁仔仕仙仟仭仮伐伎伽佃佑侃侑侮俄俊俗俚俠俣倉倣偽僅僚凄凛凜勁勾勿匡匿卑卯卸叡叢呉呆呪咎哉哀哭哮唆啄喧嗅嘘嗤嗽囁囃坑坐坦垢垣垰埠堵堺堰堵塒塙塞壱奄奸妄妊妬妻妾姐姑娃娼婉媚媛媼嫁嫗嬉嬌孔孟宍宕宥宸寅寓寤寥尖尤屑屡屣峨峯崛崔崙崚崢嵩嵯嵩巓嶋嶌巡巫巽帆帛帥弛弥彗彦徠忽怜恕悌惟惇惹愕愧慧憐拙拙捺捷掬摩摯斥斐斛斗斤於旭昂昊昏昌昴暁朋朔杏杖杜枇柊柚柾柿栞桂桐桑棟槙槻樺樫樽橘橡橿檀欣欽殷殿汀沌沙沫洸洲浩浬淵渾湊湧滉漣漕漱濡炳煌煕熙猛琉琥琴瑛瑚瑞瑶璞皓盈眸矩砦祐祢耀聡肇胤臥舵舶芙芦芹苑茅茉荻莞菫萌葵蒼蒲蒔薙藍藺蘇蘭虎虹蜂蜜蝶螢蟹訃詢詣誼諄諒諺謳賦赳辰辿迪遐遜遡遙遼邑邨邸郛郝郢鄭醤醵錐錦鎬阿陀陌陝陞隼雀雁雛雫霙霰靖靺鞘鞠韶颯飴饗馨駒騎魁魄魑麒麟黎黛鼎" +
        "亘亨享亮亰亶伊伍伎伽佑侃侑俊俐倭偲凛凜勁叡叢嘉圭堺夷奄奎奏奐妃妍妓姚姜娃娉娜嬉嬌峨峯崛崔崙崚嵩嵯巌巒巓巫巽帆帛弥彗彦徠忽怜恕悌悦惟惇惹愕慧憐捺捷摯斥斐斛於旭昂昊昌昴朋朔杏杖杜枇柊柚柾柿栞桂桐桑棟槻樺樫樽橡橿檀欣欽殷殿汀沌沙沫洸洲浩浬淵渾湊湧滉漣漕漱濡炳煌煕熙猛琉琥琴瑛瑚瑞瑶璞皓盈眸矩砦祐祢禽穣穹穿笙笛篤紗紘紬絢綺綾緋緻縞縫繁繭翠耀聡肇胤臥舵舶芙芦芹苑茅茉荘莞菫萌葵蒼蒲蒔薙藍藺蘇蘭虎虹蜂蜜蝶螢蟹訃詢詣誼諄諒諺謳譜賦赳輝辰辿迪遐遜遡遙遼邑邑邨邸郁郛郝郢鄭醤醵鈴錐錦鎬阿陀陌陝陞隼雀雁雛雫霙霰靖靺鞘鞠韶颯飴饗馨駒騎魁魄魑麒麟黎黛鼎" +
        "碧梓楠椿楓楡槐榎橙汐澪泉渚汐那奈珠翔陸琳凌碩漣彩斗斗蓮凪朱莉栞穂暖柚桃桜楓梢梓楓桂桜椎欅橙桃柿梅桐栄柳棗棕"
    ).filter { seen.insert($0).inserted })
}()

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
