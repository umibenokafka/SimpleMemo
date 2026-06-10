import SwiftUI

// メモ1件分のデータ構造
struct Memo: Identifiable, Codable, Equatable {
    // メモを一意に区別するID
    let id: UUID

    // メモのタイトル
    var title: String

    // メモの本文
    var body: String

    // メモのカテゴリ
    var category: String

    // メモを作成した日時
    var createdAt: Date

    // 完了済みかどうか
    var isDone: Bool

    // Memo同士を比較するときは、idが同じなら同じメモと判断する
    static func == (lhs: Memo, rhs: Memo) -> Bool {
        lhs.id == rhs.id
    }
}

// SimpleMemoのメイン画面
struct ContentView: View {

    // タイトル入力欄の中身
    @State private var title: String = ""

    // 本文入力欄の中身
    @State private var bodyText: String = ""

    // 新規作成・編集中メモのカテゴリ
    @State private var category: String = "未分類"

    // メモ一覧
    @State private var memos: [Memo] = []

    // 編集中のメモID。nilなら新規追加モード
    @State private var editingMemoID: UUID? = nil

    // 検索欄の文字
    @State private var searchText: String = ""

    // 表示するカテゴリ
    @State private var selectedCategory: String = "すべて"

    // ダークモードON/OFF
    @State private var isDarkMode: Bool = false

    // trueなら新しい順、falseなら古い順
    @State private var sortNewestFirst: Bool = true

    // UserDefaultsに保存するときのキー
    private let memosKey = "memos_v2"

    // 選択できるカテゴリ一覧
    private let categories = [
        "すべて",
        "未分類",
        "仕事",
        "学習",
        "買い物",
        "アイデア"
    ]

    // 検索・カテゴリ・並び替えを反映したメモ一覧
    private var filteredMemos: [Memo] {
        var result = memos

        // カテゴリが「すべて」以外なら、そのカテゴリだけに絞る
        if selectedCategory != "すべて" {
            result = result.filter { $0.category == selectedCategory }
        }

        // 検索文字がある場合、タイトル・本文・カテゴリから検索する
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.body.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        // 日付で並び替える
        result.sort {
            sortNewestFirst
            ? $0.createdAt > $1.createdAt
            : $0.createdAt < $1.createdAt
        }

        return result
    }

    // 保存済みメモを読み込む
    private func loadMemos() {
        guard let data = UserDefaults.standard.data(forKey: memosKey) else {
            memos = []
            return
        }

        do {
            memos = try JSONDecoder().decode([Memo].self, from: data)
        } catch {
            memos = []
        }
    }

    // メモ一覧を保存する
    private func saveMemos() {
        do {
            let data = try JSONEncoder().encode(memos)
            UserDefaults.standard.set(data, forKey: memosKey)
        } catch {
            print("保存に失敗しました")
        }
    }

    // メモを追加、または編集中のメモを更新する
    private func addOrUpdateMemo() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        // タイトルも本文も空なら何もしない
        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else { return }

        // editingMemoIDがある場合は編集モード
        if let id = editingMemoID,
           let index = memos.firstIndex(where: { $0.id == id }) {

            memos[index].title = trimmedTitle.isEmpty ? "無題" : trimmedTitle
            memos[index].body = trimmedBody
            memos[index].category = category

            // 編集終了
            editingMemoID = nil

        } else {
            // editingMemoIDがnilなら新規追加
            let newMemo = Memo(
                id: UUID(),
                title: trimmedTitle.isEmpty ? "無題" : trimmedTitle,
                body: trimmedBody,
                category: category,
                createdAt: Date(),
                isDone: false
            )

            // 新しいメモを先頭に追加
            memos.insert(newMemo, at: 0)
        }

        // 入力欄を空に戻す
        title = ""
        bodyText = ""
        category = "未分類"
    }

    // メモをタップしたときに編集モードへ入る
    private func startEditing(_ memo: Memo) {
        title = memo.title
        bodyText = memo.body
        category = memo.category
        editingMemoID = memo.id
    }

    // メモを削除する
    private func deleteMemo(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredMemos[$0].id }

        memos.removeAll { memo in
            idsToDelete.contains(memo.id)
        }
    }

    // メモを並び替える
    private func moveMemo(from source: IndexSet, to destination: Int) {
        memos.move(fromOffsets: source, toOffset: destination)
    }

    // 完了・未完了を切り替える
    private func toggleDone(_ memo: Memo) {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        memos[index].isDone.toggle()
    }

    // 画面の中身
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // ダークモード切り替え
                Toggle("ダークモード", isOn: $isDarkMode)
                    .padding(.horizontal)

                // タイトル入力欄
                TextField("タイトル", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // 本文入力欄
                TextField("メモ内容", text: $bodyText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // 新規作成・編集用カテゴリ選択
                Picker("カテゴリ", selection: $category) {
                    ForEach(categories.filter { $0 != "すべて" }, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 追加・更新ボタン
                Button(editingMemoID == nil ? "追加" : "更新") {
                    addOrUpdateMemo()
                }
                .buttonStyle(.borderedProminent)

                // 検索欄
                TextField("検索", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                // 表示カテゴリ選択
                Picker("表示カテゴリ", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                // 並び順切り替え
                Toggle("新しい順で表示", isOn: $sortNewestFirst)
                    .padding(.horizontal)

                // メモ一覧
                List {
                    ForEach(filteredMemos) { memo in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                // メモタイトル
                                Text(memo.title)
                                    .font(.headline)

                                Spacer()

                                // 完了ボタン
                                Button {
                                    toggleDone(memo)
                                } label: {
                                    Image(systemName: memo.isDone ? "checkmark.circle.fill" : "circle")
                                }
                            }

                            // 本文が空でなければ表示
                            if !memo.body.isEmpty {
                                Text(memo.body)
                                    .font(.body)
                            }

                            HStack {
                                // カテゴリ表示
                                Text(memo.category)
                                    .font(.caption)

                                Spacer()

                                // 作成日時表示
                                Text(memo.createdAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        // タップできる範囲を広げる
                        .contentShape(Rectangle())

                        // タップしたら編集モードへ
                        .onTapGesture {
                            startEditing(memo)
                        }
                    }
                    // スワイプ削除
                    .onDelete(perform: deleteMemo)

                    // 編集モードで並び替え
                    .onMove(perform: moveMemo)
                }
            }
            .navigationTitle("SimpleMemo")

            // 並び替え用の編集ボタン
            .toolbar {
                EditButton()
            }

            // 画面表示時にメモを読み込む
            .onAppear {
                loadMemos()
            }

            // memosが変わったら自動保存
            .onChange(of: memos) {
                saveMemos()
            }

            // ダークモード反映
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    ContentView()
}
