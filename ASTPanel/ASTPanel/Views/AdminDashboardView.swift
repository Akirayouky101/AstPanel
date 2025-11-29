//
//  AdminDashboardView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab: AdminTab = .dashboard
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Section("Panoramica") {
                    NavigationLink(value: AdminTab.dashboard) {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                }
                
                Section("Gestione") {
                    NavigationLink(value: AdminTab.tasks) {
                        Label("Lavorazioni", systemImage: "list.bullet.clipboard")
                    }
                    
                    NavigationLink(value: AdminTab.users) {
                        Label("Utenti", systemImage: "person.2.fill")
                    }
                    
                    NavigationLink(value: AdminTab.clients) {
                        Label("Clienti", systemImage: "building.2.fill")
                    }
                    
                    NavigationLink(value: AdminTab.teams) {
                        Label("Squadre", systemImage: "person.3.fill")
                    }
                    
                    NavigationLink(value: AdminTab.warehouse) {
                        Label("Magazzino", systemImage: "shippingbox.fill")
                    }
                }
                
                Section("Comunicazione") {
                    NavigationLink(value: AdminTab.communications) {
                        Label("Comunicazioni", systemImage: "envelope.fill")
                    }
                    
                    NavigationLink(value: AdminTab.requests) {
                        Label("Richieste", systemImage: "doc.text.fill")
                    }
                }
                
                Section("Tools") {
                    NavigationLink(value: AdminTab.calendar) {
                        Label("Calendario", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("AST Panel")
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
                    AdminDashboardContentView()
                case .tasks:
                    TasksListView()
                case .users:
                    UsersListView()
                case .clients:
                    ClientsListView()
                case .teams:
                    AdminTeamsView()
                case .warehouse:
                    AdminComponentsView()
                case .communications:
                    CommunicationsListView()
                case .requests:
                    RequestsListView()
                case .calendar:
                    CalendarView()
                }
            }
        }
    }
}

enum AdminTab: Hashable {
    case dashboard
    case tasks
    case users
    case clients
    case teams
    case warehouse
    case communications
    case requests
    case calendar
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthService.shared)
}
