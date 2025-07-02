import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tokenConfigurations: [TokenConfiguration]
    @State private var selectedToken: TokenConfiguration?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // System Status Section
                SystemStatusView()
                
                // Authentication Details Section
                if !tokenConfigurations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Authentication Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if tokenConfigurations.count > 1 {
                                Picker("Select Token", selection: $selectedToken) {
                                    ForEach(tokenConfigurations, id: \.id) { token in
                                        Text(token.name).tag(token as TokenConfiguration?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: 200)
                            }
                        }
                        
                        if let selectedToken = selectedToken ?? tokenConfigurations.first {
                            AuthenticationDetailsView(token: selectedToken)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No tokens available")
                        .foregroundColor(.secondary)
                        .onAppear {
                            print("DashboardView: No tokens found - count: \(tokenConfigurations.count)")
                        }
                }
                
                // Quick Actions Section
                QuickActionsView()
                
                // Token Summary Section
                TokenSummaryView(tokens: tokenConfigurations)
                
                // About Section
                AboutView()
            }
            .padding()
        }
        .onAppear {
            print("DashboardView appeared - found \(tokenConfigurations.count) tokens")
            if selectedToken == nil {
                selectedToken = tokenConfigurations.first
            }
        }
    }
}

struct SystemStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                StatusRow(
                    title: "Authentication",
                    subtitle: "Connected to DEP",
                    isHealthy: true
                )
                
                StatusRow(
                    title: "Certificates",
                    subtitle: "Certificates configured",
                    isHealthy: true
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct StatusRow: View {
    let title: String
    let subtitle: String
    let isHealthy: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isHealthy ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct AuthenticationDetailsView: View {
    let token: TokenConfiguration
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Refresh Token") {
                        Task {
                            await refreshAccessToken()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isRefreshing)
                    
                    Button(action: refreshTokenInfo) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            VStack(spacing: 12) {
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
                
                DetailRow(label: "Apple ID Email", value: token.appleID)
                DetailRow(label: "Client ID", value: token.clientID)
                DetailRow(label: "Key ID", value: token.keyID)
                DetailRow(label: "Time Remaining", value: timeRemaining)
                DetailRow(label: "Expires", value: formatDate(expiryDate))
                
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
        .onAppear {
            loadTokenInfo()
        }
        .sheet(isPresented: $showJWTDebugger) {
            if !jwtToken.isEmpty && jwtToken != "No JWT available" {
                JWTDebugView(jwtToken: jwtToken)
            }
        }
    }
    
    private func maskToken(_ token: String) -> String {
        guard token.count > 12 else { return token }
        
        // For JWT tokens, show more characters since they have a predictable structure
        if token.contains(".") && token.components(separatedBy: ".").count == 3 {
            // JWT token - show first 8 and last 8 characters
            let prefix = String(token.prefix(8))
            let suffix = String(token.suffix(8))
            return "\(prefix)...\(suffix)"
        } else {
            // Access token - show first 6 and last 6 characters
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
    
    private func loadTokenInfo() {
        // Load token information from keychain
        do {
            accessToken = try KeychainService.shared.getAccessToken(for: token.id)
            // Calculate time remaining and other info
            if let expiry = token.tokenExpiry {
                expiryDate = expiry
                timeRemaining = formatTimeRemaining(until: expiry)
                isHealthy = expiry > Date()
            } else {
                timeRemaining = "Unknown"
                isHealthy = false
            }
        } catch {
            // Handle error - token not found or expired
            accessToken = "No token available"
            timeRemaining = "No token"
            isHealthy = false
        }
        
        // Load JWT token from keychain
        do {
            jwtToken = try KeychainService.shared.getJWT(for: token.id)
        } catch {
            // Handle error - JWT not found
            jwtToken = "No JWT available"
        }
    }
    
    private func refreshTokenInfo() {
        loadTokenInfo()
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
}

struct DetailRow: View {
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

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Manage Tokens",
                    icon: "key.fill",
                    color: .green
                ) {
                    // Navigate to token management
                }
                
                QuickActionButton(
                    title: "Generate Certificate",
                    icon: "doc.badge.plus",
                    color: .green
                ) {
                    // Generate certificate action
                }
                
                QuickActionButton(
                    title: "View Help",
                    icon: "questionmark.circle.fill",
                    color: .green
                ) {
                    // View help action
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TokenSummaryView: View {
    let tokens: [TokenConfiguration]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Token Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to token management
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ForEach(ServiceType.allCases, id: \.self) { serviceType in
                let count = tokens.filter { $0.serviceType == serviceType }.count
                let activeCount = tokens.filter { $0.serviceType == serviceType && $0.isActive }.count
                let expiredCount = count - activeCount
                
                HStack {
                    Text(serviceType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(count) token\(count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if expiredCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("\(activeCount) active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("\(expiredCount) expired")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    } else if activeCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("\(activeCount) active")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About AXM KeyTool")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("This utility helps you generate access tokens for Apple Business Manager and Apple School Manager APIs.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("With AXM KeyTool, you can:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Generate JWT tokens with ECC signing")
                Text("• Exchange JWTs for access tokens")
                Text("• Securely manage authentication credentials")
                Text("• Track token status and expiration")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: TokenConfiguration.self)
}