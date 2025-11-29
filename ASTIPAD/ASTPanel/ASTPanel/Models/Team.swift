//
//  Team.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct Team: Codable, Identifiable, Hashable {
    let id: UUID
    let nome: String
    let descrizione: String?
    let createdAt: Date
    let updatedAt: Date?
    
    // Membri del team (caricati quando necessario)
    var membri: [User]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nome
        case descrizione
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case membri
    }
}

struct TeamMember: Codable, Identifiable, Hashable {
    let id: UUID
    let teamId: UUID
    let userId: UUID
    let ruolo: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case ruolo
        case createdAt = "created_at"
    }
}
