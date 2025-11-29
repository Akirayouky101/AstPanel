//
//  UserDashboardView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab: UserTab = .dashboard
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Section("Panoramica") {
                    NavigationLink(value: UserTab.dashboard) {
                        Label("Dashboard", systemImage: "house.fill")
                    }
                }
                
                Section("Le Mie Attività") {
                    NavigationLink(value: UserTab.myTasks) {
                        Label("Lavorazioni", systemImage: "list.bullet.clipboard")
                    }
                    
                    NavigationLink(value: UserTab.calendar) {
                        Label("Calendario", systemImage: "calendar")
                    }
                }
                
                Section("Comunicazione") {
                    NavigationLink(value: UserTab.communications) {
                        Label("Comunicazioni", systemImage: "envelope.fill")
                    }
                    
                    NavigationLink(value: UserTab.requests) {
                        Label("Richieste", systemImage: "doc.text.fill")
                    }
                }
            }
            .navigationTitle("Pannello Utente")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if let user = authService.currentUser {
                            Text(user.fullName)
                            Text(user.email)
                                .font(.caption)
                            
                            Divider()
                        }
                        
                        Button(role: .destructive) {
                            authService.logout()
                        } label: {
                            Label("Logout", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                    }
                }
            }
        } detail: {
            // Detail view based on selected tab
            Group {
                switch selectedTab {
                case .dashboard:
                    UserDashboardContentView()
                case .myTasks:
                    MyTasksListView()
                case .calendar:
                    CalendarView()
                case .communications:
                    CommunicationsListView()
                case .requests:
                    MyRequestsListView()
                }
            }
        }
    }
}

enum UserTab: Hashable {
    case dashboard
    case myTasks
    case calendar
    case communications
    case requests
}

#Preview {
    UserDashboardView()
        .environmentObject(AuthService.shared)
}
