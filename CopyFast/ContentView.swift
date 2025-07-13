//
//  ContentView.swift
//  CopyFast
//
//  Created by Yeuda Borodyanski on 13/07/2025.
//

import SwiftUI
import SwiftData

struct CopiedTextItem: View {
    var body: some View {
        HStack {
            Text("1")
                .font(.caption2)
            Text("Some copied Text.")
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        List() {
            CopiedTextItem()
            CopiedTextItem()
            CopiedTextItem()
        }
    }

    
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
