//
//  UserDashboardComponents.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

// MARK: - Dashboard Content
struct UserDashboardContent: View {
    @EnvironmentObject var authService: AuthService
    @Binding var tasks: [WorkTask]
    @Binding var selectedSection: String?
    @State private var showNewRequestSheet = false
    
    private var activeTasks: Int {
        tasks.filter { $0.stato.rawValue == "in_corso" }.count
    }
    
    private var completedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            task.stato.rawValue == "completato" &&
            Calendar.current.isDate(task.updatedAt ?? Date(), inSameDayAs: today)
        }.count
    }
    
    private var overdueTasks: Int {
        tasks.filter { task in
            task.stato.rawValue != "completato" &&
            task.scadenza ?? Date() < Date()
        }.count
    }
    
    private var productivity: Int {
        guard !tasks.isEmpty else { return 0 }
        let completed = tasks.filter { $0.stato.rawValue == "completato" }.count
        return Int((Double(completed) / Double(tasks.count)) * 100)
    }
    
    private var todayTasks: [WorkTask] {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            task.stato.rawValue == "in_corso" ||
            Calendar.current.isDate(task.scadenza ?? Date(), inSameDayAs: today) ||
            (task.scadenza ?? Date() < Date() && task.stato.rawValue != "completato")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // User Header
                UserHeaderView()
                    .padding(.horizontal)
                
                // Quick Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Lavorazioni Attive", value: "\(activeTasks)", icon: "list.clipboard.fill", color: .blue)
                    StatCard(title: "Completate Oggi", value: "\(completedToday)", icon: "checkmark.circle.fill", color: .green)
                    StatCard(title: "In Scadenza", value: "\(overdueTasks)", icon: "clock.fill", color: .orange)
                    StatCard(title: "Produttività", value: "\(productivity)%", icon: "chart.line.uptrend.xyaxis", color: .purple)
                }
                .padding(.horizontal)
                
                // Quick Actions
                VStack(spacing: 12) {
                    Button(action: {
                        selectedSection = "my-tasks"
                    }) {
                        QuickActionCard(title: "Le Mie Lavorazioni", subtitle: "Visualizza e aggiorna i tuoi task", icon: "list.clipboard.fill", gradient: [.blue, .blue.opacity(0.8)])
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showNewRequestSheet = true
                    }) {
                        QuickActionCard(title: "Nuova Richiesta", subtitle: "Ferie, permessi, materiali", icon: "plus.circle.fill", gradient: [.green, .green.opacity(0.8)])
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        selectedSection = "communications"
                    }) {
                        QuickActionCard(title: "Comunicazioni", subtitle: "Leggi gli ultimi annunci", icon: "bell.fill", gradient: [.purple, .purple.opacity(0.8)])
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .sheet(isPresented: $showNewRequestSheet) {
                    NewRequestView(onRequestCreated: {
                        // Ricarica dashboard dopo creazione richiesta
                    })
                    .environmentObject(authService)
                }
                
                // Today's Tasks
                VStack(alignment: .leading, spacing: 16) {
                    Text("Lavorazioni di Oggi")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    if todayTasks.isEmpty {
                        Text("Nessuna lavorazione per oggi")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(todayTasks) { task in
                            TodayTaskCard(task: task)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.top)
        }
        .navigationTitle("Dashboard")
    }
}

// MARK: - User Header
struct UserHeaderView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Photo
            if let photoURL = authService.currentUser?.fotoProfilo, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 64, height: 64)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .font(.title)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ciao, \(authService.currentUser?.nome ?? "") \(authService.currentUser?.cognome ?? "")!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text(authService.currentUser?.ruolo.capitalized ?? "Dipendente")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .padding(12)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
        }
        .padding()
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(12)
    }
}

// MARK: - Today Task Card
// MARK: - Today Task Card
struct TodayTaskCard: View {
    let task: WorkTask
    @State private var showTaskDetail = false
    
    private var isOverdue: Bool {
        task.stato.rawValue != "completato" && task.scadenza ?? Date() < Date()
    }
    
