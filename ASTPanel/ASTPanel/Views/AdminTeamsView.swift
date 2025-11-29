//
//  AdminTeamsView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

// MARK: - Admin Teams View
struct AdminTeamsView: View {
    @State private var teams: [Team] = []
    @State private var users: [User] = []
    @State private var isLoading = true
    @State private var showNewTeam = false
    @State private var selectedTeam: Team?
    @State private var showEditTeam = false
    @State private var showDeleteAlert = false
    @State private var teamToDelete: Team?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Caricamento squadre...")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(teams) { team in
                            TeamCard(team: team) {
                                selectedTeam = team
                                showEditTeam = true
                            } onDelete: {
                                teamToDelete = team
                                showDeleteAlert = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Gestione Squadre")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showNewTeam = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .fullScreenCover(isPresented: $showNewTeam) {
            NewTeamView(users: users, onSave: loadTeams)
        }
        .fullScreenCover(item: $selectedTeam) { team in
            EditTeamView(team: team, users: users, onSave: loadTeams)
        }
        .alert("Elimina Squadra", isPresented: $showDeleteAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Elimina", role: .destructive) {
                if let team = teamToDelete {
                    deleteTeam(team)
                }
            }
        } message: {
            Text("Sei sicuro di voler eliminare la squadra \(teamToDelete?.nome ?? "")?")
        }
        .onAppear {
            loadTeams()
            loadUsers()
        }
    }
    
    private func loadTeams() {
        Task {
            do {
                teams = try await SupabaseService.shared.fetch(from: "teams")
                isLoading = false
            } catch {
                print("❌ Error loading teams: \(error)")
                isLoading = false
            }
        }
    }
    
    private func loadUsers() {
        Task {
            do {
                users = try await SupabaseService.shared.fetch(from: "users")
            } catch {
                print("❌ Error loading users: \(error)")
            }
        }
    }
    
    private func deleteTeam(_ team: Team) {
        Task {
            do {
                try await SupabaseService.shared.delete(from: "teams", id: team.id)
                loadTeams()
            } catch {
                print("❌ Error deleting team: \(error)")
            }
        }
    }
}

// MARK: - Team Card
struct TeamCard: View {
    let team: Team
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.nome)
                        .font(.headline)
                    if let descrizione = team.descrizione {
                        Text(descrizione)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Modifica", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Elimina", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let membri = team.membri, !membri.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Membri (\(membri.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(membri) { member in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.purple.opacity(0.3))
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Text(member.initials)
                                                .font(.caption2)
                                                .foregroundColor(.purple)
                                        )
                                    Text(member.fullName)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - New Team View
struct NewTeamView: View {
    @Environment(\.dismiss) var dismiss
    let users: [User]
    let onSave: () -> Void
    
    @State private var nome = ""
    @State private var descrizione = ""
    @State private var selectedUserIds: Set<UUID> = []
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Squadra") {
                    TextField("Nome Squadra *", text: $nome)
                    TextField("Descrizione", text: $descrizione, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Membri") {
                    ForEach(users) { user in
                        HStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Text(user.initials)
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(user.fullName)
                                    .font(.subheadline)
                                Text(user.ruolo.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedUserIds.contains(user.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedUserIds.contains(user.id) {
                                selectedUserIds.remove(user.id)
                            } else {
                                selectedUserIds.insert(user.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuova Squadra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        saveTeam()
                    }
                    .disabled(nome.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveTeam() {
        isSaving = true
        Task {
            do {
                let newTeam: [String: Any] = [
                    "nome": nome,
                    "descrizione": descrizione.isEmpty ? nil : descrizione
                ]
                
                try await SupabaseService.shared.insert(into: "teams", data: newTeam)
                
                onSave()
                dismiss()
            } catch {
                print("❌ Error saving team: \(error)")
                isSaving = false
            }
        }
    }
}

// MARK: - Edit Team View
struct EditTeamView: View {
    @Environment(\.dismiss) var dismiss
    let team: Team
    let users: [User]
    let onSave: () -> Void
    
    @State private var nome = ""
    @State private var descrizione = ""
    @State private var selectedUserIds: Set<UUID> = []
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informazioni Squadra") {
                    TextField("Nome Squadra *", text: $nome)
                    TextField("Descrizione", text: $descrizione, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Membri") {
                    ForEach(users) { user in
                        HStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Text(user.initials)
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(user.fullName)
                                    .font(.subheadline)
                                Text(user.ruolo.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedUserIds.contains(user.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedUserIds.contains(user.id) {
                                selectedUserIds.remove(user.id)
                            } else {
                                selectedUserIds.insert(user.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Modifica Squadra")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        updateTeam()
                    }
                    .disabled(nome.isEmpty || isSaving)
                }
            }
            .onAppear {
                nome = team.nome
                descrizione = team.descrizione ?? ""
                if let membri = team.membri {
                    selectedUserIds = Set(membri.map { $0.id })
                }
            }
        }
    }
    
    private func updateTeam() {
        isSaving = true
        Task {
            do {
                let updatedData: [String: Any] = [
                    "nome": nome,
                    "descrizione": descrizione.isEmpty ? nil : descrizione
                ]
                
                try await SupabaseService.shared.update(table: "teams", id: team.id.uuidString, data: updatedData)
                
                onSave()
                dismiss()
            } catch {
                print("❌ Error updating team: \(error)")
                isSaving = false
            }
        }
    }
}
