//
//  AuthService.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let authURL = Config.authURL
    private let anonKey = Config.supabaseAnonKey
    
    private init() {}
    
    // MARK: - Authentication
    func login(email: String, password: String) async throws {
        let loginData = ["email": email, "password": password]
        let url = URL(string: "\(authURL)/token?grant_type=password")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(loginData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.invalidCredentials
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        // Save token
        self.authToken = authResponse.accessToken
        UserDefaults.standard.set(authResponse.accessToken, forKey: "authToken")
        UserDefaults.standard.set(authResponse.refreshToken, forKey: "refreshToken")
        
        // Load user data
        try await loadCurrentUser(userId: authResponse.user.id)
        
        self.isAuthenticated = true
    }
    
    func logout() {
        self.isAuthenticated = false
        self.currentUser = nil
        self.authToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
    }
    
    func checkAuthStatus() {
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            self.authToken = token
            Task {
                do {
                    // Try to load user data
                    let users: [User] = try await SupabaseService.shared.select(
                        from: "users",
                        limit: 1
                    )
                    if let user = users.first {
                        self.currentUser = user
                        self.isAuthenticated = true
                    } else {
                        logout()
                    }
                } catch {
                    logout()
                }
            }
        }
    }
    
    func getAuthToken() async -> String? {
        return authToken
    }
    
    private func loadCurrentUser(userId: UUID) async throws {
        let users: [User] = try await SupabaseService.shared.request(
            endpoint: "users?id=eq.\(userId.uuidString)"
        )
        
        guard let user = users.first else {
            throw AuthError.userNotFound
        }
        
        self.currentUser = user
    }
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
    let user: AuthUser
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
    }
}

struct AuthUser: Codable {
    let id: UUID
    let email: String
}

// MARK: - Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case tokenExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email o password non validi"
        case .userNotFound:
            return "Utente non trovato"
        case .tokenExpired:
            return "Sessione scaduta. Effettua nuovamente il login"
        }
    }
}
