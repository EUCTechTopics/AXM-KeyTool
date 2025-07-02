import SwiftUI
import Foundation

struct JWTDebugView: View {
    let jwtToken: String
    @State private var decodedJWT: DecodedJWT?
    @State private var errorMessage: String?
    @State private var showSignature: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Text("JWT Debugger")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let decodedJWT = decodedJWT {
                        // Debug info
                        Text("✅ JWT Successfully Decoded")
                            .font(.headline)
                            .foregroundColor(.green)
                            .padding(.bottom)
                        
                        // Header Section
                        JWTSectionView(
                            title: "Header",
                            content: decodedJWT.header,
                            color: .blue
                        )
                        
                        // Payload Section
                        JWTSectionView(
                            title: "Payload",
                            content: decodedJWT.payload,
                            color: .purple
                        )
                        
                        // Signature Section (Collapsible)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Signature")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                                
                                Button(showSignature ? "Hide" : "Show") {
                                    showSignature.toggle()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            if showSignature {
                                Text("ECDSASHA256(\n  base64UrlEncode(header) + \".\" +\n  base64UrlEncode(payload),\n  \(decodedJWT.keyId ?? "your-private-key")\n)")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                
                                HStack {
                                    Text("Signature (Base64URL)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Button("Copy") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(decodedJWT.signature, forType: .string)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                
                                Text(decodedJWT.signature)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .background(Color(.controlBackgroundColor))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Token Analysis
                        TokenAnalysisView(decodedJWT: decodedJWT)
                        
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            
                            VStack(spacing: 8) {
                                Text("JWT Decode Error")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Decoding JWT...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            print("🔍 JWT Debug View appeared, starting decode...")
            decodeJWT()
        }
        .onChange(of: decodedJWT) { _, newValue in
            if newValue != nil {
                print("🔍 JWT Debug View: decodedJWT state updated successfully")
            }
        }
    }
    
    private func decodeJWT() {
        print("🔍 JWT Debug: Starting decode process")
        print("🔍 JWT Debug: Token length: \(jwtToken.count)")
        print("🔍 JWT Debug: Token prefix: \(String(jwtToken.prefix(50)))...")
        
        do {
            print("🔍 JWT Debug: Attempting to decode JWT")
            decodedJWT = try JWTDecoder.decode(jwtToken)
            print("🔍 JWT Debug: Successfully decoded JWT")
            errorMessage = nil
        } catch {
            print("🔍 JWT Debug: Failed to decode JWT: \(error)")
            errorMessage = "Failed to decode JWT: \(error.localizedDescription)"
            decodedJWT = nil
        }
    }
}

struct JWTSectionView: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            HStack {
                Text("\(title) (JSON)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            ScrollView {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 200)
        }
    }
}

struct TokenAnalysisView: View {
    let decodedJWT: DecodedJWT
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token Analysis")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                AnalysisRow(label: "Algorithm", value: decodedJWT.algorithm ?? "Unknown")
                AnalysisRow(label: "Key ID", value: decodedJWT.keyId ?? "Not specified")
                AnalysisRow(label: "Issuer", value: decodedJWT.issuer ?? "Not specified")
                AnalysisRow(label: "Subject", value: decodedJWT.subject ?? "Not specified")
                AnalysisRow(label: "Audience", value: decodedJWT.audience ?? "Not specified")
                
                if let issuedAt = decodedJWT.issuedAt {
                    AnalysisRow(label: "Issued At", value: formatTimestamp(issuedAt))
                }
                
                if let expiresAt = decodedJWT.expiresAt {
                    AnalysisRow(label: "Expires At", value: formatTimestamp(expiresAt))
                    
                    let now = Date()
                    let expiryDate = Date(timeIntervalSince1970: TimeInterval(expiresAt))
                    let isExpired = expiryDate < now
                    
                    HStack {
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack {
                            Circle()
                                .fill(isExpired ? Color.red : Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text(isExpired ? "Expired" : "Valid")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(isExpired ? .red : .green)
                        }
                    }
                    
                    if !isExpired {
                        let timeRemaining = formatTimeRemaining(until: expiryDate)
                        AnalysisRow(label: "Time Remaining", value: timeRemaining)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTimeRemaining(until date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Expired"
        }
        
        let days = Int(timeInterval) / 86400
        let hours = Int(timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s"), \(hours) hour\(hours == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s"), \(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

struct AnalysisRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - JWT Decoder

struct DecodedJWT: Equatable {
    let header: String
    let payload: String
    let signature: String
    let algorithm: String?
    let keyId: String?
    let issuer: String?
    let subject: String?
    let audience: String?
    let issuedAt: Int?
    let expiresAt: Int?
    let jwtId: String?
}

class JWTDecoder {
    enum JWTError: Error {
        case invalidFormat
        case invalidBase64
        case invalidJSON
    }
    
    static func decode(_ jwt: String) throws -> DecodedJWT {
        print("🔧 JWT Decoder: Input token: \(jwt.prefix(100))...")
        
        let parts = jwt.components(separatedBy: ".")
        print("🔧 JWT Decoder: Found \(parts.count) parts")
        
        guard parts.count == 3 else {
            print("🔧 JWT Decoder: Invalid format - expected 3 parts, got \(parts.count)")
            throw JWTError.invalidFormat
        }
        
        print("🔧 JWT Decoder: Part 0 (header): \(parts[0].prefix(50))...")
        print("🔧 JWT Decoder: Part 1 (payload): \(parts[1].prefix(50))...")
        print("🔧 JWT Decoder: Part 2 (signature): \(parts[2].prefix(50))...")
        
        let header = try decodeBase64URL(parts[0])
        let payload = try decodeBase64URL(parts[1])
        let signature = parts[2]
        
        print("🔧 JWT Decoder: Decoded header: \(header)")
        print("🔧 JWT Decoder: Decoded payload: \(payload)")
        
        // Parse header JSON
        guard let headerData = header.data(using: .utf8) else {
            print("🔧 JWT Decoder: Failed to convert header to data")
            throw JWTError.invalidJSON
        }
        
        let headerJSON = try JSONSerialization.jsonObject(with: headerData) as? [String: Any]
        print("🔧 JWT Decoder: Header JSON: \(headerJSON ?? [:])")
        
        // Parse payload JSON
        guard let payloadData = payload.data(using: .utf8) else {
            print("🔧 JWT Decoder: Failed to convert payload to data")
            throw JWTError.invalidJSON
        }
        
        let payloadJSON = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
        print("🔧 JWT Decoder: Payload JSON: \(payloadJSON ?? [:])")
        
        // Pretty print JSON
        let prettyHeader = try prettyPrintJSON(headerData)
        let prettyPayload = try prettyPrintJSON(payloadData)
        
        print("🔧 JWT Decoder: Successfully decoded JWT")
        
        return DecodedJWT(
            header: prettyHeader,
            payload: prettyPayload,
            signature: signature,
            algorithm: headerJSON?["alg"] as? String,
            keyId: headerJSON?["kid"] as? String,
            issuer: payloadJSON?["iss"] as? String,
            subject: payloadJSON?["sub"] as? String,
            audience: payloadJSON?["aud"] as? String,
            issuedAt: payloadJSON?["iat"] as? Int,
            expiresAt: payloadJSON?["exp"] as? Int,
            jwtId: payloadJSON?["jti"] as? String
        )
    }
    
    private static func decodeBase64URL(_ base64URL: String) throws -> String {
        print("🔧 Base64URL Decoder: Input: \(base64URL)")
        
        var base64 = base64URL
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        print("🔧 Base64URL Decoder: After char replacement: \(base64)")
        
        // Add padding if needed
        let padding = 4 - (base64.count % 4)
        if padding < 4 {
            base64 += String(repeating: "=", count: padding)
            print("🔧 Base64URL Decoder: Added \(padding) padding chars: \(base64)")
        }
        
        guard let data = Data(base64Encoded: base64) else {
            print("🔧 Base64URL Decoder: Failed to decode base64")
            throw JWTError.invalidBase64
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            print("🔧 Base64URL Decoder: Failed to convert data to UTF-8 string")
            throw JWTError.invalidBase64
        }
        
        print("🔧 Base64URL Decoder: Successfully decoded: \(string)")
        return string
    }
    
    private static func prettyPrintJSON(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(data: prettyData, encoding: .utf8) ?? ""
    }
}

#Preview {
    JWTDebugView(jwtToken: "eyJhbGciOiJFUzI1NiIsImtpZCI6IjEyMzQ1Njc4OTAifQ.eyJpc3MiOiJjb20uZXhhbXBsZS5hcHAiLCJhdWQiOiJodHRwczovL2FjY291bnQuYXBwbGUuY29tL2F1dGgvb2F1dGgyL3YyL3Rva2VuIiwic3ViIjoiY29tLmV4YW1wbGUuYXBwIiwiaWF0IjoxNjQwOTk1MjAwLCJleHAiOjE2NDA5OTg4MDAsImp0aSI6IjEyMzQ1Njc4LTkwYWItY2RlZi0xMjM0LTEyMzQ1Njc4OTBhYiJ9.signature")
}