    var body: some View {
        Button(action: {
            showTaskDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(task.titolo)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Text(task.descrizione ?? "Nessuna descrizione")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    StatusBadge(status: task.stato.rawValue)
                    PriorityBadge(priority: task.priorita.rawValue)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(formatDate(task.scadenza))
                            .font(.caption)
                    }
                    .foregroundColor(isOverdue ? .red : .gray)
                }
                
                if task.progresso > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progresso")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(task.progresso)%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        ProgressView(value: Double(task.progresso), total: 100)
                            .tint(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                Rectangle()
                    .fill(priorityColor(task.priorita.rawValue))
                    .frame(width: 4)
                    .cornerRadius(2),
                alignment: .leading
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showTaskDetail) {
            TaskDetailView(task: task)
        }
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "alta", "high": return .red
        case "media", "medium": return .orange
        case "bassa", "low": return .green
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Helper Views
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(statusText)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusText: String {
        switch status {
        case "da_fare": return "Da Fare"
        case "in_corso": return "In Corso"
        case "revisione": return "Revisione"
        case "completato": return "Completato"
        default: return status
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "da_fare": return .gray
        case "in_corso": return .blue
        case "revisione": return .orange
        case "completato": return .green
        default: return .gray
        }
    }
}

struct PriorityBadge: View {
    let priority: String
    
    var body: some View {
        Text(priority.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority.lowercased() {
        case "alta", "high": return .red
        case "media", "medium": return .orange
        case "bassa", "low": return .green
        default: return .gray
        }
    }
}

// MARK: - User Tasks View
struct UserTasksView: View {
    @Binding var tasks: [WorkTask]
    @State private var filterStatus: String = ""
    
    private var filteredTasks: [WorkTask] {
        if filterStatus.isEmpty {
            return tasks
        }
        return tasks.filter { $0.stato.rawValue == filterStatus }
    }
    
