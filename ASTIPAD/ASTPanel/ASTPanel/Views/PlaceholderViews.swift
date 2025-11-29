//
//  PlaceholderViews.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//  Temporary placeholder views - To be implemented
//

import SwiftUI

// MARK: - Admin Views
struct AdminDashboardContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Statistiche e panoramica generale")
                    .foregroundColor(.secondary)
                
                // TODO: Implement stats cards, charts, recent activities
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

struct TasksListView: View {
    var body: some View {
        List {
            Text("Elenco Lavorazioni")
        }
        .navigationTitle("Lavorazioni")
        .toolbar {
            Button {
                // Add task
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct UsersListView: View {
    var body: some View {
        List {
            Text("Elenco Utenti")
        }
        .navigationTitle("Utenti")
        .toolbar {
            Button {
                // Add user
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct ClientsListView: View {
    var body: some View {
        List {
            Text("Elenco Clienti")
        }
        .navigationTitle("Clienti")
        .toolbar {
            Button {
                // Add client
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct TeamsListView: View {
    var body: some View {
        List {
            Text("Elenco Squadre")
        }
        .navigationTitle("Squadre")
        .toolbar {
            Button {
                // Add team
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct WarehouseListView: View {
    var body: some View {
        List {
            Text("Magazzino Componenti")
        }
        .navigationTitle("Magazzino")
        .toolbar {
            Button {
                // Add component
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct CommunicationsListView: View {
    var body: some View {
        List {
            Text("Comunicazioni")
        }
        .navigationTitle("Comunicazioni")
        .toolbar {
            Button {
                // New communication
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct RequestsListView: View {
    var body: some View {
        List {
            Text("Tutte le Richieste")
        }
        .navigationTitle("Richieste")
    }
}

struct CalendarView: View {
    var body: some View {
        VStack {
            Text("Calendario Lavorazioni")
                .font(.title)
        }
        .navigationTitle("Calendario")
    }
}

// MARK: - User Views
struct UserDashboardContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Il Mio Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Le tue attività e statistiche")
                    .foregroundColor(.secondary)
                
                // TODO: Implement user stats, today's tasks, recent updates
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

struct MyTasksListView: View {
    var body: some View {
        List {
            Text("Le Mie Lavorazioni")
        }
        .navigationTitle("Le Mie Lavorazioni")
    }
}

struct MyRequestsListView: View {
    var body: some View {
        List {
            Text("Le Mie Richieste")
        }
        .navigationTitle("Le Mie Richieste")
        .toolbar {
            Button {
                // New request
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

#Preview("Admin Dashboard") {
    NavigationStack {
        AdminDashboardContentView()
    }
}

#Preview("User Dashboard") {
    NavigationStack {
        UserDashboardContentView()
    }
}
