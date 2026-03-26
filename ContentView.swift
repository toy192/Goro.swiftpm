import SwiftUI

struct ContentView: View {
    @State private var inputNumber = ""
    @State private var selectedReadings: [Int: String] = [:]
    @State private var copied = false

    var digitItems: [GoroModel.DigitItem] {
        GoroModel.digitItems(from: inputNumber)
    }

    var result: String {
        digitItems.map { item in
            selectedReadings[item.id]
                ?? GoroModel.readings[item.digit]?.first
                ?? String(item.digit)
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
                        .keyboardType(.numberPad)
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .onChange(of: inputNumber) { _ in
                            selectedReadings = [:]
                        }

                    if !inputNumber.isEmpty {
                        Button {
                            inputNumber = ""
                            selectedReadings = [:]
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color(white: 0.6))
                                .font(.title2)
                        }
                    }
                }
                .padding(.horizontal, 16)

                if digitItems.isEmpty {
                    Spacer()
                    Text("数字を入力してください")
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(digitItems) { item in
                                DigitRowView(
                                    item: item,
                                    readings: GoroModel.readings[item.digit] ?? [],
                                    selected: selectedReadings[item.id]
                                ) { reading in
                                    selectedReadings[item.id] = reading
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

struct DigitRowView: View {
    let item: GoroModel.DigitItem
    let readings: [String]
    let selected: String?
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(String(item.digit))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .frame(width: 36)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(readings, id: \.self) { reading in
                        Button(reading) {
                            onSelect(reading)
                        }
                        .foregroundColor(selected == reading ? .black : .white)
                        .fontWeight(selected == reading ? .bold : .regular)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selected == reading ? Color.orange : Color(white: 0.25))
                        .cornerRadius(20)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(Color(white: 0.12))
        .cornerRadius(10)
    }
}
