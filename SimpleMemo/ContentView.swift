import SwiftUI

struct Memo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var body: String
    var category: String
    var createdAt: Date
    var isDone: Bool

    static func == (lhs: Memo, rhs: Memo) -> Bool {
        lhs.id == rhs.id
    }
}

struct ContentView: View {
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var category: String = "未分類"
    @State private var memos: [Memo] = []
    @State private var editingMemoID: UUID? = nil
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "すべて"
    @State private var isDarkMode: Bool = false
    @State private var sortNewestFirst: Bool = true

    private let memosKey = "memos_v2"

    private let categories = [
        "すべて",
        "未分類",
        "仕事",
        "学習",
        "買い物",
        "アイデア"
    ]

    private var filteredMemos: [Memo] {
        var result = memos

        if selectedCategory != "すべて" {
            result = result.filter { $0.category == selectedCategory }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.body.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        result.sort {
            sortNewestFirst
            ? $0.createdAt > $1.createdAt
            : $0.createdAt < $1.createdAt
        }

        return result
    }

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

    private func saveMemos() {
        do {
            let data = try JSONEncoder().encode(memos)
            UserDefaults.standard.set(data, forKey: memosKey)
        } catch {
            print("保存に失敗しました")
        }
    }

    private func addOrUpdateMemo() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else { return }

        if let id = editingMemoID,
           let index = memos.firstIndex(where: { $0.id == id }) {

            memos[index].title = trimmedTitle.isEmpty ? "無題" : trimmedTitle
            memos[index].body = trimmedBody
            memos[index].category = category
            editingMemoID = nil

        } else {
            let newMemo = Memo(
                id: UUID(),
                title: trimmedTitle.isEmpty ? "無題" : trimmedTitle,
                body: trimmedBody,
                category: category,
                createdAt: Date(),
                isDone: false
            )

            memos.insert(newMemo, at: 0)
        }

        title = ""
        bodyText = ""
        category = "未分類"
    }

    private func startEditing(_ memo: Memo) {
        title = memo.title
        bodyText = memo.body
        category = memo.category
        editingMemoID = memo.id
    }

    private func deleteMemo(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredMemos[$0].id }

        memos.removeAll { memo in
            idsToDelete.contains(memo.id)
        }
    }

    private func moveMemo(from source: IndexSet, to destination: Int) {
        memos.move(fromOffsets: source, toOffset: destination)
    }

    private func toggleDone(_ memo: Memo) {
        guard let index = memos.firstIndex(where: { $0.id == memo.id }) else { return }
        memos[index].isDone.toggle()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                Toggle("ダークモード", isOn: $isDarkMode)
                    .padding(.horizontal)

                TextField("タイトル", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                TextField("メモ内容", text: $bodyText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Picker("カテゴリ", selection: $category) {
                    ForEach(categories.filter { $0 != "すべて" }, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Button(editingMemoID == nil ? "追加" : "更新") {
                    addOrUpdateMemo()
                }
                .buttonStyle(.borderedProminent)

                TextField("検索", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Picker("表示カテゴリ", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { item in
                        Text(item)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                Toggle("新しい順で表示", isOn: $sortNewestFirst)
                    .padding(.horizontal)

                List {
                    ForEach(filteredMemos) { memo in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(memo.title)
                                    .font(.headline)

                                Spacer()

                                Button {
                                    toggleDone(memo)
                                } label: {
                                    Image(systemName: memo.isDone ? "checkmark.circle.fill" : "circle")
                                }
                            }

                            if !memo.body.isEmpty {
                                Text(memo.body)
                                    .font(.body)
                            }

                            HStack {
                                Text(memo.category)
                                    .font(.caption)

                                Spacer()

                                Text(memo.createdAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            startEditing(memo)
                        }
                    }
                    .onDelete(perform: deleteMemo)
                    .onMove(perform: moveMemo)
                }
            }
            .navigationTitle("SimpleMemo")
            .toolbar {
                EditButton()
            }
            .onAppear {
                loadMemos()
            }
            .onChange(of: memos) {
                saveMemos()
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    ContentView()
}
