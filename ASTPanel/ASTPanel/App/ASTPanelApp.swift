//
//  ASTPanelApp.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

@main
struct ASTPanelApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(networkMonitor)
                .preferredColorScheme(.light) // Force light mode initially
        }
    }
}
