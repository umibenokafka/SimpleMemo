//
//  ContentView.swift
//  SimpleMemo
//
//  Created by 鈴木光央 on 2026/02/07.
//

import SwiftUI

struct ContentView: View {
    @State private var text = ""
    @State private var memos: [String] = []

    private let memosKey = "memos"

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                HStack {
                    TextField("メモを入力", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("追加") {
                        addMemo()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                List {
                    ForEach(memos, id: \.self) { memo in
                        Text(memo)
                    }
                    .onDelete(perform: deleteMemo)
                }
            }
            .navigationTitle("SimpleMemo")
        }
        .onAppear {
            loadMemos()
        }
        .onChange(of: memos) {
            saveMemos()
        }
    }

    private func addMemo() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        memos.insert(trimmed, at: 0)
        text = ""
    }

    private func deleteMemo(at offsets: IndexSet) {
        memos.remove(atOffsets: offsets)
    }

    private func loadMemos() {
        memos = UserDefaults.standard.stringArray(forKey: memosKey) ?? []
    }

    private func saveMemos() {
        UserDefaults.standard.set(memos, forKey: memosKey)
    }
}

#Preview {
    ContentView()
}
