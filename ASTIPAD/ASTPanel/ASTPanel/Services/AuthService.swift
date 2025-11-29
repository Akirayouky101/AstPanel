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
    
    // Login semplificato - seleziona utente (come web app)
    func loginWithUser(_ user: User) {
        print("✅ Login utente: \(user.fullName) (\(user.ruolo))")
        self.currentUser = user
        self.isAuthenticated = true
        
        // Salva in UserDefaults per persistenza
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    // Login con autenticazione Supabase (per future versioni)
    func login(email: String, password: String) async throws {
        print("🔐 Tentativo di login per: \(email)")
        
        let loginData = ["email": email, "password": password]
        let url = URL(string: "\(authURL)/token?grant_type=password")!
        
        print("📍 URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(loginData)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📥 Response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response body: \(responseString)")
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ Status code non valido")
                throw AuthError.invalidCredentials
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            print("✅ Token ricevuto")
            
            // Save token
            self.authToken = authResponse.accessToken
            UserDefaults.standard.set(authResponse.accessToken, forKey: "authToken")
            UserDefaults.standard.set(authResponse.refreshToken, forKey: "refreshToken")
            
            // Load user data
            try await loadCurrentUser(userId: authResponse.user.id)
            
            self.isAuthenticated = true
            
            print("✅ Login completato")
        } catch let error as DecodingError {
            print("❌ Errore decodifica: \(error)")
            throw error
        } catch {
            print("❌ Errore generico: \(error)")
            throw error
        }
    }
    
    func logout() {
        print("🚪 Logout")
        self.isAuthenticated = false
        self.currentUser = nil
        self.authToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    func checkAuthStatus() {
        // Controlla se c'è un utente salvato
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
            print("✅ Utente caricato da storage: \(user.fullName)")
            return
        }
        
        // Fallback: prova con token (per compatibilità futura)
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
