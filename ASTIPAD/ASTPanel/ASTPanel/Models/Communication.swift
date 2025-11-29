//
//  Communication.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct Communication: Codable, Identifiable, Hashable {
    let id: UUID
    let titolo: String
    let messaggio: String
    let mittente: UUID
    let tipo: CommunicationType
    let priorita: String
    let letta: Bool
    let eliminataDa: [UUID]?
    let archiviatiaDa: [UUID]?
    let destinatariSpecifici: [UUID]?
    let createdAt: Date
    
    // Relazione mittente (caricata quando necessario)
    var mittenteUser: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case titolo
        case messaggio
        case mittente
        case tipo
        case priorita
        case letta
        case eliminataDa = "eliminata_da"
        case archiviatiaDa = "archiviata_da"
        case destinatariSpecifici = "destinatari_specifici"
        case createdAt = "created_at"
        case mittenteUser
    }
    
    var isImportant: Bool {
        priorita == "alta"
    }
}

enum CommunicationType: String, Codable, CaseIterable {
    case generale = "generale"
    case avviso = "avviso"
    case urgente = "urgente"
    case manutenzione = "manutenzione"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .generale: return "envelope"
        case .avviso: return "exclamationmark.circle"
        case .urgente: return "bell"
        case .manutenzione: return "wrench"
        }
    }
}