    var body: some View {
        VStack {
            // Filter
            Picker("Stato", selection: $filterStatus) {
                Text("Tutti").tag("")
                Text("Da Fare").tag("da_fare")
                Text("In Corso").tag("in_corso")
                Text("Revisione").tag("revisione")
                Text("Completato").tag("completato")
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tasks Grid
            if filteredTasks.isEmpty {
                Text("Nessuna lavorazione trovata")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TodayTaskCard(task: task)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Le Mie Lavorazioni")
    }
}

// MARK: - User Requests View
struct UserRequestsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var requests: [Request] = []
    @State private var isLoading = false
    @State private var showNewRequestSheet = false
    @State private var filterStatus: String = ""
    
    private var filteredRequests: [Request] {
        if filterStatus.isEmpty {
            return requests
        }
        return requests.filter { $0.stato.rawValue == filterStatus }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    showNewRequestSheet = true
                }) {
                    Label("Nuova Richiesta", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
            
            // Filter
            Picker("Stato", selection: $filterStatus) {
                Text("Tutte").tag("")
                Text("In Attesa").tag("in_attesa")
                Text("Approvate").tag("approvata")
                Text("Rifiutate").tag("rifiutata")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Requests List
            if isLoading {
                ProgressView()
                    .padding()
            } else if filteredRequests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Nessuna richiesta trovata")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRequests) { request in
                            RequestCard(request: request)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Le Mie Richieste")
        .sheet(isPresented: $showNewRequestSheet) {
            NewRequestView(onRequestCreated: loadRequests)
                .environmentObject(authService)
        }
        .onAppear {
            loadRequests()
        }
    }
    
    private func loadRequests() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        Task {
            do {
                let fetchedRequests: [Request] = try await SupabaseService.shared.fetch(
                    from: "richieste",
                    filters: [("user_id", "eq.\(userId)")]
                )
                await MainActor.run {
                    self.requests = fetchedRequests.sorted { $0.createdAt > $1.createdAt }
                    self.isLoading = false
                }
            } catch {
                print("❌ Errore caricamento richieste: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - User Communications View
struct UserCommunicationsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var communications: [Communication] = []
    @State private var isLoading = false
    @State private var filterType: String = ""
    
    private var filteredCommunications: [Communication] {
        if filterType.isEmpty {
            return communications
        }
        return communications.filter { $0.tipo.rawValue == filterType }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter
            Picker("Tipo", selection: $filterType) {
                Text("Tutte").tag("")
                Text("Generale").tag("generale")
                Text("Avviso").tag("avviso")
                Text("Urgente").tag("urgente")
                Text("Manutenzione").tag("manutenzione")
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Communications List
            if isLoading {
                ProgressView()
                    .padding()
            } else if filteredCommunications.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Nessuna comunicazione")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCommunications) { communication in
                            CommunicationCard(communication: communication)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Comunicazioni")
        .onAppear {
            loadCommunications()
        }
    }
    
    private func loadCommunications() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        Task {
            do {
                // Carica comunicazioni generali o indirizzate all'utente
                let allCommunications: [Communication] = try await SupabaseService.shared.fetch(
                    from: "comunicazioni",
                    filters: []
                )
                
                await MainActor.run {
                    // Filtra comunicazioni rilevanti per l'utente
                    self.communications = allCommunications.filter { comm in
                        // Mostra se non ha destinatari specifici o se l'utente è tra i destinatari
                        comm.destinatariSpecifici == nil || 
                        comm.destinatariSpecifici?.contains(userId) == true
                    }
                    .filter { comm in
                        // Nascondi se eliminata dall'utente
                        comm.eliminataDa?.contains(userId) != true
                    }
                    .sorted { $0.createdAt > $1.createdAt }
                    
                    self.isLoading = false
                }
            } catch {
                print("❌ Errore caricamento comunicazioni: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - User Profile View
struct UserProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showEditSheet = false
    @State private var tasks: [WorkTask] = []
    @State private var isLoadingStats = false
    
    private var totalTasks: Int {
        tasks.count
    }
    
    private var completedTasks: Int {
        tasks.filter { $0.stato.rawValue == "completata" }.count
    }
    
    private var averageDaily: String {
        guard !tasks.isEmpty else { return "0.0" }
        let days = max(Calendar.current.dateComponents([.day], from: tasks.first?.createdAt ?? Date(), to: Date()).day ?? 1, 1)
        let avg = Double(completedTasks) / Double(days)
        return String(format: "%.1f", avg)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Photo
                if let photoURL = authService.currentUser?.fotoProfilo, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .font(.largeTitle)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .font(.largeTitle)
                        )
                }
                
                VStack(spacing: 8) {
                    Text("\(authService.currentUser?.nome ?? "") \(authService.currentUser?.cognome ?? "")")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(authService.currentUser?.ruolo.capitalized ?? "")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    showEditSheet = true
                }) {
                    Text("Modifica Profilo")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Stats
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistiche")
                        .font(.headline)
                    
                    if isLoadingStats {
                        ProgressView()
                    } else {
                        HStack {
                            Text("Lavorazioni Totali")
                            Spacer()
                            Text("\(totalTasks)")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Completate")
                            Spacer()
                            Text("\(completedTasks)")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Media Giornaliera")
                            Spacer()
                            Text(averageDaily)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
            }
            .padding()
        }
        .navigationTitle("Il Mio Profilo")
        .sheet(isPresented: $showEditSheet) {
            EditProfileView()
                .environmentObject(authService)
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoadingStats = true
        Task {
            do {
                let allTasks: [WorkTask] = try await SupabaseService.shared.fetch(
                    from: "lavorazioni",
                    filters: [("assigned_user_id", "eq.\(userId)")]
                )
                
                await MainActor.run {
                    self.tasks = allTasks
                    self.isLoadingStats = false
                }
            } catch {
                print("❌ Errore caricamento statistiche: \(error)")
                await MainActor.run {
                    self.isLoadingStats = false
                }
            }
        }
    }
}

// MARK: - Request Card
struct RequestCard: View {
    let request: Request
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: request.tipo.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.tipo.displayName)
                        .font(.headline)
                    
                    Text(dateFormatter.string(from: request.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                StatusBadgeRequest(status: request.stato)
            }
            
            Text(request.descrizione)
                .font(.body)
                .foregroundColor(.primary)
            
            if let risposta = request.risposta {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Risposta:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(risposta)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct StatusBadgeRequest: View {
    let status: RequestStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .inAttesa: return .orange
        case .approvata: return .green
        case .rifiutata: return .red
        }
    }
}

// MARK: - Communication Card
struct CommunicationCard: View {
    let communication: Communication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: communication.tipo.icon)
                    .foregroundColor(typeColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(communication.titolo)
                        .font(.headline)
                    
                    Text(dateFormatter.string(from: communication.createdAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if communication.isImportant {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
                
                if !communication.letta {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
            
            Text(communication.messaggio)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(communication.letta ? Color(.systemBackground) : Color.blue.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var typeColor: Color {
        switch communication.tipo {
        case .generale: return .blue
        case .avviso: return .orange
        case .urgente: return .red
        case .manutenzione: return .purple
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - New Request View
struct NewRequestView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    let onRequestCreated: () -> Void
    
    @State private var selectedType: RequestType = .ferie
    @State private var descrizione: String = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tipo Richiesta")) {
                    Picker("Tipo", selection: $selectedType) {
                        ForEach(RequestType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Descrizione")) {
                    TextEditor(text: $descrizione)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: submitRequest) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Invia Richiesta")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(descrizione.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Nuova Richiesta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
            .alert("Errore", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitRequest() {
        guard let userId = authService.currentUser?.id else { return }
        guard !descrizione.isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let newRequest: [String: Any] = [
                    "user_id": userId.uuidString,
                    "tipo": selectedType.rawValue,
                    "descrizione": descrizione,
                    "stato": "in_attesa",
                    "created_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                try await SupabaseService.shared.insert(into: "richieste", data: newRequest)
                
                await MainActor.run {
                    onRequestCreated()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossibile creare la richiesta: \(error.localizedDescription)"
                    showError = true
                    isSubmitting = false
                }
            }
        }
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    let task: WorkTask
    @Environment(\.dismiss) var dismiss
    @State private var progresso: Double
    @State private var selectedStatus: TaskStatus
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(task: WorkTask) {
        self.task = task
        _progresso = State(initialValue: Double(task.progresso))
        _selectedStatus = State(initialValue: task.stato)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.titolo)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        HStack {
                            PriorityBadge(priority: task.priorita.rawValue)
                            
                            if let scadenza = task.scadenza {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text("Scadenza: \(formatDate(scadenza))")
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descrizione")
                            .font(.headline)
                        Text(task.descrizione ?? "Nessuna descrizione disponibile")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Status Update
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aggiorna Stato")
                            .font(.headline)
                        
                        Picker("Stato", selection: $selectedStatus) {
                            ForEach([TaskStatus.daFare, TaskStatus.inCorso, TaskStatus.inPausa, TaskStatus.completata], id: \.self) { status in
                                Text(statusDisplayName(status)).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Progress Update
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Progresso")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(progresso))%")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $progresso, in: 0...100, step: 5)
                            .tint(.blue)
                        
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("100%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Update Button
                    Button(action: updateTask) {
                        if isUpdating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Salva Modifiche")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isUpdating || (selectedStatus == task.stato && Int(progresso) == task.progresso))
                }
                .padding()
            }
            .navigationTitle("Dettaglio Lavorazione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
            .alert("Errore", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateTask() {
        isUpdating = true
        
        Task {
            do {
                let updates: [String: Any] = [
                    "stato": selectedStatus.rawValue,
                    "progresso": Int(progresso),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                try await SupabaseService.shared.update(
                    table: "lavorazioni",
                    id: task.id.uuidString,
                    data: updates
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossibile aggiornare la lavorazione: \(error.localizedDescription)"
                    showError = true
                    isUpdating = false
                }
            }
        }
    }
    
    private func statusDisplayName(_ status: TaskStatus) -> String {
        switch status {
        case .daFare: return "Da Fare"
        case .inCorso: return "In Corso"
        case .inPausa: return "In Pausa"
        case .completata: return "Completata"
        case .annullata: return "Annullata"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var nome: String
    @State private var cognome: String
    @State private var email: String
    @State private var fotoProfilo: String
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    init() {
        // Initialize from current user - using _state to set initial values
        _nome = State(initialValue: "")
        _cognome = State(initialValue: "")
        _email = State(initialValue: "")
        _fotoProfilo = State(initialValue: "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informazioni Personali")) {
                    HStack {
                        Text("Nome")
                            .frame(width: 100, alignment: .leading)
                        TextField("Nome", text: $nome)
                    }
                    
                    HStack {
                        Text("Cognome")
                            .frame(width: 100, alignment: .leading)
                        TextField("Cognome", text: $cognome)
                    }
                    
                    HStack {
                        Text("Email")
                            .frame(width: 100, alignment: .leading)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                Section(header: Text("Foto Profilo")) {
                    HStack {
                        Text("URL Foto")
                            .frame(width: 100, alignment: .leading)
                        TextField("https://...", text: $fotoProfilo)
                            .autocapitalization(.none)
                    }
                    
                    if !fotoProfilo.isEmpty, let url = URL(string: fotoProfilo) {
                        HStack {
                            Spacer()
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("Ruolo")) {
                    HStack {
                        Text("Ruolo")
                            .frame(width: 100, alignment: .leading)
                        Text(authService.currentUser?.ruolo.capitalized ?? "")
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.1))
                
                Section {
                    Button(action: saveProfile) {
                        if isUpdating {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Salva Modifiche")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isUpdating || nome.isEmpty || cognome.isEmpty || email.isEmpty)
                }
            }
            .navigationTitle("Modifica Profilo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
            .alert("Errore", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Successo", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Profilo aggiornato con successo!")
            }
            .onAppear {
                loadCurrentUser()
            }
        }
    }
    
    private func loadCurrentUser() {
        if let user = authService.currentUser {
            nome = user.nome
            cognome = user.cognome
            email = user.email
            fotoProfilo = user.fotoProfilo ?? ""
        }
    }
    
    private func saveProfile() {
        guard let userId = authService.currentUser?.id else { return }
        
        isUpdating = true
        
        Task {
            do {
                let updates: [String: Any] = [
                    "nome": nome,
                    "cognome": cognome,
                    "email": email,
                    "foto_profilo": fotoProfilo.isEmpty ? NSNull() : fotoProfilo,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ]
                
                try await SupabaseService.shared.update(
                    table: "utenti",
                    id: userId.uuidString,
                    data: updates
                )
                
                // Aggiorna l'utente locale - ricarica da server
                await MainActor.run {
                    if let currentUser = authService.currentUser {
                        // Crea nuovo utente con dati aggiornati
                        let updatedUser = User(
                            id: currentUser.id,
                            email: email,
                            nome: nome,
                            cognome: cognome,
                            ruolo: currentUser.ruolo,
                            stato: currentUser.stato,
                            telefono: currentUser.telefono,
                            fotoProfilo: fotoProfilo.isEmpty ? nil : fotoProfilo,
                            reparto: currentUser.reparto,
                            dataAssunzione: currentUser.dataAssunzione,
                            createdAt: currentUser.createdAt,
                            updatedAt: currentUser.updatedAt
                        )
                        authService.currentUser = updatedUser
                        
                        // Salva in UserDefaults
                        if let encoded = try? JSONEncoder().encode(updatedUser) {
                            UserDefaults.standard.set(encoded, forKey: "currentUser")
                        }
                    }
                    
                    showSuccess = true
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Impossibile aggiornare il profilo: \(error.localizedDescription)"
                    showError = true
                    isUpdating = false
                }
            }
        }
    }
}


// MARK: - User Calendar View
struct UserCalendarView: View {
    @Binding var tasks: [WorkTask]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private var tasksForSelectedDate: [WorkTask] {
        tasks.filter { task in
            guard let scadenza = task.scadenza else { return false }
            return Calendar.current.isDate(scadenza, inSameDayAs: selectedDate)
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: currentMonth)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .padding()
                }
                Spacer()
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 0) {
                ForEach(["L", "M", "M", "G", "V", "S", "D"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            taskCount: tasksCount(for: date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.frame(height: 50)
                    }
                }
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Lavorazioni del \(formatSelectedDate())")
                    .font(.headline)
                    .padding(.horizontal)
                
                if tasksForSelectedDate.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Nessuna lavorazione per questa data")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tasksForSelectedDate) { task in
                                TodayTaskCard(task: task)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Il Mio Calendario")
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let adjustedFirstWeekday = (firstWeekday + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: adjustedFirstWeekday)
        var date = interval.start
        while date < interval.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return days
    }
    
    private func tasksCount(for date: Date) -> Int {
        tasks.filter { task in
            guard let scadenza = task.scadenza else { return false }
            return Calendar.current.isDate(scadenza, inSameDayAs: date)
        }.count
    }
    
    private func previousMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: selectedDate)
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let taskCount: Int
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
            
            if taskCount > 0 {
                Circle()
                    .fill(isSelected ? Color.white : Color.blue)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

