import Foundation

// MARK: - Device Response Models

struct DeviceResponse: Codable {
    let data: [DeviceData]
    let meta: ResponseMeta?
    
    // Computed property to extract devices from the JSON API format
    var devices: [Device] {
        return data.map { deviceData in
            deviceData.attributes
        }
    }
    
    // For pagination support
    var cursor: String? {
        return meta?.cursor
    }
    
    var more: Bool? {
        return meta?.hasMore
    }
}

struct DeviceData: Codable {
    let type: String
    let id: String
    let attributes: Device
}

struct ResponseMeta: Codable {
    let cursor: String?
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case cursor
        case hasMore = "has_more"
    }
}

struct Device: Codable, Hashable, Identifiable {
    let serialNumber: String
    let addedToOrgDateTime: String?
    let updatedDateTime: String?
    let deviceModel: String?
    let productFamily: String?
    let productType: String?
    let deviceCapacity: String?
    let partNumber: String?
    let orderNumber: String?
    let color: String?
    let status: String?
    let orderDateTime: String?
    let imei: [String]?
    let meid: [String]?
    let eid: String?
    let purchaseSourceId: String?
    let purchaseSourceType: String?
    
    // Computed properties for UI
    var id: String { serialNumber }
    
    var displayName: String {
        if let deviceModel = deviceModel, !deviceModel.isEmpty {
            return deviceModel
        } else if let productFamily = productFamily {
            return productFamily
        } else {
            return "Unknown Device"
        }
    }
    
    var deviceTypeIcon: String {
        guard let productFamily = productFamily?.lowercased() else {
            return "questionmark.square"
        }
        
        switch productFamily {
        case "iphone":
            return "iphone"
        case "ipad":
            return "ipad"
        case "mac":
            return "laptopcomputer"
        case "appletv":
            return "appletv"
        case "watch":
            return "applewatch"
        default:
            return "questionmark.square"
        }
    }
    
    var formattedAddedDate: String {
        guard let addedToOrgDateTime = addedToOrgDateTime else { return "Unknown" }
        return formatDate(addedToOrgDateTime)
    }
    
    var formattedUpdatedDate: String {
        guard let updatedDateTime = updatedDateTime else { return "Never" }
        return formatDate(updatedDateTime)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        } else {
            // Try alternative format without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.timeStyle = .short
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString
    }
}

struct AssignedUser: Codable, Hashable {
    let userId: String?
    let userName: String?
    let email: String?
    let givenName: String?
    let familyName: String?
    
    var displayName: String {
        if let givenName = givenName, let familyName = familyName {
            return "\(givenName) \(familyName)"
        } else if let userName = userName {
            return userName
        } else if let email = email {
            return email
        } else {
            return "Unknown User"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case email
        case givenName = "given_name"
        case familyName = "family_name"
    }
}