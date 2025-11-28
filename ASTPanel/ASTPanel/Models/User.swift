//
//  User.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct User: Codable, Identifiable, Hashable {
    let id: UUID
    let email: String
    let nome: String
    let cognome: String
    let ruolo: String // admin, dipendente, tecnico
    let stato: String // attivo, inattivo, sospeso
    let telefono: String?
    let fotoProfilo: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case nome
        case cognome
        case ruolo
        case stato
        case telefono
        case fotoProfilo = "foto_profilo"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var fullName: String {
        "\(nome) \(cognome)"
    }
    
    var initials: String {
        let first = nome.first.map(String.init) ?? ""
        let last = cognome.first.map(String.init) ?? ""
        return "\(first)\(last)".uppercased()
    }
    
    var isAdmin: Bool {
        ruolo == "admin"
    }
    
    var isActive: Bool {
        stato == "attivo"
    }
}
