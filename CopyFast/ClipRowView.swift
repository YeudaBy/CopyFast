import SwiftUI
import AppKit

struct ClipRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: ClipboardEntry

    @State private var showingTagPrompt = false
    @State private var newTag = ""

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if entry.type == "image", let data = entry.data, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                } else if let content = entry.content {
                    LinkTextView(text: content)
                        .lineLimit(2)
                        .font(.body)
                } else {
                    Text("")
                }

                Text(entry.date ?? Date(), style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: toggleFavorite) {
                Image(systemName: entry.isFavorite ? "star.fill" : "star")
                    .foregroundColor(entry.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: pasteEntry) {
                Image(systemName: "doc.on.clipboard")
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                newTag = ""
                showingTagPrompt = true
            }) {
                Image(systemName: "tag")
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingTagPrompt) {
                TagPromptView(newTag: $newTag, onComplete: { tag in
                    if !tag.isEmpty {
                        entry.tags = (entry.tags?.isEmpty ?? true) ? tag : (entry.tags! + "," + tag)
                        try? viewContext.save()
                    }
                    showingTagPrompt = false
                }, onCancel: {
                    showingTagPrompt = false
                })
                .frame(width: 300, height: 120)
                .padding()
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleFavorite() {
        entry.isFavorite.toggle()
        try? viewContext.save()
    }

    private func pasteEntry() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(entry.content ?? "", forType: .string)
    }
}

struct TagPromptView: View {
    @Binding var newTag: String
    var onComplete: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("הוסף תגית")
                .font(.headline)
            TextField("תגית חדשה", text: $newTag)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            HStack {
                Button("ביטול", action: onCancel)
                Spacer()
                Button("אישור") {
                    onComplete(newTag.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}
