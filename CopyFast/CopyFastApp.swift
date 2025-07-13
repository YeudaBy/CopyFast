//
//  CopyFastApp.swift
//  CopyFast
//
//  Created by Yeuda Borodyanski on 13/07/2025.
//

import SwiftUI
import SwiftData
import ServiceManagement


@main
struct CopyFastApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        let persistenceController = PersistenceController.shared
    

        var body: some Scene {
            Settings {
                EmptyView()
            }
        }
}

struct HomeView: View {
    
    var loginStatusText: some View {
        if SMAppService.mainApp.status == .notRegistered {
            return Text("❌ App can not be opened automaticly at login. Please register it manually in the menu bar.")
        } else {
            return Text("✅ App registered automaticly at login.")
        }
    }
    
    var menuBarHint: some View {
        HStack {
            Text("Search the ")
            Image(systemName: "doc.on.clipboard")
            Text(" icon in the menu bar to get started.")
        }
        .foregroundColor(.secondary)
        .font(.title3)
    }
    
    
    var body: some View {
        VStack {
            Spacer()
            Image("appstore")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.bottom, 20)
            
            Text("Welcome to CopyFast!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.yellow)
                .padding(.bottom, 8)

            Text("A simple, lightweight app to store and manage you clipboard content.")
                .foregroundColor(.secondary)
                .font(.title)
                .padding(.bottom, 16)

            menuBarHint
            Spacer()
            loginStatusText
            Spacer()
            Text("Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")")
                .foregroundColor(.secondary)
            Text("2025 © CopyFast. All rights reserved.")
                .foregroundColor(.secondary)
                .font(.caption)
            Link("@YeudaBy", destination: URL(string: "https://yeudaby.com")!)
                .foregroundColor(.blue)
                .font(.caption)
                .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea()
    }
}
