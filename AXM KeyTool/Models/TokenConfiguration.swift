import Foundation
import SwiftData

@Model
class TokenConfiguration {
    var id: UUID
    var name: String
    var appleID: String
    var clientID: String
    var keyID: String
    var serviceType: ServiceType
    var createdAt: Date
    var lastRefresh: Date?
    var tokenExpiry: Date?
    var isActive: Bool
    
    init(name: String, appleID: String, clientID: String, keyID: String, serviceType: ServiceType) {
        self.id = UUID()
        self.name = name
        self.appleID = appleID
        self.clientID = clientID
        self.keyID = keyID
        self.serviceType = serviceType
        self.createdAt = Date()
        self.isActive = true
    }
}

enum ServiceType: String, CaseIterable, Codable, Hashable {
    case businessManager = "Apple Business Manager"
    case schoolManager = "Apple School Manager"
    
    var displayName: String {
        return self.rawValue
    }
}