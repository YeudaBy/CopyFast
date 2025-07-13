import Foundation
import SwiftUI
import AppKit
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover = NSPopover()
    var clipboardMonitor = ClipboardMonitor()
    
    let persistenceController = PersistenceController.shared

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupPopover()
        clipboardMonitor.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stopMonitoring()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    private func setupPopover() {
        popover.contentViewController = NSHostingController(rootView:
                                                                HistoryView(
        ).environment(\.managedObjectContext, persistenceController.container.viewContext)
        )

        popover.behavior = .transient // נסגר כשמקליקים מחוץ
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
