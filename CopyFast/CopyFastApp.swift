//
//  CopyFastApp.swift
//  CopyFast
//
//  Created by Yeuda Borodyanski on 13/07/2025.
//

import SwiftUI
import SwiftData

@main
struct CopyFastApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        let persistenceController = PersistenceController.shared

        var body: some Scene {
            WindowGroup {
                VStack {
                    Text("Hello")
                }
            }
        }
}
