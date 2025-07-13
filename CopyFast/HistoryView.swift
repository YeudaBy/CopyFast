import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText: String = ""
    @State private var showOnlyFavorites = false
    @State private var tagFilter: String = ""


    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<ClipboardEntry>

    var filteredEntries: [ClipboardEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty || (entry.content ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesFavorite = !showOnlyFavorites || entry.isFavorite
            let matchesTag = tagFilter.isEmpty || (entry.tags ?? "").localizedCaseInsensitiveContains(tagFilter)
            return matchesSearch && matchesFavorite && matchesTag
        }
    }


    var body: some View {
            
            VStack(spacing: 0) {
                
                HStack {
                    TextField("חיפוש...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Toggle("⭐️ מועדפים", isOn: $showOnlyFavorites)
                    TextField("תג...", text: $tagFilter)
                }
                .padding()
                
                List {
                    ForEach(filteredEntries) { entry in
                        ClipRowView(entry: entry)
                    }
                    .onDelete(perform: deleteItems)
                }
            }.frame(minWidth: 600)

            }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredEntries[$0] }.forEach(self.viewContext.delete)
            try? self.viewContext.save()
        }
    }
}
