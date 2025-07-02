import SwiftUI
import SwiftData

struct TokenManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tokenConfigurations: [TokenConfiguration]
    @State private var manualTokens: [TokenConfiguration] = []
    @State private var showingAddToken = false
    @State private var selectedToken: TokenConfiguration?
    @State private var refreshTrigger = false
    @State private var useManualFetch = false
    @State private var tokenDetailToShow: TokenConfiguration?
    @State private var tokenToRename: TokenConfiguration?
    @State private var newTokenName: String = ""
    
    var body: some View {
        VStack {
            if tokenConfigurations.isEmpty {
                EmptyStateView {
                    showingAddToken = true
                }
            } else {
                TokenListView(
                    tokens: tokenConfigurations,
                    selectedToken: $selectedToken,
                    onAddToken: { showingAddToken = true },
                    onDeleteToken: deleteToken,
                    onTokenTap: { token in
                        print("🔍 Token tapped: \(token.name)")
                        tokenDetailToShow = token
                        print("🔍 tokenDetailToShow set to: \(token.name)")
                    },
                    onRenameToken: { token in
                        print("🔍 Rename token: \(token.name)")
                        tokenToRename = token
                        newTokenName = token.name
                    }
                )
            }
        }
        .sheet(isPresented: $showingAddToken) {
            AddTokenView()
        }
        .sheet(item: $tokenDetailToShow) { token in
            TokenDetailView(token: token)
        }
        .alert("Rename Token", isPresented: .constant(tokenToRename != nil)) {
            TextField("Token Name", text: $newTokenName)
            Button("Save") {
                saveTokenName()
            }
            Button("Cancel", role: .cancel) {
                cancelRename()
            }
        } message: {
            if let token = tokenToRename {
                Text("Enter a new name for '\(token.name)'")
            }
        }
        .onAppear {
            print("TokenManagementView appeared - found \(tokenConfigurations.count) tokens")
            refreshData()
        }
        .onChange(of: tokenConfigurations) {
            print("TokenManagementView: Token configurations changed - now \(tokenConfigurations.count) tokens")
        }
        .onChange(of: showingAddToken) {
            if !showingAddToken {
                // Sheet was dismissed, refresh the data
                print("AddTokenView dismissed, refreshing data...")
                refreshData()
            }
        }
    }
    
    private func refreshData() {
        // Force refresh by toggling the trigger
        refreshTrigger.toggle()
        
        // Try to refresh the model context
        do {
            try modelContext.save()
            print("Model context refreshed")
            
            // Debug: Check what tokens are actually in the database
            let descriptor = FetchDescriptor<TokenConfiguration>()
            let allTokens = try modelContext.fetch(descriptor)
            print("DEBUG TokenManagementView: Found \(allTokens.count) tokens in database")
            for token in allTokens {
                print("  - Token: \(token.name) (\(token.clientID))")
            }
        } catch {
            print("Failed to refresh model context: \(error)")
        }
    }
    
    private func deleteToken(_ token: TokenConfiguration) {
        // Delete from keychain first
        try? KeychainService.shared.deleteAllDataForToken(token.id)
        
        // Delete from SwiftData
        modelContext.delete(token)
        
        try? modelContext.save()
    }
    
    private func saveTokenName() {
        guard let token = tokenToRename else { return }
        guard !newTokenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelRename()
            return
        }
        
        token.name = newTokenName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try modelContext.save()
            print("🔍 Token renamed to: \(token.name)")
        } catch {
            print("🔍 Failed to save token name: \(error)")
        }
        
        tokenToRename = nil
        newTokenName = ""
    }
    
    private func cancelRename() {
        tokenToRename = nil
        newTokenName = ""
    }
}

struct EmptyStateView: View {
    let onAddToken: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Tokens Configured")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first Apple Business Manager or School Manager token to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddToken) {
                Label("Add Token", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TokenListView: View {
    let tokens: [TokenConfiguration]
    @Binding var selectedToken: TokenConfiguration?
    let onAddToken: () -> Void
    let onDeleteToken: (TokenConfiguration) -> Void
    let onTokenTap: (TokenConfiguration) -> Void
    let onRenameToken: (TokenConfiguration) -> Void
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Token Configurations")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onAddToken) {
                    Label("Add Token", systemImage: "plus")
                }
            }
            .padding()
            
            // Token List
            List(tokens, id: \.id, selection: $selectedToken) { token in
                TokenRowView(token: token, onTap: {
                    onTokenTap(token)
                })
                .contextMenu {
                    Button("View Details") {
                        onTokenTap(token)
                    }
                    
                    Button("Rename") {
                        onRenameToken(token)
                    }
                    
                    Divider()
                    
                    Button("Delete", role: .destructive) {
                        onDeleteToken(token)
                    }
                }
            }
            .listStyle(SidebarListStyle())
        }
    }
}

struct TokenRowView: View {
    let token: TokenConfiguration
    let onTap: () -> Void
    @State private var tokenStatus: TokenStatus = .unknown
    
    var body: some View {
        Button(action: {
            print("🔍 TokenRowView button pressed for: \(token.name)")
            onTap()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(token.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(token.serviceType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Apple ID: \(token.appleID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Client ID: \(token.clientID)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: tokenStatus)
                    
                    if let expiry = token.tokenExpiry {
                        let timeRemaining = formatTimeRemaining(until: expiry)
                        Text(timeRemaining)
                            .font(.caption)
                            .foregroundColor(expiry > Date().addingTimeInterval(1800) ? .secondary : .orange)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            checkTokenStatus()
        }
    }
    
    private func checkTokenStatus() {
        // Check if we have an access token and if it's valid
        do {
            let _ = try KeychainService.shared.getAccessToken(for: token.id)
            
            if let expiry = token.tokenExpiry, expiry > Date() {
                tokenStatus = .active
            } else {
                tokenStatus = .expired
            }
        } catch {
            tokenStatus = .notConfigured
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

struct StatusBadge: View {
    let status: TokenStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
    }
}

enum TokenStatus {
    case active
    case expired
    case notConfigured
    case unknown
    
    var displayName: String {
        switch self {
        case .active:
            return "Active"
        case .expired:
            return "Expired"
        case .notConfigured:
            return "Not Configured"
        case .unknown:
            return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .active:
            return .green
        case .expired:
            return .red
        case .notConfigured:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

#Preview {
    TokenManagementView()
        .modelContainer(for: TokenConfiguration.self)
}
