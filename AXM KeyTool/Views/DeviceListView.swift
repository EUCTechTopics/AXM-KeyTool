import SwiftUI
import SwiftData

struct DeviceListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tokenConfigurations: [TokenConfiguration]
    
    @State private var selectedToken: TokenConfiguration?
    @State private var devices: [Device] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var cursor: String?
    @State private var hasMore = false
    @State private var showTokenExpiredAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with token selection
            VStack {
                HStack {
                    Text("Organization Devices")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Token Selection
                    if !tokenConfigurations.isEmpty {
                        Menu {
                            ForEach(tokenConfigurations, id: \.id) { token in
                                Button(action: {
                                    selectedToken = token
                                    loadDevices()
                                }) {
                                    HStack {
                                        Label(token.name, systemImage: token.serviceType == .businessManager ? "building.2" : "graduationcap")
                                        Spacer()
                                        if isTokenExpired(token) {
                                            Text("Expired")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let token = selectedToken {
                                    Text(token.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("Select Token")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .disabled(isLoading)
                        
                        Button("Refresh") {
                            loadDevices()
                        }
                        .disabled(selectedToken == nil || isLoading)
                    }
                }
                .padding()
                
                Divider()
            }
            
            // Content
            if tokenConfigurations.isEmpty {
                EmptyTokenView()
            } else if selectedToken == nil {
                SelectTokenView()
            } else if isLoading && devices.isEmpty {
                DeviceLoadingView()
            } else if let errorMessage = errorMessage {
                DeviceErrorView(message: errorMessage, onRetry: loadDevices)
            } else if devices.isEmpty {
                EmptyDevicesView()
            } else {
                DeviceGrid(devices: devices, isLoading: isLoading, hasMore: hasMore, onLoadMore: loadMoreDevices)
            }
        }
        .onAppear {
            if selectedToken == nil && !tokenConfigurations.isEmpty {
                selectedToken = tokenConfigurations.first
                loadDevices()
            }
        }
        .alert("Token Expired", isPresented: $showTokenExpiredAlert) {
            Button("Refresh Token", role: .none) {
                // Navigate to token management or refresh token
                refreshTokenAction()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your access token has expired. Please refresh your token in Token Management to continue accessing device data.")
        }
    }
    
    private func loadDevices() {
        guard let token = selectedToken else { return }
        
        // Check if token is expired before making API request
        if isTokenExpired(token) {
            showTokenExpiredAlert = true
            return
        }
        
        Task {
            await loadDevices(for: token, cursor: nil)
        }
    }
    
    private func loadMoreDevices() {
        guard let token = selectedToken, let cursor = cursor, hasMore else { return }
        
        // Check if token is expired before making API request
        if isTokenExpired(token) {
            showTokenExpiredAlert = true
            return
        }
        
        Task {
            await loadDevices(for: token, cursor: cursor, append: true)
        }
    }
    
    private func isTokenExpired(_ token: TokenConfiguration) -> Bool {
        // Check if we have an access token and if it's valid
        do {
            let _ = try KeychainService.shared.getAccessToken(for: token.id)
            
            if let expiry = token.tokenExpiry {
                return expiry <= Date()
            } else {
                // If no expiry date, consider it expired for safety
                return true
            }
        } catch {
            // If we can't get the access token, consider it expired
            return true
        }
    }
    
    private func refreshTokenAction() {
        guard let token = selectedToken else { return }
        
        Task {
            do {
                try await TokenService.shared.generateAccessToken(for: token)
                // After successful refresh, try loading devices again
                await MainActor.run {
                    loadDevices()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to refresh token: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @MainActor
    private func loadDevices(for token: TokenConfiguration, cursor: String?, append: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get access token from keychain
            let accessToken = try KeychainService.shared.getAccessToken(for: token.id)
            
            // Make API request
            let response = try await AppleAPIClient.shared.listOrganizationDevices(
                accessToken: accessToken,
                serviceType: token.serviceType,
                cursor: cursor
            )
            
            if append {
                devices.append(contentsOf: response.devices)
            } else {
                devices = response.devices
            }
            
            self.cursor = response.cursor
            hasMore = response.more ?? false
            
        } catch KeychainService.KeychainError.itemNotFound {
            errorMessage = "Access token not found. Please refresh your token in Token Management."
        } catch AppleAPIClient.APIError.httpError(let statusCode) {
            if statusCode == 401 {
                errorMessage = "Authentication failed. Your token may have expired. Please refresh it in Token Management."
            } else if statusCode == 403 {
                errorMessage = "Access denied. Your token may not have permission to access device data."
            } else if statusCode == 404 {
                errorMessage = "Device endpoint not found. Please check your service type configuration."
            } else if statusCode >= 500 {
                errorMessage = "Apple server error (\(statusCode)). Please try again later."
            } else {
                errorMessage = "API request failed with status \(statusCode). Please try again."
            }
        } catch AppleAPIClient.APIError.networkError(let networkError) {
            errorMessage = "Network error: \(networkError.localizedDescription)"
        } catch AppleAPIClient.APIError.decodingError {
            errorMessage = "Failed to parse device data from Apple's response."
        } catch AppleAPIClient.APIError.noData {
            errorMessage = "No data received from Apple's API."
        } catch AppleAPIClient.APIError.invalidURL {
            errorMessage = "Invalid API URL configuration."
        } catch AppleAPIClient.APIError.invalidResponse {
            errorMessage = "Invalid response from Apple's API."
        } catch {
            errorMessage = "Failed to load devices: \(error.localizedDescription)\n\nError details: \(error)"
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views

struct EmptyTokenView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "key.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Tokens Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add a token in Token Management to view devices.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SelectTokenView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "cursorarrow.click")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Select a Token")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose a token from the dropdown to view its organization devices.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DeviceLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading devices...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DeviceErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Error Loading Devices")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct EmptyDevicesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Devices Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("This organization doesn't have any devices enrolled yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DeviceGrid: View {
    let devices: [Device]
    let isLoading: Bool
    let hasMore: Bool
    let onLoadMore: () -> Void
    
    private let gridColumns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(devices) { device in
                    DeviceCard(device: device)
                        .onAppear {
                            // Load more when approaching the end
                            if device == devices.last && hasMore && !isLoading {
                                onLoadMore()
                            }
                        }
                }
                
                if hasMore {
                    VStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Button("Load More") {
                                onLoadMore()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .padding()
        }
    }
}

struct DeviceCard: View {
    let device: Device
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: device.deviceTypeIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let productType = device.productType {
                        Text(productType)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if let color = device.color {
                    Text(color)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                DeviceDetailRow(label: "Serial Number", value: device.serialNumber)
                
                if let capacity = device.deviceCapacity {
                    DeviceDetailRow(label: "Capacity", value: capacity)
                }
                
                if let status = device.status {
                    DeviceDetailRow(label: "Status", value: status)
                }
                
                DeviceDetailRow(label: "Added", value: device.formattedAddedDate)
                DeviceDetailRow(label: "Updated", value: device.formattedUpdatedDate)
                
                if let partNumber = device.partNumber, !partNumber.isEmpty {
                    DeviceDetailRow(label: "Part Number", value: partNumber)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct DeviceDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer()
        }
    }
}

#Preview {
    DeviceListView()
        .modelContainer(for: TokenConfiguration.self)
}