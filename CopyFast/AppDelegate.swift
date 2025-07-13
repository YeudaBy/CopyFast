import Foundation
import SwiftUI
import AppKit
import ServiceManagement
import CoreData // Import CoreData for NSFetchRequest
import UniformTypeIdentifiers // Import for UTType

// Key code for 'V'. This code is constant in macOS.
// A full list of key codes can be found in Carbon.framework/Headers/Events.h
let kVK_ANSI_V: UInt16 = 0x09

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover = NSPopover()
    var clipboardMonitor = ClipboardMonitor()
    // Reference to the global event monitor, so we can remove it when the app quits
    var globalHotkeyMonitor: Any?

    let persistenceController = PersistenceController.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupPopover()
        clipboardMonitor.startMonitoring()
        setupGlobalHotkey()
        
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to register as the main app: \(error)")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stopMonitoring()
        // Remove the global event monitor to prevent memory leaks or unexpected behavior
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.image?.isTemplate = true

            // Set action for left-click
            button.action = #selector(togglePopover(_:))
            button.target = self

            // Important! Enables receiving right-click events
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
    }

    private func setupPopover() {
        popover.contentViewController = NSHostingController(rootView:
                                                                HistoryView(
                                                                ).environment(\.managedObjectContext, persistenceController.container.viewContext)
        )
        popover.behavior = .transient // Popover disappears when clicking outside
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        // Check if the current event is a right-click or left-click
        let event = NSApp.currentEvent!
        if event.type == .rightMouseDown {
            // If it's a right-click, show the menu
            statusItem.menu = createMenu()
            // Perform a "click" on the button to display the menu immediately
            statusItem.button?.performClick(nil)
            // Optional: Remove the menu after it's shown to prevent a "sticky" state
            statusItem.menu = nil
        } else {
            // If it's a left-click (or called from hotkey), handle the popover as usual
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
                // Activate the application so the popover receives focus and keyboard events
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // Function to create the menu for right-click on the status bar button
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Add Export menu item
        let exportMenuItem = NSMenuItem(title: "Export Data...", action: #selector(exportData), keyEquivalent: "")
        exportMenuItem.target = self
        menu.addItem(exportMenuItem)

        menu.addItem(NSMenuItem.separator()) // Separator between items

        let quitMenuItem = NSMenuItem(title: "Quit CopyFast", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitMenuItem)

        return menu
    }

    private func setupGlobalHotkey() {
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }

            let commandKeyPressed = event.modifierFlags.contains(.command)
            let shiftKeyPressed = event.modifierFlags.contains(.shift)
            let vKeyPressed = event.keyCode == kVK_ANSI_V
            if commandKeyPressed && shiftKeyPressed && vKeyPressed {
                self.togglePopover(nil)
            }
        }
    }
    
    // MARK: - Export Data
    
    @objc private func exportData() {
        // Ensure UI operations are on the main thread
        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            savePanel.canCreateDirectories = true
            savePanel.showsTagField = false
            savePanel.nameFieldStringValue = "clipboard_data"
            
            // Use allowedContentTypes for macOS 12.0+
            savePanel.allowedContentTypes = [.json, .commaSeparatedText] // UTType for JSON and CSV

            savePanel.begin { (result) in
                if result == .OK {
                    guard let url = savePanel.url else { return }
                    
                    let fileExtension = url.pathExtension.lowercased()
                    
                    // Fetch all clipboard entries
                    let fetchRequest: NSFetchRequest<ClipboardEntry> = ClipboardEntry.fetchRequest()
                    do {
                        let entries = try self.persistenceController.container.viewContext.fetch(fetchRequest)
                        
                        var dataToExport: Data?
                        var error: Error?
                        
                        switch fileExtension {
                        case "json":
                            dataToExport = self.exportToJson(entries: entries)
                        case "csv":
                            dataToExport = self.exportToCsv(entries: entries)
                        default:
                            // This case should ideally not be reached if allowedContentTypes is set correctly
                            error = NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported file format selected."])
                        }
                        
                        if let data = dataToExport {
                            do {
                                try data.write(to: url)
                                print("Data exported successfully to: \(url.path)")
                                // Optionally, show a success message to the user
                            } catch let writeError {
                                print("Error writing file: \(writeError.localizedDescription)")
                                // Show error message to the user
                                self.showErrorAlert(message: "Failed to write file: \(writeError.localizedDescription)")
                            }
                        } else if let exportError = error {
                            print("Error during export: \(exportError.localizedDescription)")
                            self.showErrorAlert(message: "Failed to export data: \(exportError.localizedDescription)")
                        } else {
                            self.showErrorAlert(message: "No data to export or unknown error occurred.")
                        }
                        
                    } catch let fetchError {
                        print("Error fetching data: \(fetchError.localizedDescription)")
                        self.showErrorAlert(message: "Failed to fetch data for export: \(fetchError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func exportToJson(entries: [ClipboardEntry]) -> Data? {
        // Create a Codable struct to represent the data for JSON export
        struct ExportableEntry: Codable {
            let content: String?
            let type: String?
            let date: Date?
            let isFavorite: Bool
            let tags: String?
            // Add other properties you want to export
        }
        
        let exportableEntries = entries.map { entry in
            ExportableEntry(
                content: entry.content,
                type: entry.type,
                date: entry.date,
                isFavorite: entry.isFavorite,
                tags: entry.tags
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // For human-readable JSON
        encoder.dateEncodingStrategy = .iso8601 // Standard date format
        
        do {
            let jsonData = try encoder.encode(exportableEntries)
            return jsonData
        } catch {
            print("Error encoding JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func exportToCsv(entries: [ClipboardEntry]) -> Data? {
        // Define CSV header
        let header = "Content,Type,Date,IsFavorite,Tags\n"
        var csvString = header
        
        // Helper to escape CSV fields
        func escapeCsvField(_ field: String?) -> String {
            guard let field = field else { return "" }
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"") // Escape double quotes
            if escapedField.contains(",") || escapedField.contains("\n") || escapedField.contains("\"") {
                return "\"\(escapedField)\"" // Enclose in double quotes if it contains special characters
            }
            return escapedField
        }
        
        let dateFormatter = ISO8601DateFormatter() // Standard date format for CSV
        
        for entry in entries {
            let content = escapeCsvField(entry.content)
            let type = escapeCsvField(entry.type)
            let date = escapeCsvField(entry.date.map { dateFormatter.string(from: $0) })
            let isFavorite = entry.isFavorite ? "TRUE" : "FALSE"
            let tags = escapeCsvField(entry.tags)
            
            csvString += "\(content),\(type),\(date),\(isFavorite),\(tags)\n"
        }
        
        return csvString.data(using: .utf8)
    }
    
    // Helper to show an alert to the user
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Export Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

/*
Important Notes:
For the new features to work correctly, you must ensure your project is configured properly:

1.  **Entitlements:**
    If your application uses App Sandbox (highly recommended), you must add the following entitlements to your project's `.entitlements` file:
    * **For File Export (Saving to arbitrary locations):**
        You need to enable the "User Selected File" entitlement to allow `NSSavePanel` to function correctly in a sandboxed environment. In your Xcode project, go to your target's "Signing & Capabilities" tab, and add the "App Sandbox" capability if it's not already there. Then, under "File Access", ensure "User Selected Files" is set to "Read/Write".
    * For "Launch at Login" (`SMAppService`):
        No specific entitlement is needed for `SMAppService` itself, but the application must be properly code-signed.
    * For the global hotkey (`NSEvent.addGlobalMonitorForEvents`):
        No specific entitlement is needed, but the application will need to request "Accessibility" permissions from the user the first time it tries to use a global hotkey. If the hotkey doesn't work, instruct the user to go to:
        `System Settings > Privacy & Security > Accessibility`
        and enable your application there.

2.  **Code Signing:**
    Ensure your application is properly code-signed. `SMAppService` relies on a valid signature to enable launch at login.
*/
