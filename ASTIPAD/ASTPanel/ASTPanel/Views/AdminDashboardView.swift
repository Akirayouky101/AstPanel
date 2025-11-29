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
        NavigationView {
            // Sidebar
            List {
                Section("Panoramica") {
                    Button {
                        selectedTab = .dashboard
                    } label: {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                }
                
                Section("Gestione") {
                    Button {
                        selectedTab = .tasks
                    } label: {
                        Label("Lavorazioni", systemImage: "list.bullet.clipboard")
                    }
                    
                    Button {
                        selectedTab = .users
                    } label: {
                        Label("Utenti", systemImage: "person.2.fill")
                    }
                    
                    Button {
                        selectedTab = .clients
                    } label: {
                        Label("Clienti", systemImage: "building.2.fill")
                    }
                    
                    Button {
                        selectedTab = .teams
                    } label: {
                        Label("Squadre", systemImage: "person.3.fill")
                    }
                    
                    Button {
                        selectedTab = .warehouse
                    } label: {
                        Label("Magazzino", systemImage: "shippingbox.fill")
                    }
                }
                
                Section("Comunicazione") {
                    Button {
                        selectedTab = .communications
                    } label: {
                        Label("Comunicazioni", systemImage: "envelope.fill")
                    }
                    
                    Button {
                        selectedTab = .requests
                    } label: {
                        Label("Richieste", systemImage: "doc.text.fill")
                    }
                }
                
                Section("Tools") {
                    Button {
                        selectedTab = .calendar
                    } label: {
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
                    TeamsListView()
                case .warehouse:
                    WarehouseListView()
                case .communications:
                    CommunicationsListView()
                case .requests:
                    RequestsListView()
                case .calendar:
                    CalendarView()
                }
            }
        }
        .navigationViewStyle(.columns)
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
