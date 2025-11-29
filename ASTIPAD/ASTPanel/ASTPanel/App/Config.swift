//
//  Config.swift
//  ASTPanel
//
//  Created on 27/11/2025.
//

import Foundation

enum Config {
    // MARK: - Supabase Configuration
    static let supabaseURL = "https://hrqhckksrunniqnzqogk.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhycWhja2tzcnVubmlxbnpxb2drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyODczNjUsImV4cCI6MjA3Njg2MzM2NX0.EyJc6p88SDxDt07g4sytrrqqnoA6EOvpKmoZFNCaqvA"
    
    // MARK: - API Endpoints
    static let restURL = "\(supabaseURL)/rest/v1"
    static let authURL = "\(supabaseURL)/auth/v1"
    static let storageURL = "\(supabaseURL)/storage/v1"
    
    // MARK: - App Configuration
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - Feature Flags
    static let enableOfflineMode = true
    static let enablePushNotifications = true
    static let enableBiometricAuth = true
    
    // MARK: - Cache Configuration
    static let cacheExpirationMinutes = 30
    static let maxCacheSize = 100 // MB
}
