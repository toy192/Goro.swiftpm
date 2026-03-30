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
