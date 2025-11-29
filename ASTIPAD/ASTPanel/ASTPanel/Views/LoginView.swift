//
//  LoginView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

//
//  LoginView.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var users: [User] = []
    @State private var selectedUserId: UUID?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Sfondo bianco
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header con logo e titolo
                    VStack(spacing: 20) {
                        Spacer()
                        
                        // Logo
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.0, green: 0.47, blue: 1.0),
                                            Color(red: 0.0, green: 0.40, blue: 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Text("AST")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        // Titolo
                        Text("AST PANEL")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.47, blue: 1.0))
                        
                        Text("Gestione Aziendale")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height * 0.45)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color(red: 0.0, green: 0.47, blue: 1.0).opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Form di selezione utente
                    VStack(spacing: 24) {
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(Color(red: 0.0, green: 0.47, blue: 1.0))
                                
                                Text("Caricamento utenti...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(height: 200)
                        } else if users.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.orange)
                                
                                Text("Nessun utente trovato")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                
                                Button("Riprova") {
                                    Task {
                                        await loadUsers()
                                    }
                                }
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.0, green: 0.47, blue: 1.0))
                            }
                            .frame(height: 200)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Seleziona Utente")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.0, green: 0.47, blue: 1.0))
                                
                                // Lista utenti
                                VStack(spacing: 12) {
                                    ForEach(users) { user in
                                        Button {
                                            selectedUserId = user.id
                                        } label: {
                                            HStack {
                                                // Icona ruolo
                                                ZStack {
                                                    Circle()
                                                        .fill(user.isAdmin ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                                                        .frame(width: 40, height: 40)
                                                    
                                                    Text(user.isAdmin ? "👑" : "👤")
                                                        .font(.system(size: 20))
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(user.fullName)
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.black)
                                                    
                                                    Text(user.ruolo.capitalized)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                if selectedUserId == user.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Color(red: 0.0, green: 0.47, blue: 1.0))
                                                        .font(.system(size: 24))
                                                }
                                            }
                                            .padding()
                                            .background(
                                                selectedUserId == user.id ? 
                                                Color(red: 0.0, green: 0.47, blue: 1.0).opacity(0.1) : 
                                                Color.white
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        selectedUserId == user.id ? 
                                                        Color(red: 0.0, green: 0.47, blue: 1.0) : 
                                                        Color.gray.opacity(0.3),
                                                        lineWidth: selectedUserId == user.id ? 2 : 1
                                                    )
                                            )
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                                .frame(maxHeight: 300)
                            }
                            
                            // Pulsante Accedi
                            Button(action: handleLogin) {
                                HStack {
                                    Text("Accedi")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.0, green: 0.47, blue: 1.0),
                                            Color(red: 0.0, green: 0.40, blue: 0.85)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .disabled(selectedUserId == nil)
                            .opacity(selectedUserId == nil ? 0.6 : 1.0)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                    
                    Spacer()
                }
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            await loadUsers()
        }
        .alert("Errore", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Si è verificato un errore")
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            users = try await SupabaseService.shared.select(
                from: "users",
                orderBy: "nome"
            )
            print("✅ Caricati \(users.count) utenti")
        } catch {
            print("❌ Errore caricamento utenti: \(error)")
            errorMessage = "Impossibile caricare gli utenti"
            showError = true
        }
        
        isLoading = false
    }
    
    private func handleLogin() {
        guard let userId = selectedUserId,
              let user = users.first(where: { $0.id == userId }) else {
            return
        }
        
        print("🔐 Login utente: \(user.fullName)")
        
        // Simula login senza autenticazione (come la web app)
        authService.loginWithUser(user)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
