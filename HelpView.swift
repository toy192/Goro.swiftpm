import SwiftUI

struct HelpView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // タイトル
                    VStack(alignment: .leading, spacing: 6) {
                        Text("🔔 GoroBell とは")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.orange)
                        Text("数字を覚えやすい日本語の言葉（語呂合わせ）に変換するアプリです。電話番号・暗証番号・歴史の年号など、数字の暗記をサポートします。")
                            .foregroundColor(Color(white: 0.85))
                            .font(.system(size: 15))
                    }

                    Divider().background(Color(white: 0.3))

                    // 基本的な使い方
                    HelpSection(title: "① 数字を入力する") {
                        HelpRow(icon: "textfield", text: "上部のテキストフィールドに数字を入力します。")
                        HelpRow(icon: "minus", text: "「-」（ハイフン）も入力できます。電話番号などの区切りに使えます。")
                        HelpRow(icon: "xmark.circle", text: "×ボタンで入力をクリアします。")
                    }

                    HelpSection(title: "② 読みを選ぶ") {
                        HelpRow(icon: "hand.tap", text: "各数字の横に読み仮名のボタンが表示されます。タップして読みを切り替えられます。")
                        HelpRow(icon: "info.circle", text: "例：「8」→ は / や / はち")
                    }

                    HelpSection(title: "③ 候補を選ぶ") {
                        HelpRow(icon: "list.bullet", text: "数字の組み合わせに対応する候補が表示される場合があります。オレンジ色のボタンをタップして選択できます。")
                        HelpRow(icon: "pencil", text: "テキストフィールドに直接言葉を入力することもできます。")
                    }

                    HelpSection(title: "④ 数字を結合する") {
                        HelpRow(icon: "link", text: "「結合」ボタンで隣り合う数字をグループにまとめられます（最大7桁）。")
                        HelpRow(icon: "scissors", text: "「✂」ボタンでグループを分割できます。")
                        HelpRow(icon: "star", text: "例：1＋4 を結合 →「いし」→「石」")
                    }

                    HelpSection(title: "⑤ 保存・コピー") {
                        HelpRow(icon: "bookmark", text: "「保存」ボタンで現在の語呂合わせを履歴に保存します。")
                        HelpRow(icon: "doc.on.doc", text: "「コピー」ボタンで結果をクリップボードにコピーします。")
                        HelpRow(icon: "clock.arrow.circlepath", text: "右上の時計アイコンから保存済みの語呂合わせを参照・復元できます。")
                    }

                    Divider().background(Color(white: 0.3))

                    // 数字の読み一覧
                    HelpSection(title: "📖 数字の読み一覧") {
                        VStack(spacing: 6) {
                            ForEach(readingRows, id: \.digit) { row in
                                HStack(alignment: .top) {
                                    Text(row.digit)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.orange)
                                        .frame(width: 28, alignment: .center)
                                    Text(row.readings)
                                        .foregroundColor(Color(white: 0.85))
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                            }
                        }
                    }

                    Divider().background(Color(white: 0.3))

                    // Base変換
                    HelpSection(title: "🔵 Base変換（B128ボタン）") {
                        HelpRow(icon: "number", text: "右上の「B128」ボタンをタップするとBase変換モードをオン/オフできます。")
                        HelpRow(icon: "arrow.right", text: "数字を入力すると、ひらがな・漢字で表現した変換結果を表示します（シアン色）。")
                        HelpRow(icon: "arrow.left.arrow.right", text: "逆順変換も同時に表示されます（ティール色）。携帯番号の語呂に便利です。")
                        HelpRow(icon: "arrow.left", text: "「逆変換」フィールドに漢字・かなを入力すると元の数字に復元できます（黄色）。")
                        HelpRow(icon: "doc.on.doc", text: "各結果の右端のアイコンをタップするとクリップボードにコピーできます。")
                        HelpRow(icon: "lock", text: "変換は可逆です。同じアルファベット（約1949文字）を使えばいつでも元の数字に戻せます。")
                    }

                    Divider().background(Color(white: 0.3))

                    // 抵抗器カラーコード
                    HelpSection(title: "Ω 抵抗器カラーコード（Ωボタン）") {
                        HelpRow(icon: "resistor", text: "右上の「Ω」ボタンをタップすると抵抗値表示モードをオン/オフできます。")
                        HelpRow(icon: "info.circle", text: "数字を入力すると、4桁ずつ抵抗器のカラーバンドとして表示します。")
                        HelpRow(icon: "number.square", text: "カラーコードの読み方：上2桁が有効数字、3桁目が乗数（×10ⁿ）。例：「472」→ 47 × 10² = 4.7kΩ")
                        HelpRow(icon: "person.text.rectangle", text: "マイナンバー（12桁）を入力すると3グループ分の抵抗値が計算され、合計抵抗値も表示されます。")
                        HelpRow(icon: "sparkles", text: "例：あなたのマイナンバーの抵抗値は何Ωでしょう？")
                    }

                    HelpSection(title: "　　カラーコード対応表") {
                        VStack(spacing: 4) {
                            ForEach(resistorColorRows, id: \.digit) { row in
                                HStack(spacing: 10) {
                                    Text(row.digit)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(row.textColor)
                                        .frame(width: 28, height: 28)
                                        .background(row.color)
                                        .cornerRadius(4)
                                    Text(row.name)
                                        .foregroundColor(Color(white: 0.85))
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                            }
                        }
                    }

                    Divider().background(Color(white: 0.3))

                    // ポケベル暗号
                    HelpSection(title: "📟 ポケベル暗号について") {
                        Text("1990年代、日本の若者がポケベル（ポケット呼出受信機）で使っていた数字の暗号です。GoroBellはこの文化にインスパイアされています。")
                            .foregroundColor(Color(white: 0.85))
                            .font(.system(size: 14))

                        VStack(spacing: 4) {
                            ForEach(pokebelCodes, id: \.code) { item in
                                HStack {
                                    Text(item.code)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.orange)
                                        .frame(width: 80, alignment: .leading)
                                    Text("→")
                                        .foregroundColor(Color(white: 0.5))
                                    Text(item.meaning)
                                        .foregroundColor(Color(white: 0.85))
                                        .font(.system(size: 14))
                                    Spacer()
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
    }

    private var resistorColorRows: [(digit: String, name: String, color: Color, textColor: Color)] = [
        ("0", "黒  × 1",         Color(white: 0.08),                                          .white),
        ("1", "茶  × 10",        Color(red: 0.45, green: 0.22, blue: 0.05),                  .white),
        ("2", "赤  × 100",       Color(red: 0.85, green: 0.1,  blue: 0.1),                   .white),
        ("3", "橙  × 1k",        Color(red: 1.0,  green: 0.5,  blue: 0.0),                   .black),
        ("4", "黄  × 10k",       Color(red: 1.0,  green: 0.85, blue: 0.0),                   .black),
        ("5", "緑  × 100k",      Color(red: 0.1,  green: 0.65, blue: 0.1),                   .white),
        ("6", "青  × 1M",        Color(red: 0.1,  green: 0.2,  blue: 0.9),                   .white),
        ("7", "紫  × 10M",       Color(red: 0.5,  green: 0.0,  blue: 0.8),                   .white),
        ("8", "灰  × 100M",      Color(white: 0.55),                                          .white),
        ("9", "白  × 1G",        Color.white,                                                 .black),
    ]

    private var readingRows: [(digit: String, readings: String)] = [
        ("0", "れ / ぜ / お / まる / ま"),
        ("1", "い / ひ / いち"),
        ("2", "に / ふ / ふた"),
        ("3", "さ / み / さん"),
        ("4", "し / よ / よん"),
        ("5", "ご / いつ"),
        ("6", "む / ろ / りく"),
        ("7", "な / しち / なな"),
        ("8", "は / や / はち"),
        ("9", "く / きゅ / こ"),
        ("-", "ー（区切り）"),
    ]

    private var pokebelCodes: [(code: String, meaning: String)] = [
        ("0840", "おはよう"),
        ("0833", "おやすみ"),
        ("8181", "バイバイ"),
        ("3470", "さよなら"),
        ("14106", "愛してる"),
        ("4649", "よろしく"),
        ("49", "至急"),
        ("5963", "ご苦労さん"),
        ("889", "はやく"),
        ("39", "サンキュー"),
        ("724", "なに"),
        ("5110", "ファイト"),
    ]
}

// MARK: - ヘルプセクション

struct HelpSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            content
        }
    }
}

struct HelpRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .foregroundColor(Color(white: 0.85))
                .font(.system(size: 14))
            Spacer()
        }
    }
}
