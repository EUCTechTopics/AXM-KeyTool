import Foundation
import SwiftData

class TokenService: ObservableObject {
    
    enum TokenServiceError: Error, LocalizedError {
        case tokenNotFound
        case invalidCredentials
        case networkError(Error)
        case keychainError(Error)
        case jwtGenerationFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .tokenNotFound:
                return "Token configuration not found"
            case .invalidCredentials:
                return "Invalid credentials provided"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .keychainError(let error):
                return "Keychain error: \(error.localizedDescription)"
            case .jwtGenerationFailed(let error):
                return "JWT generation failed: \(error.localizedDescription)"
            }
        }
    }
    
    static let shared = TokenService()
    
    private init() {}
    
    func generateAccessToken(for tokenConfig: TokenConfiguration) async throws {
        do {
            // Get private key from keychain
            let privateKeyData = try KeychainService.shared.getPrivateKey(for: tokenConfig.id)
            
            // Generate JWT
            let jwt = try JWTGenerator.generateJWT(
                clientID: tokenConfig.clientID,
                keyID: tokenConfig.keyID,
                privateKeyData: privateKeyData
            )
            
            // Store JWT token
            try KeychainService.shared.storeJWT(jwt, for: tokenConfig.id)
            
            // Determine scope based on service type
            let scope = tokenConfig.serviceType == .businessManager 
                ? "business.api"
                : "school.api"
            
            // Exchange for access token
            print("Exchanging JWT for access token...")
            let tokenResponse = try await AppleAPIClient.shared.exchangeJWTForAccessToken(
                jwt: jwt,
                clientID: tokenConfig.clientID,
                scope: scope
            )
            
            print("Token exchange successful! Access token received: \(String(tokenResponse.accessToken.prefix(20)))...")
            
            // Store access token
            try KeychainService.shared.storeAccessToken(tokenResponse.accessToken, for: tokenConfig.id)
            print("Access token stored in keychain")
            
            // Update token configuration on main actor to ensure SwiftData tracks changes
            await MainActor.run {
                tokenConfig.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
                tokenConfig.lastRefresh = Date()
                tokenConfig.isActive = true
                print("Token configuration updated - expires in \(tokenResponse.expiresIn) seconds")
                
                // Try to save to the model context if it's available
                // Note: We can't guarantee the context is still valid, but we'll try
                print("TokenService: Token configuration properties updated successfully")
            }
            
        } catch KeychainService.KeychainError.itemNotFound {
            throw TokenServiceError.invalidCredentials
        } catch let keychainError as KeychainService.KeychainError {
            throw TokenServiceError.keychainError(keychainError)
        } catch let jwtError as JWTGenerator.JWTError {
            throw TokenServiceError.jwtGenerationFailed(jwtError)
        } catch let apiError as AppleAPIClient.APIError {
            throw TokenServiceError.networkError(apiError)
        } catch {
            throw TokenServiceError.networkError(error)
        }
    }
    
    func refreshAccessToken(for tokenConfig: TokenConfiguration) async throws {
        // For Apple's API, we need to generate a new JWT and exchange it
        // as they don't provide refresh tokens in the traditional sense
        try await generateAccessToken(for: tokenConfig)
    }
    
    func validateTokenConfiguration(_ tokenConfig: TokenConfiguration) throws -> Bool {
        // Check if we have all required data in keychain
        do {
            let _ = try KeychainService.shared.getPrivateKey(for: tokenConfig.id)
            return true
        } catch {
            throw TokenServiceError.invalidCredentials
        }
    }
    
    func getTokenStatus(for tokenConfig: TokenConfiguration) -> TokenStatus {
        // Check if we have an access token
        do {
            let _ = try KeychainService.shared.getAccessToken(for: tokenConfig.id)
            
            // Check expiry
            if let expiry = tokenConfig.tokenExpiry {
                if expiry > Date() {
                    return .active
                } else {
                    return .expired
                }
            } else {
                return .unknown
            }
        } catch {
            return .notConfigured
        }
    }
    
    func deleteToken(_ tokenConfig: TokenConfiguration, from modelContext: ModelContext) throws {
        // Delete from keychain
        try KeychainService.shared.deleteAllDataForToken(tokenConfig.id)
        
        // Delete from SwiftData
        modelContext.delete(tokenConfig)
        try modelContext.save()
    }
    
    func checkExpiringTokens(_ tokens: [TokenConfiguration], minutesThreshold: Int = 15) -> [TokenConfiguration] {
        let thresholdDate = Date().addingTimeInterval(TimeInterval(minutesThreshold * 60))
        
        return tokens.filter { token in
            guard let expiry = token.tokenExpiry else { return false }
            return expiry <= thresholdDate && expiry > Date()
        }
    }
}