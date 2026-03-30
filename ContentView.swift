import SwiftUI

struct ContentView: View {
    @State private var inputNumber = ""
    @State private var mergedGroups: [Int: Int] = [:]  // 開始インデックス → グループサイズ
    @State private var selectedReadings: [Int: String] = [:]
    @State private var customWords: [Int: String] = [:]
    @State private var copied = false

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

    var result: String {
        groupItems.map { group in
            let word = customWords[group.id] ?? ""
            return word.isEmpty ? groupReading(group) : word
        }.joined()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("語呂合わせメーカー")
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 60)
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
                            let filtered = inputNumber.filter { $0.isNumber || $0 == "-" }
                            if filtered != inputNumber {
                                inputNumber = filtered
                            }
                            mergedGroups = [:]
                            selectedReadings = [:]
                            customWords = [:]
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
                                    if combined <= 6 {
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

                        Button {
                            UIPasteboard.general.string = result
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "コピーしました" : "コピー")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color.orange)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 24)
                    }
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

            if let candidates = GoroModel.suggestions[group.digitKey], !candidates.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(candidates, id: \.self) { candidate in
                            Button(candidate) {
                                onWordChange(candidate)
                            }
                            .foregroundColor(customWord == candidate ? .black : .orange)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(customWord == candidate ? Color.orange : Color.orange.opacity(0.15))
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
