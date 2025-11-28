//
//  Component.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

struct Component: Codable, Identifiable, Hashable {
    let id: UUID
    let nome: String
    let descrizione: String?
    let unitaMisura: String
    let quantitaDisponibile: Double
    let categoria: String
    let scortaMinima: Double
    let prezzoUnitario: Double?
    let codice: String?
    let note: String?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case nome
        case descrizione
        case unitaMisura = "unita_misura"
        case quantitaDisponibile = "quantita_disponibile"
        case categoria
        case scortaMinima = "scorta_minima"
        case prezzoUnitario = "prezzo_unitario"
        case codice
        case note
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isBelowMinimum: Bool {
        quantitaDisponibile < scortaMinima
    }
    
    var stockStatus: StockStatus {
        if quantitaDisponibile == 0 {
            return .outOfStock
        } else if isBelowMinimum {
            return .lowStock
        } else {
            return .inStock
        }
    }
    
    enum StockStatus {
        case inStock
        case lowStock
        case outOfStock
        
        var color: String {
            switch self {
            case .inStock: return "green"
            case .lowStock: return "orange"
            case .outOfStock: return "red"
            }
        }
        
        var displayName: String {
            switch self {
            case .inStock: return "Disponibile"
            case .lowStock: return "Scorta Bassa"
            case .outOfStock: return "Esaurito"
            }
        }
    }
}

struct TaskComponent: Codable, Identifiable, Hashable {
    let id: UUID
    let taskId: UUID
    let componentId: UUID
    let quantita: Double
    let note: String?
    
    // Relazione component (caricata quando necessario)
    var component: Component?
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case componentId = "component_id"
        case quantita
        case note
        case component
    }
}
