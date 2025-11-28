//
//  ContentView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if authService.currentUser?.ruolo == "admin" {
                    AdminDashboardView()
                } else {
                    UserDashboardView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            authService.checkAuthStatus()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
}
