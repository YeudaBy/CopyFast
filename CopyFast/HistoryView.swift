import SwiftUI
import CoreData
import AppKit // Import AppKit to access NSWindow

// Helper component to access and modify NSWindow properties
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Defer window access as the view might not yet be in a window
        DispatchQueue.main.async {
            if let window = view.window {
                // Set the window as non-opaque to allow transparency
                window.isOpaque = false
                // Set the window's background color to clear
                window.backgroundColor = .clear
                
                // Optional: For a completely transparent title bar and content extending into it
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
        }
    }
}

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText: String = ""
    @State private var showOnlyFavorites = false
    @State private var selectedTag: String = "All Tags" // Default option for the picker

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClipboardEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<ClipboardEntry>

    // Computed property to extract all unique tags
    var allUniqueTags: [String] {
        var tagsSet = Set<String>()
        for entry in entries {
            if let tagsString = entry.tags, !tagsString.isEmpty {
                let tagsArray = tagsString.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                tagsSet.formUnion(tagsArray)
            }
        }
        // Sort tags alphabetically and add "All Tags" as the first option
        return ["All Tags"] + tagsSet.sorted()
    }

    var filteredEntries: [ClipboardEntry] {
        entries.filter { entry in
            let matchesSearch = searchText.isEmpty || (entry.content ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesFavorite = !showOnlyFavorites || entry.isFavorite
            
            // Tag filtering logic for the picker
            let matchesTag: Bool
            if selectedTag == "All Tags" {
                matchesTag = true // Show all entries if "All Tags" is selected
            } else if let entryTags = entry.tags {
                // Check if the entry's tags contain the selected tag
                let entryTagsArray = entryTags.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                matchesTag = entryTagsArray.contains(selectedTag)
            } else {
                matchesTag = false // Entry has no tags, and a specific tag is selected
            }
            
            return matchesSearch && matchesFavorite && matchesTag
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header / Search Bar Section
            HStack {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.trailing, 8) // Add some spacing after the search field
                
                Toggle(isOn: $showOnlyFavorites) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                .toggleStyle(.button) // Make the toggle look like a button
                .help("Show only favorites") // Tooltip for accessibility
                .padding(.trailing, 8)

                // Tag Picker
                Picker("Tag", selection: $selectedTag) {
                    ForEach(allUniqueTags, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                .background(Capsule().fill(Color.accentColor.opacity(0.1))) // Subtle background for the picker
                .cornerRadius(8) // Rounded corners for the picker background
                .padding(.trailing, 8)
            }
            .padding(12) // Padding around the entire header HStack
            .background(Material.thin) // Top bar with subtle blur
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2) // Subtle shadow, applied correctly
            
            // List of Clipboard Entries
            List {
                ForEach(filteredEntries) { entry in
                    ClipRowView(entry: entry)
                        .listRowBackground(Color.clear) // Ensure row background is transparent to see list background
                        .padding(.vertical, 4) // Add vertical padding to each row
                }
                .onDelete(perform: deleteItems)
            }.background(Material.thin) // Top bar with subtle blur
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .listStyle(.plain) // Use plain list style for more control over appearance
            // List background will come from the main VStack
        }
        .frame(minWidth: 600, minHeight: 300)
        .background(Material.ultraThin) // Transparent blurred background for the entire app
        .background(WindowAccessor()) // Attach the WindowAccessor
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredEntries[$0] }.forEach(self.viewContext.delete)
            try? self.viewContext.save()
        }
    }
}
