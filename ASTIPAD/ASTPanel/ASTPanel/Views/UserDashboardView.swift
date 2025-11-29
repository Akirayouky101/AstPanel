//
//  UserDashboardView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedSection: String? = "dashboard"
    @State private var tasks: [WorkTask] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            // Sidebar
            List {
                NavigationLink(tag: "dashboard", selection: $selectedSection) {
                    UserDashboardContent(tasks: $tasks, selectedSection: $selectedSection)
                } label: {
                    Label("Dashboard", systemImage: "house.fill")
                }
                
                NavigationLink(tag: "my-tasks", selection: $selectedSection) {
                    UserTasksView(tasks: $tasks)
                } label: {
                    Label("Le Mie Lavorazioni", systemImage: "list.clipboard.fill")
                }
                
                NavigationLink(tag: "calendar", selection: $selectedSection) {
                    Text("Calendario - In arrivo")
                } label: {
                    Label("Il Mio Calendario", systemImage: "calendar")
                }
                
                NavigationLink(tag: "requests", selection: $selectedSection) {
                    UserRequestsView()
                } label: {
                    Label("Le Mie Richieste", systemImage: "doc.text.fill")
                }
                
                NavigationLink(tag: "communications", selection: $selectedSection) {
                    UserCommunicationsView()
                } label: {
                    Label("Comunicazioni", systemImage: "message.fill")
                }
                
                NavigationLink(tag: "profile", selection: $selectedSection) {
                    UserProfileView()
                } label: {
                    Label("Il Mio Profilo", systemImage: "person.fill")
                }
                
                Section {
                    Button(action: { authService.logout() }) {
                        Label("Logout", systemImage: "arrow.left.square.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Pannello Utente")
            .listStyle(.sidebar)
            
            // Content based on selection
            Group {
                switch selectedSection {
                case "dashboard":
                    UserDashboardContent(tasks: $tasks, selectedSection: $selectedSection)
                case "my-tasks":
                    UserTasksView(tasks: $tasks)
                case "calendar":
                    UserCalendarView(tasks: $tasks)
                case "requests":
                    UserRequestsView()
                case "communications":
                    UserCommunicationsView()
                case "profile":
                    UserProfileView()
                default:
                    Text("Funzionalità in arrivo...")
                }
            }
        }
        .navigationViewStyle(.columns)
        .onAppear {
            loadUserTasks()
        }
    }
    
    private func loadUserTasks() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        Task {
            do {
                let allTasks = try await SupabaseService.shared.select(
                    from: "tasks",
                    orderBy: "created_at"
                ) as [WorkTask]
                
                // Filter tasks for current user
                await MainActor.run {
                    self.tasks = allTasks.filter { task in
                        task.assignedUserId == userId
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
