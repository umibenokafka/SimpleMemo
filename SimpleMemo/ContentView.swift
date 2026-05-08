//
//  ContentView.swift
//  SimpleMemo
//
//  Created by 鈴木光央 on 2026/02/07.
//

import SwiftUI

struct ContentView: View {

    @State private var text: String = ""

    @State private var memos: [String] = []

    @State private var editingIndex: Int? = nil

    private let memosKey = "memos"

    private func loadMemos() {

        memos = UserDefaults.standard.stringArray(forKey: memosKey) ?? []

    }

    private func saveMemos() {

        UserDefaults.standard.set(memos, forKey: memosKey)

    }

    private func addOrUpdateMemo() {

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return }

        if let index = editingIndex {

            memos[index] = trimmed

            editingIndex = nil

        } else {

            memos.insert(trimmed, at: 0)

        }

        text = ""

    }

    private func deleteMemo(at offsets: IndexSet) {

        memos.remove(atOffsets: offsets)

    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 12) {

                HStack {

                    TextField("メモを入力", text: $text)

                        .textFieldStyle(.roundedBorder)

                    Button(editingIndex == nil ? "追加" : "更新") {

                        addOrUpdateMemo()

                    }

                    .buttonStyle(.borderedProminent)

                }

                .padding(.horizontal)

                List {

                    ForEach(memos.indices, id: \.self) { index in

                        Text(memos[index])

                            .onTapGesture {

                                text = memos[index]

                                editingIndex = index

                            }

                    }

                    .onDelete(perform: deleteMemo)

                }

            }

            .navigationTitle("SimpleMemo")

            .onAppear {

                loadMemos()

            }

            .onChange(of: memos) {

                saveMemos()

            }

        }

    }

}

#Preview {

    ContentView()

}
