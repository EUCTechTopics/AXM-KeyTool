import Foundation
import Security
import CryptoKit

class JWTGenerator {
    
    enum JWTError: Error {
        case invalidPrivateKey
        case signingFailed
        case encodingFailed
        case invalidKeyFormat
    }
    
    static func generateJWT(
        clientID: String,
        keyID: String,
        privateKeyData: Data,
        audience: String = "https://account.apple.com/auth/oauth2/v2/token"
    ) throws -> String {
        
        let header = JWTHeader(
            alg: "ES256",
            kid: keyID
        )
        
        let now = Date()
        let expiration = now.addingTimeInterval(86400 * 180) // 180 days (max allowed)
        
        let payload = JWTPayload(
            iss: clientID, // In Apple's case, client_id is the same as team_id
            aud: audience,
            sub: clientID,
            iat: Int(now.timeIntervalSince1970),
            exp: Int(expiration.timeIntervalSince1970),
            jti: UUID().uuidString
        )
        
        let headerEncoder = JSONEncoder()
        headerEncoder.outputFormatting = []
        let headerData = try headerEncoder.encode(header)
        
        let payloadEncoder = JSONEncoder()
        payloadEncoder.outputFormatting = []
        let payloadData = try payloadEncoder.encode(payload)
        
        let encodedHeader = headerData.base64URLEncodedString()
        let encodedPayload = payloadData.base64URLEncodedString()
        
        let signingInput = "\(encodedHeader).\(encodedPayload)"
        let signingData = signingInput.data(using: .utf8)!
        
        let signature = try signWithES256(data: signingData, privateKeyData: privateKeyData)
        let encodedSignature = signature.base64URLEncodedString()
        
        let jwt = "\(signingInput).\(encodedSignature)"
        print("Generated JWT: \(jwt)")
        
        // Debug: decode and inspect the payload
        if let decodedPayload = Data(base64Encoded: encodedPayload.padding(toLength: ((encodedPayload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)),
           let payloadString = String(data: decodedPayload, encoding: .utf8) {
            print("JWT Payload: \(payloadString)")
        }
        
        return jwt
    }
    
    private static func signWithES256(data: Data, privateKeyData: Data) throws -> Data {
        // First try PEM format (most common for .pem files)
        if let pemString = String(data: privateKeyData, encoding: .utf8),
           pemString.contains("-----BEGIN") {
            
            print("Attempting to parse PEM key...")
            
            // Handle both PKCS#8 and SEC1 formats
            do {
                let privateKey: P256.Signing.PrivateKey
                
                if pemString.contains("-----BEGIN PRIVATE KEY-----") {
                    // PKCS#8 format - convert to DER and use derRepresentation
                    print("Detected PKCS#8 format, converting...")
                    let derData = try convertPKCS8PEMToDER(pemString)
                    privateKey = try P256.Signing.PrivateKey(derRepresentation: derData)
                } else if pemString.contains("-----BEGIN EC PRIVATE KEY-----") {
                    // SEC1 format - try DER representation directly first
                    print("Detected SEC1 format, trying DER representation...")
                    let sec1DerData = try convertSEC1PEMToDER(pemString)
                    do {
                        privateKey = try P256.Signing.PrivateKey(derRepresentation: sec1DerData)
                    } catch {
                        print("SEC1 DER failed, converting to PKCS#8...")
                        let pkcs8PemString = try convertSEC1ToPKCS8(pemString)
                        privateKey = try P256.Signing.PrivateKey(pemRepresentation: pkcs8PemString)
                    }
                } else {
                    // Try as-is for other formats
                    print("Trying original PEM format...")
                    privateKey = try P256.Signing.PrivateKey(pemRepresentation: pemString)
                }
                
                let signature = try privateKey.signature(for: data)
                return signature.rawRepresentation
            } catch {
                print("PEM parsing failed: \(error)")
                throw JWTError.invalidPrivateKey
            }
        }
        
        // Try DER format
        do {
            print("Trying DER format...")
            let privateKey = try P256.Signing.PrivateKey(derRepresentation: privateKeyData)
            let signature = try privateKey.signature(for: data)
            return signature.rawRepresentation
        } catch {
            print("DER parsing failed: \(error)")
        }
        
        // Try raw representation as last resort
        do {
            print("Trying raw representation...")
            let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
            let signature = try privateKey.signature(for: data)
            return signature.rawRepresentation
        } catch {
            print("Raw representation parsing failed: \(error)")
            throw JWTError.invalidPrivateKey
        }
    }
    
    private static func convertPKCS8PEMToDER(_ pemString: String) throws -> Data {
        // Remove PEM headers and whitespace
        let base64String = pemString
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        
        guard let derData = Data(base64Encoded: base64String) else {
            throw JWTError.invalidKeyFormat
        }
        
        return derData
    }
    
    private static func convertSEC1PEMToDER(_ sec1PemString: String) throws -> Data {
        // Extract the base64 content from SEC1 PEM
        let base64String = sec1PemString
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
        
        guard let sec1DerData = Data(base64Encoded: base64String) else {
            throw JWTError.invalidKeyFormat
        }
        
        return sec1DerData
    }
    
    private static func convertSEC1ToPKCS8(_ sec1PemString: String) throws -> String {
        // Extract the base64 content from SEC1 PEM
        let sec1DerData = try convertSEC1PEMToDER(sec1PemString)
        
        // Convert SEC1 DER to PKCS#8 DER
        let pkcs8DerData = try wrapSEC1InPKCS8(sec1DerData)
        
        // Convert back to PEM format
        let pkcs8Base64 = pkcs8DerData.base64EncodedString()
        let pkcs8Pem = "-----BEGIN PRIVATE KEY-----\n" +
                       pkcs8Base64.chunked(into: 64).joined(separator: "\n") +
                       "\n-----END PRIVATE KEY-----"
        
        return pkcs8Pem
    }
    
    private static func wrapSEC1InPKCS8(_ sec1Data: Data) throws -> Data {
        // PKCS#8 wrapper for P-256 EC private key
        // This is the ASN.1 structure for PKCS#8 with P-256 curve
        let p256AlgorithmIdentifier: [UInt8] = [
            0x30, 0x13, // SEQUENCE (AlgorithmIdentifier)
            0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, // OID: ecPublicKey
            0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07 // OID: secp256r1
        ]
        
        var pkcs8Data = Data()
        
        // SEQUENCE header for PKCS#8
        pkcs8Data.append(0x30)
        
        // Calculate total length
        let contentLength = 1 + 1 + p256AlgorithmIdentifier.count + 1 + sec1Data.count
        pkcs8Data.append(contentsOf: encodeLength(contentLength))
        
        // Version (INTEGER 0)
        pkcs8Data.append(contentsOf: [0x02, 0x01, 0x00])
        
        // AlgorithmIdentifier
        pkcs8Data.append(contentsOf: p256AlgorithmIdentifier)
        
        // PrivateKey (OCTET STRING)
        pkcs8Data.append(0x04)
        pkcs8Data.append(contentsOf: encodeLength(sec1Data.count))
        pkcs8Data.append(sec1Data)
        
        return pkcs8Data
    }
    
    private static func encodeLength(_ length: Int) -> [UInt8] {
        if length < 0x80 {
            return [UInt8(length)]
        } else if length < 0x100 {
            return [0x81, UInt8(length)]
        } else if length < 0x10000 {
            return [0x82, UInt8(length >> 8), UInt8(length & 0xFF)]
        } else {
            // For longer lengths, but we shouldn't need this for keys
            return [0x83, UInt8(length >> 16), UInt8((length >> 8) & 0xFF), UInt8(length & 0xFF)]
        }
    }
    
    static func extractKeyIDFromP8File(data: Data) -> String? {
        // This is a simplified approach - in practice, you might need to parse the P8 file
        // or get the Key ID from Apple Developer Portal
        // For now, we'll expect the user to provide it separately
        return nil
    }
}

// MARK: - JWT Structures

private struct JWTHeader: Codable {
    let alg: String
    let kid: String
}

private struct JWTPayload: Codable {
    let iss: String  // Issuer (Team ID / Client ID)
    let aud: String  // Audience (Apple)
    let sub: String  // Subject (Client ID)
    let iat: Int     // Issued at
    let exp: Int     // Expiration
    let jti: String  // JWT ID (unique identifier)
}

// MARK: - Base64URL Encoding Extension

extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

extension String {
    func chunked(into size: Int) -> [String] {
        return stride(from: 0, to: self.count, by: size).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: min(size, self.count - $0))
            return String(self[start..<end])
        }
    }
}