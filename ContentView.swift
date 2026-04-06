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
    @State private var decodeReversed = false
    @State private var ladybugVisible = false
    @State private var ladybugX: CGFloat = -60
    @State private var ladybugY: CGFloat = 0
    @State private var butterflyVisible = false
    @State private var butterflyX: CGFloat = -60
    @State private var butterflyY: CGFloat = 0
    @State private var butterflyOffset: CGFloat = 0
    @State private var grasshopperVisible = false
    @State private var grasshopperX: CGFloat = -60
    @State private var grasshopperY: CGFloat = 0
    @State private var frogVisible = false
    @State private var frogX: CGFloat = -60
    @State private var frogY: CGFloat = 0
    @State private var beetleVisible = false
    @State private var beetleX: CGFloat = -60
    @State private var beetleY: CGFloat = 0

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

    var baseDecodeResult: String {
        let decoded = baseDecode(inputKanji)
        return decodeReversed ? String(decoded.reversed()) : decoded
    }

    private func runBeetle() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        beetleX = -50
        beetleY = screenH * 0.9
        beetleVisible = true
        // 素早くジグザグ走る
        let steps: [(x: CGFloat, y: CGFloat, delay: Double)] = [
            (screenW * 0.15, screenH * 0.82, 0.0),
            (screenW * 0.3,  screenH * 0.92, 0.18),
            (screenW * 0.45, screenH * 0.80, 0.36),
            (screenW * 0.6,  screenH * 0.92, 0.54),
            (screenW * 0.75, screenH * 0.82, 0.72),
            (screenW * 0.9,  screenH * 0.90, 0.90),
            (screenW + 60,   screenH * 0.90, 1.05),
        ]
        for step in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) {
                withAnimation(.linear(duration: 0.18)) {
                    beetleX = step.x
                    beetleY = step.y
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            beetleVisible = false
        }
    }

    private func runFrog() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        frogX = -50
        frogY = screenH * 0.88
        frogVisible = true
        let hops: [(x: CGFloat, y: CGFloat, delay: Double)] = [
            (screenW * 0.2,  screenH * 0.65, 0.0),
            (screenW * 0.35, screenH * 0.88, 0.45),
            (screenW * 0.55, screenH * 0.65, 0.9),
            (screenW * 0.7,  screenH * 0.88, 1.35),
            (screenW * 0.9,  screenH * 0.65, 1.8),
            (screenW + 60,   screenH * 0.88, 2.25),
        ]
        for hop in hops {
            DispatchQueue.main.asyncAfter(deadline: .now() + hop.delay) {
                withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
                    frogX = hop.x
                    frogY = hop.y
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            frogVisible = false
        }
    }

    private func runGrasshopper() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        grasshopperX = -50
        grasshopperY = screenH * 0.85
        grasshopperVisible = true
        // ぴょんぴょん跳ねながら横断
        withAnimation(.interpolatingSpring(stiffness: 120, damping: 8).repeatCount(4, autoreverses: false).speed(1.5)) {
            grasshopperX = screenW * 0.25
            grasshopperY = screenH * 0.6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 8)) {
                grasshopperX = screenW * 0.55
                grasshopperY = screenH * 0.85
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.interpolatingSpring(stiffness: 120, damping: 8)) {
                grasshopperX = screenW * 0.8
                grasshopperY = screenH * 0.6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.linear(duration: 0.3)) {
                grasshopperX = screenW + 60
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            grasshopperVisible = false
        }
    }

    private func runButterfly() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        butterflyX = -50
        butterflyY = CGFloat.random(in: screenH * 0.1 ... screenH * 0.4)
        butterflyOffset = 0
        butterflyVisible = true
        withAnimation(.easeInOut(duration: 3.5)) {
            butterflyX = screenW + 50
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            butterflyVisible = false
        }
    }

    private func runLadybug() {
        let screenW = UIScreen.main.bounds.width
        let screenH = UIScreen.main.bounds.height
        ladybugX = -44
        ladybugY = CGFloat.random(in: screenH * 0.08 ... screenH * 0.25)
        ladybugVisible = true
        withAnimation(.linear(duration: 2.2)) {
            ladybugX = screenW + 44
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            ladybugVisible = false
        }
    }

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
                        HStack {
                            Text("逆変換（漢字→数字）")
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.5))
                            Spacer()
                            Toggle("逆順", isOn: $decodeReversed)
                                .toggleStyle(.button)
                                .font(.system(size: 11))
                                .tint(.teal)
                                .padding(.trailing, 16)
                        }
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
                                        if word == "てんとう虫" || word == "🐞" {
                                            runLadybug()
                                        }
                                        if word == "てふてふ" || word == "蝶々" || word == "🦋" {
                                            runButterfly()
                                        }
                                        if word == "イナゴ" || word == "🦗" {
                                            runGrasshopper()
                                        }
                                        if word == "ケロケロ" || word == "🐸" {
                                            runFrog()
                                        }
                                        if word == "オサムシ" || word == "🪲" {
                                            runBeetle()
                                        }
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
        .overlay(
            GeometryReader { geo in
                if ladybugVisible {
                    Text("🐞")
                        .font(.system(size: 44))
                        .position(x: ladybugX, y: ladybugY)
                        .allowsHitTesting(false)
                }
                if butterflyVisible {
                    Text("🦋")
                        .font(.system(size: 44))
                        .position(x: butterflyX, y: butterflyY)
                        .allowsHitTesting(false)
                }
                if grasshopperVisible {
                    Text("🦗")
                        .font(.system(size: 44))
                        .position(x: grasshopperX, y: grasshopperY)
                        .allowsHitTesting(false)
                }
                if frogVisible {
                    Text("🐸")
                        .font(.system(size: 44))
                        .position(x: frogX, y: frogY)
                        .allowsHitTesting(false)
                }
                if beetleVisible {
                    Text("🪲")
                        .font(.system(size: 44))
                        .position(x: beetleX, y: beetleY)
                        .allowsHitTesting(false)
                }
            }
        )
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

