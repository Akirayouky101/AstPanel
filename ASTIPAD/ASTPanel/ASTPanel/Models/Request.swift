//
//  Request.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct Request: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let tipo: RequestType
    let descrizione: String
    let stato: RequestStatus
    let rispostoDa: UUID?
    let risposta: String?
    let createdAt: Date
    let updatedAt: Date?
    
    // Relazioni (caricate quando necessario)
    var user: User?
    var responder: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case tipo
        case descrizione
        case stato
        case rispostoDa = "risposto_da"
        case risposta
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case responder
    }
}

enum RequestType: String, Codable, CaseIterable {
    case ferie = "ferie"
    case permesso = "permesso"
    case malattia = "malattia"
    case materiale = "materiale"
    case supporto = "supporto"
    case altro = "altro"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .ferie: return "calendar"
        case .permesso: return "clock"
        case .malattia: return "cross.case"
        case .materiale: return "shippingbox"
        case .supporto: return "questionmark.circle"
        case .altro: return "ellipsis.circle"
        }
    }
}

enum RequestStatus: String, Codable, CaseIterable {
    case inAttesa = "in_attesa"
    case approvata = "approvata"
    case rifiutata = "rifiutata"
    
    var displayName: String {
        switch self {
        case .inAttesa: return "In Attesa"
        case .approvata: return "Approvata"
        case .rifiutata: return "Rifiutata"
        }
    }
    
    var color: String {
        switch self {
        case .inAttesa: return "orange"
        case .approvata: return "green"
        case .rifiutata: return "red"
        }
    }
}
