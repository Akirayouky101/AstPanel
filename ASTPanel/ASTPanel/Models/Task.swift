//
//  Task.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct Task: Codable, Identifiable, Hashable {
    let id: UUID
    let titolo: String
    let descrizione: String?
    let clientId: UUID?
    let stato: TaskStatus
    let priorita: TaskPriority
    let scadenza: Date?
    let dataInizio: Date?
    let dataCompletamento: Date?
    let progresso: Int
    let assignedUserId: UUID?
    let assignedTeamId: UUID?
    let createdBy: UUID?
    let createdAt: Date
    let updatedAt: Date?
    
    // Relazioni (opzionali, caricate quando necessario)
    var client: Client?
    var assignedUser: User?
    var assignedTeam: Team?
    var componenti: [TaskComponent]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case titolo
        case descrizione
        case clientId = "client_id"
        case stato
        case priorita
        case scadenza
        case dataInizio = "data_inizio"
        case dataCompletamento = "data_completamento"
        case progresso
        case assignedUserId = "assigned_user_id"
        case assignedTeamId = "assigned_team_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case client
        case assignedUser = "assigned_user"
        case assignedTeam = "assigned_team"
        case componenti
    }
    
    var isOverdue: Bool {
        guard let scadenza = scadenza else { return false }
        return scadenza < Date() && stato != .completata
    }
    
    var statusColor: String {
        switch stato {
        case .daFare: return "gray"
        case .inCorso: return "blue"
        case .inPausa: return "orange"
        case .completata: return "green"
        case .annullata: return "red"
        }
    }
    
    var priorityColor: String {
        switch priorita {
        case .bassa: return "green"
        case .media: return "orange"
        case .alta: return "red"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case daFare = "da_fare"
    case inCorso = "in_corso"
    case inPausa = "in_pausa"
    case completata = "completata"
    case annullata = "annullata"
    
    var displayName: String {
        switch self {
        case .daFare: return "Da Fare"
        case .inCorso: return "In Corso"
        case .inPausa: return "In Pausa"
        case .completata: return "Completata"
        case .annullata: return "Annullata"
        }
    }
}

enum TaskPriority: String, Codable, CaseIterable {
    case bassa = "bassa"
    case media = "media"
    case alta = "alta"
    
    var displayName: String {
        rawValue.capitalized
    }
}