// 常用漢字2136字（2010年内閣告示・音読み五十音順）
private let base128Alphabet: [Character] = Array(
    "一丁七万丈三上下不与且世丘丙両並中串丸丹主丼久乏乗乙九乞乱乳乾亀了予争事二互五井亜亡交享京亭人仁今介仏仕他付仙代令以仮仰仲件任企伎伏伐休会伝伯伴伸伺似但位低住佐" +
    "体何余作佳併使例侍供依価侮侯侵侶便係促俊俗保信修俳俵俸俺倉個倍倒候借倣値倫倹偉偏停健側偵偶偽傍傑傘備催傲債傷傾僅働像僕僚僧儀億儒償優元兄充兆先光克免児党入全八公" +
    "六共兵具典兼内円冊再冒冗写冠冥冬冶冷凄准凍凝凡処凶凸凹出刀刃分切刈刊刑列初判別利到制刷券刹刺刻則削前剖剛剣剤剝副剰割創劇力功加劣助努励労効劾勃勅勇勉動勘務勝募勢" +
    "勤勧勲勾匂包化北匠匹区医匿十千升午半卑卒卓協南単博占印危即却卵卸厄厘厚原厳去参又及友双反収叔取受叙口古句叫召可台叱史右号司各合吉同名后吏吐向君吟否含吸吹呂呈呉告" +
    "周呪味呼命和咲咽哀品員哲哺唄唆唇唐唯唱唾商問啓善喉喚喜喝喩喪喫営嗅嗣嘆嘱嘲器噴嚇囚四回因団困囲図固国圏園土圧在地坂均坊坑坪垂型垣埋城域執培基埼堀堂堅堆堕堤堪報場" +
    "塀塁塊塑塔塗塚塞塩塡塾境墓増墜墨墳墾壁壇壊壌士壮声壱売変夏夕外多夜夢大天太夫央失奇奈奉奏契奔奥奨奪奮女奴好如妃妄妊妖妙妥妨妬妹妻姉始姓委姫姻姿威娘娠娯婆婚婦婿媒" +
    "媛嫁嫉嫌嫡嬢子孔字存孝季孤学孫宅宇守安完宗官宙定宛宜宝実客宣室宮宰害宴宵家容宿寂寄密富寒寛寝察寡寧審寮寸寺対寿封専射将尉尊尋導小少尚就尺尻尼尽尾尿局居屈届屋展属" +
    "層履屯山岐岡岩岬岳岸峠峡峰島崇崎崖崩嵐川州巡巣工左巧巨差己巻巾市布帆希帝帥師席帯帰帳常帽幅幕幣干平年幸幹幻幼幽幾庁広床序底店府度座庫庭庶康庸廃廉廊延廷建弁弄弊式" +
    "弐弓弔引弟弥弦弧弱張強弾当彙形彩彫彰影役彼往征径待律後徐徒従得御復循微徳徴徹心必忌忍志忘忙応忠快念怒怖思怠急性怨怪恋恐恒恣恥恨恩恭息恵悔悟悠患悦悩悪悲悼情惑惜惧" +
    "惨惰想愁愉意愚愛感慄慈態慌慎慕慢慣慨慮慰慶憂憎憤憧憩憬憲憶憾懇懐懲懸成我戒戚戦戯戴戸戻房所扇扉手才打払扱扶批承技抄把抑投抗折抜択披抱抵抹押抽担拉拍拐拒拓拘拙招拝" +
    "拠拡括拭拳拶拷拾持指挑挙挟挨挫振挿捉捕捗捜捨据捻掃授掌排掘掛採探接控推措掲描提揚換握揮援揺損搬搭携搾摂摘摩摯撃撤撮撲擁操擦擬支改攻放政故敏救敗教敢散敬数整敵敷文" +
    "斉斎斑斗料斜斤斥斬断新方施旅旋族旗既日旦旧旨早旬旺昆昇明易昔星映春昧昨昭是昼時晩普景晴晶暁暇暑暖暗暦暫暮暴曇曖曜曲更書曹曽替最月有服朕朗望朝期木未末本札朱朴机朽" +
    "杉材村束条来杯東松板析枕林枚果枝枠枢枯架柄某染柔柱柳柵査柿栃栄栓校株核根格栽桁桃案桑桜桟梅梗梨械棄棋棒棚棟森棺椅植椎検業極楷楼楽概構様槽標模権横樹橋機欄欠次欧欲" +
    "欺款歌歓止正武歩歯歳歴死殉殊残殖殴段殺殻殿毀母毎毒比毛氏民気水氷永氾汁求汎汗汚江池汰決汽沃沈沖沙没沢河沸油治沼沿況泉泊泌法泡波泣泥注泰泳洋洗洞津洪活派流浄浅浜浦" +
    "浪浮浴海浸消涙涯液涼淑淡淫深混添清渇済渉渋渓減渡渦温測港湖湧湯湾湿満源準溝溶溺滅滋滑滝滞滴漁漂漆漏演漠漢漫漬漸潔潜潟潤潮潰澄激濁濃濫濯瀬火灯灰災炉炊炎炭点為烈無" +
    "焦然焼煎煙照煩煮熊熟熱燃燥爆爪爵父爽片版牙牛牧物牲特犠犬犯状狂狙狩独狭猛猟猫献猶猿獄獣獲玄率玉王玩珍珠班現球理琴瑠璃璧環璽瓦瓶甘甚生産用田由甲申男町画界畏畑畔留" +
    "畜畝略番異畳畿疎疑疫疲疾病症痕痘痛痢痩痴瘍療癒癖発登白百的皆皇皮皿盆益盗盛盟監盤目盲直相盾省眉看県真眠眺眼着睡督睦瞬瞭瞳矛矢知短矯石砂研砕砲破硝硫硬碁碑確磁磨礁" +
    "礎示礼社祈祉祖祝神祥票祭禁禅禍福秀私秋科秒秘租秩称移程税稚種稲稼稽稿穀穂積穏穫穴究空突窃窒窓窟窮窯立竜章童端競竹笑笛符第筆等筋筒答策箇箋算管箱箸節範築篤簡簿籍籠" +
    "米粉粋粒粗粘粛粧精糖糧糸系糾紀約紅紋納純紙級紛素紡索紫累細紳紹紺終組経結絞絡給統絵絶絹継続維綱網綻綿緊総緑緒線締編緩緯練緻縁縄縛縦縫縮績繁繊織繕繭繰缶罪置罰署罵" +
    "罷羅羊美羞群羨義羽翁翌習翻翼老考者耐耕耗耳聖聞聴職肉肌肖肘肝股肢肥肩肪肯育肺胃胆背胎胞胴胸能脂脅脇脈脊脚脱脳腎腐腕腫腰腸腹腺膚膜膝膨膳臆臓臣臨自臭至致臼興舌舎舗" +
    "舞舟航般舶舷船艇艦良色艶芋芝芯花芳芸芽苗苛若苦英茂茎茨茶草荒荘荷菊菌菓菜華萎落葉著葛葬蒸蓄蓋蔑蔵蔽薄薦薪薫薬藍藤藩藻虎虐虚虜虞虫虹蚊蚕蛇蛍蛮蜂蜜融血衆行術街衛衝" +
    "衡衣表衰衷袋袖被裁裂装裏裕補裸製裾複褐褒襟襲西要覆覇見規視覚覧親観角解触言訂訃計討訓託記訟訪設許訳訴診証詐詔評詞詠詣試詩詮詰話該詳誇誉誌認誓誕誘語誠誤説読誰課調" +
    "談請論諦諧諭諮諸諾謀謁謄謎謙講謝謡謹識譜警議譲護谷豆豊豚象豪貌貝貞負財貢貧貨販貪貫責貯貴買貸費貼貿賀賂賃賄資賊賓賛賜賞賠賢賦質賭購贈赤赦走赴起超越趣足距跡路跳践" +
    "踊踏踪蹴躍身車軌軍軒軟転軸軽較載輝輩輪輸轄辛辞辣辱農辺込迅迎近返迫迭述迷追退送逃逆透逐逓途通逝速造連逮週進逸遂遅遇遊運遍過道達違遜遠遡遣適遭遮遵遷選遺避還那邦邪" +
    "邸郊郎郡部郭郵郷都酌配酎酒酔酢酪酬酵酷酸醒醜醸采釈里重野量金釜針釣鈍鈴鉄鉛鉢鉱銀銃銅銘銭鋭鋳鋼錠錦錬錮錯録鍋鍛鍵鎌鎖鎮鏡鐘鑑長門閉開閑間関閣閥閲闇闘阜阪防阻附降" +
    "限陛院陣除陥陪陰陳陵陶陸険陽隅隆隊階随隔隙際障隠隣隷隻雄雅集雇雌雑離難雨雪雰雲零雷電需震霊霜霧露青静非面革靴韓音韻響頂頃項順須預頑頒頓領頬頭頻頼題額顎顔顕願類顧" +
    "風飛食飢飯飲飼飽飾餅養餌餓館首香馬駄駅駆駐駒騎騒験騰驚骨骸髄高髪鬱鬼魂魅魔魚鮮鯨鳥鳴鶏鶴鹿麓麗麦麺麻黄黒黙鼓鼻齢"
)

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
