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

    private let memosKey = "memos"

    private func loadMemos() {
        memos = UserDefaults.standard.stringArray(forKey: memosKey) ?? []
    }

    private func saveMemos() {
        UserDefaults.standard.set(memos, forKey: memosKey)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    TextField("メモを入力", text: $text)
                        .textFieldStyle(.roundedBorder)
                    Button("追加") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        memos.insert(trimmed, at: 0)
                        text = ""
                    }
                    .buttonStyle(.borderedProminent)
                }

                List {
                    ForEach(memos, id: \.self) { memo in
                        Text(memo)
                    }
                    .onDelete { indexSet in
                        memos.remove(atOffsets: indexSet)
                    }
                }
            }
            .padding()
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

