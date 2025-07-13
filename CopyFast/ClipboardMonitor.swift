import Foundation
import AppKit

class ClipboardMonitor {
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            ClipboardManager.shared.saveCopiedText()
        }
    }
}
