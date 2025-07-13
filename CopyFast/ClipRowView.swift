import SwiftUI
import AppKit

struct ClipRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var entry: ClipboardEntry

    @State private var showingTagPrompt = false
    @State private var newTag = ""
    @State private var checkmarkOpacity: Double = 0.0 // State to control the checkmark's opacity

    var body: some View {
        ZStack { // Use ZStack to overlay the checkmark animation
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
            .contentShape(Rectangle())
            .onTapGesture {
                pasteEntry()
            }

            // Checkmark animation overlay
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
                .opacity(checkmarkOpacity)
                .animation(.easeOut(duration: 0.5), value: checkmarkOpacity) // Animate opacity changes
        }
    }

    private func toggleFavorite() {
        entry.isFavorite.toggle()
        try? viewContext.save()
    }

    private func pasteEntry() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if entry.type == "image", let data = entry.data, let nsImage = NSImage(data: data) {
            pasteboard.writeObjects([nsImage])
        } else if let content = entry.content {
            pasteboard.setString(content, forType: .string)
        }

        // Trigger the checkmark animation
        checkmarkOpacity = 1.0 // Make it fully visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { // After 0.8 seconds
            checkmarkOpacity = 0.0 // Fade it out
        }
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
