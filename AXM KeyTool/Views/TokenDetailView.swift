import SwiftUI
import SwiftData

struct TokenDetailView: View {
    let token: TokenConfiguration
    @Environment(\.dismiss) private var dismiss
    @State private var accessToken: String = ""
    @State private var jwtToken: String = ""
    @State private var timeRemaining: String = "0 minutes"
    @State private var expiryDate: Date = Date()
    @State private var isHealthy: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var showFullAccessToken: Bool = false
    @State private var showFullJWTToken: Bool = false
    @State private var showJWTDebugger: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(token.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(token.serviceType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
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
                    // Debug info
                    Text("Token: \(token.name) (\(token.id.uuidString))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Token Information
                    TokenInfoSection(token: token)
                    
                    // Authentication Details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Authentication Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Refresh Token") {
                                Task {
                                    await refreshAccessToken()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isRefreshing)
                        }
                        
                        VStack(spacing: 12) {
                            // Access Token
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Access Token")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if !accessToken.isEmpty && accessToken != "No token available" {
                                        HStack(spacing: 8) {
                                            Button(showFullAccessToken ? "Hide" : "Show") {
                                                showFullAccessToken.toggle()
                                                print("🔍 Access token show/hide toggled: \(showFullAccessToken)")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            
                                            Button("Copy") {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(accessToken, forType: .string)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                        }
                                    }
                                }
                                
                                if !accessToken.isEmpty && accessToken != "No token available" {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        Text(showFullAccessToken ? accessToken : maskToken(accessToken))
                                            .font(.system(.caption, design: .monospaced))
                                            .textSelection(.enabled)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.controlBackgroundColor))
                                            .cornerRadius(4)
                                    }
                                } else {
                                    Text(accessToken)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // JWT Token
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("JWT Token")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if !jwtToken.isEmpty && jwtToken != "No JWT available" {
                                        HStack(spacing: 8) {
                                            Button("Debug") {
                                                showJWTDebugger = true
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            
                                            Button(showFullJWTToken ? "Hide" : "Show") {
                                                showFullJWTToken.toggle()
                                                print("🔍 JWT token show/hide toggled: \(showFullJWTToken)")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                            
                                            Button("Copy") {
                                                NSPasteboard.general.clearContents()
                                                NSPasteboard.general.setString(jwtToken, forType: .string)
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)
                                        }
                                    }
                                }
                                
                                if !jwtToken.isEmpty && jwtToken != "No JWT available" {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        Text(showFullJWTToken ? jwtToken : maskToken(jwtToken))
                                            .font(.system(.caption, design: .monospaced))
                                            .textSelection(.enabled)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.controlBackgroundColor))
                                            .cornerRadius(4)
                                    }
                                } else {
                                    Text(jwtToken)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            // Token Status
                            HStack {
                                Text("Time Remaining")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(timeRemaining)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Expires")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatDate(expiryDate))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Token Status")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                HStack {
                                    Circle()
                                        .fill(isHealthy ? Color.green : Color.red)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(isHealthy ? "Active" : "Expired")
                                        .font(.subheadline)
                                        .foregroundColor(isHealthy ? .green : .red)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Actions
                    TokenActionsSection(
                        token: token,
                        isRefreshing: $isRefreshing,
                        onTokenRefresh: {
                            loadTokenInfo()
                        }
                    )
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            print("🔍 TokenDetailView appeared for token: \(token.name)")
            loadTokenInfo()
        }
        .sheet(isPresented: $showJWTDebugger) {
            if !jwtToken.isEmpty && jwtToken != "No JWT available" {
                JWTDebugView(jwtToken: jwtToken)
            }
        }
    }
    
    private func loadTokenInfo() {
        print("🔍 TokenDetailView: Loading token info for \(token.name)")
        
        do {
            accessToken = try KeychainService.shared.getAccessToken(for: token.id)
            print("🔍 TokenDetailView: Found access token")
            if let expiry = token.tokenExpiry {
                expiryDate = expiry
                timeRemaining = formatTimeRemaining(until: expiry)
                isHealthy = expiry > Date()
                print("🔍 TokenDetailView: Token expires at \(expiry), healthy: \(isHealthy)")
            } else {
                timeRemaining = "Unknown"
                isHealthy = false
                print("🔍 TokenDetailView: No expiry date found")
            }
        } catch {
            print("🔍 TokenDetailView: No access token found: \(error)")
            accessToken = "No token available"
            timeRemaining = "No token"
            isHealthy = false
        }
        
        do {
            jwtToken = try KeychainService.shared.getJWT(for: token.id)
            print("🔍 TokenDetailView: Found JWT token")
        } catch {
            print("🔍 TokenDetailView: No JWT token found: \(error)")
            jwtToken = "No JWT available"
        }
        
        print("🔍 TokenDetailView: Load complete - accessToken: \(accessToken.isEmpty ? "empty" : "found"), jwtToken: \(jwtToken.isEmpty ? "empty" : "found")")
    }
    
    private func refreshAccessToken() async {
        isRefreshing = true
        
        do {
            try await TokenService.shared.generateAccessToken(for: token)
            await MainActor.run {
                loadTokenInfo()
                isRefreshing = false
            }
        } catch {
            print("Failed to refresh token: \(error)")
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    
    private func formatTimeRemaining(until date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Expired"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
    
    private func maskToken(_ token: String) -> String {
        guard token.count > 12 else { return token }
        
        if token.contains(".") && token.components(separatedBy: ".").count == 3 {
            let prefix = String(token.prefix(8))
            let suffix = String(token.suffix(8))
            return "\(prefix)...\(suffix)"
        } else {
            let prefix = String(token.prefix(6))
            let suffix = String(token.suffix(6))
            return "\(prefix)...\(suffix)"
        }
    }
}

struct TokenInfoSection: View {
    let token: TokenConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(label: "Name", value: token.name)
                InfoRow(label: "Service Type", value: token.serviceType.displayName)
                InfoRow(label: "Apple ID", value: token.appleID)
                InfoRow(label: "Client ID", value: token.clientID)
                InfoRow(label: "Key ID", value: token.keyID)
                InfoRow(label: "Created", value: formatDate(token.createdAt))
                
                HStack {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Circle()
                            .fill(token.isActive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(token.isActive ? "Active" : "Inactive")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(token.isActive ? .green : .red)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AuthenticationDetailsSection: View {
    let token: TokenConfiguration
    @Binding var accessToken: String
    @Binding var jwtToken: String
    @Binding var timeRemaining: String
    @Binding var expiryDate: Date
    @Binding var isHealthy: Bool
    @Binding var isRefreshing: Bool
    @Binding var showFullAccessToken: Bool
    @Binding var showFullJWTToken: Bool
    @Binding var showJWTDebugger: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Authentication Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh Token") {
                    Task {
                        await refreshAccessToken()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRefreshing)
            }
            
            VStack(spacing: 12) {
                // Access Token
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Access Token")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !accessToken.isEmpty && accessToken != "No token available" {
                            HStack(spacing: 8) {
                                Button(showFullAccessToken ? "Hide" : "Show") {
                                    showFullAccessToken.toggle()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Copy") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(accessToken, forType: .string)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    if !accessToken.isEmpty && accessToken != "No token available" {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(showFullAccessToken ? accessToken : maskToken(accessToken))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                    } else {
                        Text(accessToken)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // JWT Token
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("JWT Token")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !jwtToken.isEmpty && jwtToken != "No JWT available" {
                            HStack(spacing: 8) {
                                Button("Debug") {
                                    showJWTDebugger = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button(showFullJWTToken ? "Hide" : "Show") {
                                    showFullJWTToken.toggle()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Copy") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(jwtToken, forType: .string)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    if !jwtToken.isEmpty && jwtToken != "No JWT available" {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(showFullJWTToken ? jwtToken : maskToken(jwtToken))
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                    } else {
                        Text(jwtToken)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Token Status
                InfoRow(label: "Time Remaining", value: timeRemaining)
                InfoRow(label: "Expires", value: formatDate(expiryDate))
                
                HStack {
                    Text("Token Status")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Circle()
                            .fill(isHealthy ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(isHealthy ? "Active" : "Expired")
                            .font(.subheadline)
                            .foregroundColor(isHealthy ? .green : .red)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func maskToken(_ token: String) -> String {
        guard token.count > 12 else { return token }
        
        if token.contains(".") && token.components(separatedBy: ".").count == 3 {
            let prefix = String(token.prefix(8))
            let suffix = String(token.suffix(8))
            return "\(prefix)...\(suffix)"
        } else {
            let prefix = String(token.prefix(6))
            let suffix = String(token.suffix(6))
            return "\(prefix)...\(suffix)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func refreshAccessToken() async {
        isRefreshing = true
        
        do {
            try await TokenService.shared.generateAccessToken(for: token)
            await MainActor.run {
                // Reload token info after refresh
                do {
                    accessToken = try KeychainService.shared.getAccessToken(for: token.id)
                    if let expiry = token.tokenExpiry {
                        expiryDate = expiry
                        timeRemaining = formatTimeRemaining(until: expiry)
                        isHealthy = expiry > Date()
                    }
                } catch {
                    accessToken = "No token available"
                }
                isRefreshing = false
            }
        } catch {
            print("Failed to refresh token: \(error)")
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func formatTimeRemaining(until date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Expired"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
}

struct TokenActionsSection: View {
    let token: TokenConfiguration
    @Binding var isRefreshing: Bool
    let onTokenRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await generateNewToken()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Generate New JWT")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRefreshing)
                
                Button(action: {
                    Task {
                        await refreshAccessToken()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Refresh Access Token")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRefreshing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func generateNewToken() async {
        isRefreshing = true
        
        do {
            try await TokenService.shared.generateAccessToken(for: token)
            await MainActor.run {
                onTokenRefresh()
                isRefreshing = false
            }
        } catch {
            print("Failed to generate token: \(error)")
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func refreshAccessToken() async {
        isRefreshing = true
        
        do {
            try await TokenService.shared.generateAccessToken(for: token)
            await MainActor.run {
                onTokenRefresh()
                isRefreshing = false
            }
        } catch {
            print("Failed to refresh token: \(error)")
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

struct InfoRow: View {
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

#Preview {
    TokenDetailView(token: TokenConfiguration(
        name: "Test Token",
        appleID: "test@example.com",
        clientID: "TEST.client.id",
        keyID: "ABC123",
        serviceType: .businessManager
    ))
}