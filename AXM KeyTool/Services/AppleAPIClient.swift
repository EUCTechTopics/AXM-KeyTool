import Foundation

class AppleAPIClient {
    
    enum APIError: Error {
        case invalidURL
        case noData
        case decodingError
        case networkError(Error)
        case httpError(Int)
        case invalidResponse
    }
    
    static let shared = AppleAPIClient()
    private let session = URLSession.shared
    
    private init() {}
    
    func exchangeJWTForAccessToken(
        jwt: String,
        clientID: String,
        scope: String = "business.api"
    ) async throws -> TokenResponse {
        
        // Build URL with query parameters like in the curl example
        var components = URLComponents(string: "https://account.apple.com/auth/oauth2/token")!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "client_credentials"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_assertion_type", value: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"),
            URLQueryItem(name: "client_assertion", value: jwt),
            URLQueryItem(name: "scope", value: scope)
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        print("Token exchange URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("account.apple.com", forHTTPHeaderField: "Host")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                // Log the error response for debugging
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Apple API Error (\(httpResponse.statusCode)): \(errorString)")
                }
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw APIError.noData
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func refreshAccessToken(refreshToken: String) async throws -> TokenResponse {
        guard let url = URL(string: "https://appleid.apple.com/auth/oauth2/token") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        let bodyData = parameters.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = bodyData.data(using: .utf8)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse
            
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    func listOrganizationDevices(
        accessToken: String,
        serviceType: ServiceType,
        cursor: String? = nil,
        limit: Int = 100
    ) async throws -> DeviceResponse {
        
        let baseURL = serviceType == .businessManager 
            ? "https://api-business.apple.com/v1/orgDevices"
            : "https://api-school.apple.com/v1/orgDevices"
        
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = []
        
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("AXM-KeyTool/1.0", forHTTPHeaderField: "User-Agent")
        
        // Force HTTP/1.1 to avoid HTTP/2 chunked encoding issues
        request.setValue("HTTP/1.1", forHTTPHeaderField: "Connection")
        
        print("Device API Request: \(request.url?.absoluteString ?? "N/A")")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Device API Error (\(httpResponse.statusCode)): \(errorString)")
                } else {
                    print("Device API Error (\(httpResponse.statusCode)): No response body")
                }
                print("Response headers: \(httpResponse.allHeaderFields)")
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw APIError.noData
            }
            
            let deviceResponse = try JSONDecoder().decode(DeviceResponse.self, from: data)
            return deviceResponse
            
        } catch let error as APIError {
            print("Device API - APIError caught: \(error)")
            throw error
        } catch {
            print("Device API - General error caught: \(error)")
            print("Error type: \(type(of: error))")
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Response Models

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

struct TokenErrorResponse: Codable {
    let error: String
    let errorDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }
}