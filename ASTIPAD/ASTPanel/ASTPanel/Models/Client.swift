//
//  Client.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct Client: Codable, Identifiable, Hashable {
    let id: UUID
    let ragioneSociale: String
    let partitaIva: String?
    let codiceFiscale: String?
    let email: String?
    let telefono: String?
    let indirizzo: String?
    let citta: String?
    let cap: String?
    let provincia: String?
    let note: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ragioneSociale = "ragione_sociale"
        case partitaIva = "partita_iva"
        case codiceFiscale = "codice_fiscale"
        case email
        case telefono
        case indirizzo
        case citta
        case cap
        case provincia
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var fullAddress: String? {
        let components = [indirizzo, cap, citta, provincia].compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
