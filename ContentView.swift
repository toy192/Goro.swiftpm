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

    // 固定電話のグループ: 03/06は2+4+4、それ以外は3+3+4
    var landlineGroups: [Int: Int] {
        let digits = inputNumber.filter { $0.isNumber }
        let prefix2 = String(digits.prefix(2))
        if ["03", "06"].contains(prefix2) {
            return [0: 2, 2: 4, 6: 4]
        }
        return [0: 3, 3: 3, 6: 4]
    }

    var result: String {
        let words = groupItems.map { group in
            let word = customWords[group.id] ?? ""
            return word.isEmpty ? groupReading(group) : word
        }
        return words.joined(separator: (isMyNumber || isPhoneNumber || isLandline) ? " " : "")
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
                                        // 固定電話モード: 03/06→2+4+4, その他→3+3+4
                                        let p2 = String(stripped.prefix(2))
                                        if ["03", "06"].contains(p2) {
                                            if i == 2 || i == 6 { tmp.append(" ") }
                                        } else {
                                            if i == 3 || i == 6 { tmp.append(" ") }
                                        }
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
                                    let p2 = String(digits.prefix(2))
                                    if ["03", "06"].contains(p2) {
                                        mergedGroups = [0: 2, 2: 4, 6: 4]     // 固定電話(2+4+4)
                                    } else {
                                        mergedGroups = [0: 3, 3: 3, 6: 4]     // 固定電話(3+3+4)
                                    }
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
                    let p2 = String(inputNumber.filter { $0.isNumber }.prefix(2))
                    let fmt = ["03", "06"].contains(p2) ? "2+4+4" : "3+3+4"
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("固定電話モード（\(fmt)）")
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
                                .foregroundColor(.orange)
                                .frame(width: 28)

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
