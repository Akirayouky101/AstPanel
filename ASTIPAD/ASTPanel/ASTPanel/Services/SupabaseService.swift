//
//  SupabaseService.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

class SupabaseService {
    static let shared = SupabaseService()
    
    private let session: URLSession
    private let baseURL: String
    private let anonKey: String
    
    private init() {
        self.baseURL = Config.restURL
        self.anonKey = Config.supabaseAnonKey
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Generic Request
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(string: "\(baseURL)/\(endpoint)")
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            print("❌ URL non valido: \(baseURL)/\(endpoint)")
            throw SupabaseError.invalidURL
        }
        
        print("🌐 Request: \(method.rawValue) \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if available
        if let token = await AuthService.shared.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Token aggiunto")
        } else {
            print("🔓 Nessun token, uso anon key")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Risposta non HTTP")
                throw SupabaseError.invalidResponse
            }
            
            print("📥 Status code: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response: \(responseString.prefix(200))")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Errore HTTP \(httpResponse.statusCode)")
                throw SupabaseError.httpError(statusCode: httpResponse.statusCode, data: data)
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatters: [Any] = [
                    ISO8601DateFormatter(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        return formatter
                    }()
                ]
                
                for formatter in formatters {
                    if let formatter = formatter as? ISO8601DateFormatter,
                       let date = formatter.date(from: dateString) {
                        return date
                    } else if let formatter = formatter as? DateFormatter,
                              let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            print("❌ Errore decodifica: \(error)")
            throw error
        } catch {
            print("❌ Errore generico: \(error)")
            throw error
        }
    }
    
    // MARK: - Query Builder
    func select<T: Decodable>(
        from table: String,
        columns: String = "*",
        filter: String? = nil,
        orderBy: String? = nil,
        limit: Int? = nil
    ) async throws -> [T] {
        var endpoint = table
        var queryParts: [String] = []
        
        // Columns selection
        queryParts.append("select=\(columns)")
        
        // Filter
        if let filter = filter {
            queryParts.append(filter)
        }
        
        // Order by
        if let orderBy = orderBy {
            queryParts.append("order=\(orderBy).asc")
        }
        
        // Limit
        if let limit = limit {
            queryParts.append("limit=\(limit)")
        }
        
        if !queryParts.isEmpty {
            endpoint += "?" + queryParts.joined(separator: "&")
        }
        
        print("📋 Query endpoint: \(endpoint)")
        
        return try await request(endpoint: endpoint)
    }
    
    func insert<T: Encodable & Decodable>(
        into table: String,
        values: T
    ) async throws -> T {
        return try await request(
            endpoint: table,
            method: .post,
            body: values
        )
    }
    
    func update<T: Encodable & Decodable>(
        table: String,
        id: UUID,
        values: T
    ) async throws -> T {
        return try await request(
            endpoint: "\(table)?id=eq.\(id.uuidString)",
            method: .patch,
            body: values
        )
    }
    
    func delete(from table: String, id: UUID) async throws {
        let _: [String: String] = try await request(
            endpoint: "\(table)?id=eq.\(id.uuidString)",
            method: .delete
        )
    }
    
    // MARK: - Convenience Methods
    func fetch<T: Decodable>(from table: String, filters: [(String, String)] = []) async throws -> [T] {
        var endpoint = table
        
        if !filters.isEmpty {
            let filterString = filters.map { "\($0.0)=\($0.1)" }.joined(separator: "&")
            endpoint += "?\(filterString)"
        }
        
        return try await request(endpoint: endpoint)
    }
    
    func insert(into table: String, data: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/\(table)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }
    }
    
    func update(table: String, id: String, data: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/\(table)?id=eq.\(id)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.invalidResponse
        }
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

// MARK: - Errors
enum SupabaseError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case encodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL non valido"
        case .invalidResponse:
            return "Risposta del server non valida"
        case .httpError(let statusCode, let data):
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            return "Errore HTTP \(statusCode): \(message)"
        case .decodingError(let error):
            return "Errore decodifica: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Errore codifica: \(error.localizedDescription)"
        }
    }
}
