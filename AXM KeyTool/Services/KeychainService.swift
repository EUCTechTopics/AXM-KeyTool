import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.mathijs.axm-keytool"
    
    private init() {}
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }
    
    
    // MARK: - Private Key Storage
    
    func storePrivateKey(_ keyData: Data, for tokenID: UUID) throws {
        let key = "private_key_\(tokenID.uuidString)"
        try storeData(keyData, for: key)
    }
    
    func getPrivateKey(for tokenID: UUID) throws -> Data {
        let key = "private_key_\(tokenID.uuidString)"
        return try getData(for: key)
    }
    
    func deletePrivateKey(for tokenID: UUID) throws {
        let key = "private_key_\(tokenID.uuidString)"
        try deleteItem(for: key)
    }
    
    // MARK: - Access Token Storage
    
    func storeAccessToken(_ token: String, for tokenID: UUID) throws {
        let key = "access_token_\(tokenID.uuidString)"
        try storeString(token, for: key)
    }
    
    func getAccessToken(for tokenID: UUID) throws -> String {
        let key = "access_token_\(tokenID.uuidString)"
        return try getString(for: key)
    }
    
    func deleteAccessToken(for tokenID: UUID) throws {
        let key = "access_token_\(tokenID.uuidString)"
        try deleteItem(for: key)
    }
    
    // MARK: - JWT Token Storage
    
    func storeJWT(_ jwt: String, for tokenID: UUID) throws {
        let key = "jwt_token_\(tokenID.uuidString)"
        try storeString(jwt, for: key)
    }
    
    func getJWT(for tokenID: UUID) throws -> String {
        let key = "jwt_token_\(tokenID.uuidString)"
        return try getString(for: key)
    }
    
    func deleteJWT(for tokenID: UUID) throws {
        let key = "jwt_token_\(tokenID.uuidString)"
        try deleteItem(for: key)
    }
    
    // MARK: - Generic Storage Methods
    
    private func storeString(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        try storeData(data, for: key)
    }
    
    private func getString(for key: String) throws -> String {
        let data = try getData(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        return string
    }
    
    private func storeData(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try updateData(data, for: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func updateData(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let updateFields: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updateFields as CFDictionary)
        
        if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func getData(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidItemFormat
        }
        
        return data
    }
    
    private func deleteItem(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    // MARK: - Cleanup Methods
    
    func deleteAllDataForToken(_ tokenID: UUID) throws {
        try? deletePrivateKey(for: tokenID)
        try? deleteAccessToken(for: tokenID)
        try? deleteJWT(for: tokenID)
    }
}