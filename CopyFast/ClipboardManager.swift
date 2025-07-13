import Foundation
import AppKit

class ClipboardManager {
    static let shared = ClipboardManager()
    private init() {}

    func saveCopiedText() {
        let context = PersistenceController.shared.container.viewContext
        let pasteboard = NSPasteboard.general
        let newEntry = ClipboardEntry(context: context)
        
        if let imageData = pasteboard.data(forType: .tiff) {
            newEntry.data = imageData
            newEntry.type = "image"
            newEntry.content = "[תמונה]"
        } else if let copiedText = pasteboard.string(forType: .string) {
            newEntry.content = copiedText
            newEntry.type = "text"
            newEntry.data = nil
        }

        newEntry.id = UUID()
        newEntry.date = Date()
        newEntry.isFavorite = false

        do {
            try context.save()
            print("💾 נשמר בהצלחה!")
        } catch {
            print("❌ שגיאה בשמירה: \(error)")
        }
    }
}

