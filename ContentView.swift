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
        NavigationStack {
            VStack(spacing: 0) {
                inputArea
                    .padding()

                if digitItems.isEmpty {
                    Spacer()
                    Text("数字を入力してください")
                        .foregroundStyle(.secondary)
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
                        .padding()
                    }

                    resultArea
                }
            }
            .navigationTitle("語呂合わせメーカー")
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("数字を入力...", text: $inputNumber)
                .keyboardType(.numberPad)
                .font(.title2)
                .padding(12)
                .background(Color(.systemGray6))
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
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
            }
        }
    }

    private var resultArea: some View {
        VStack(spacing: 12) {
            Divider()
            Text(result)
                .font(.system(size: 34, weight: .bold))
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .animation(.default, value: result)

            Button {
                UIPasteboard.general.string = result
                copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    copied = false
                }
            } label: {
                Label(
                    copied ? "コピーしました" : "コピー",
                    systemImage: copied ? "checkmark" : "doc.on.doc"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .padding(.bottom)
            .animation(.default, value: copied)
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
                .foregroundStyle(.blue)
                .frame(width: 36)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(readings, id: \.self) { reading in
                        Button(reading) {
                            onSelect(reading)
                        }
                        .buttonStyle(.bordered)
                        .tint(selected == reading ? .blue : .secondary)
                        .fontWeight(selected == reading ? .bold : .regular)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
