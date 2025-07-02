import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AddTokenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var appleIDEmail = ""
    @State private var clientID = ""
    @State private var keyID = ""
    @State private var serviceType: ServiceType = .businessManager
    @State private var privateKeyData: Data?
    @State private var showingFilePicker = false
    @State private var isGeneratingToken = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var isFormValid: Bool {
        !name.isEmpty && !appleIDEmail.isEmpty && !clientID.isEmpty && !keyID.isEmpty && privateKeyData != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Text("Add Token")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    Task {
                        await saveToken()
                    }
                }
                .disabled(!isFormValid || isGeneratingToken)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Token Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Token Information")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            FormField(title: "Name", text: $name, placeholder: "Enter a name for this token")
                            FormField(title: "Apple ID Email", text: $appleIDEmail, placeholder: "your.email@company.com")
                                .textContentType(.emailAddress)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Service Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Picker("", selection: $serviceType) {
                                    ForEach(ServiceType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Authentication Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Authentication Details")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            FormField(title: "Key ID", text: $keyID, placeholder: "e.g., 2X9R4HXF34")
                            FormField(title: "Client ID", text: $clientID, placeholder: "e.g., BUSINESSAPI.12345678-1234-1234-1234-123456789012")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Private Key
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Private Key")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if privateKeyData != nil {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text("Private key loaded")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        Text("Your private key has been securely loaded")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("No private key selected")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        Text("Select a .p8 or .pem private key file from Apple")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(privateKeyData != nil ? "Change File" : "Select File") {
                                    showingFilePicker = true
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if privateKeyData == nil {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How to get your private key:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("1. Go to Apple Business Manager → API → Manage")
                                        Text("2. Click on your API account name")
                                        Text("3. Download the private key (.p8 file)")
                                        Text("4. Select that file here")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Error display
                    if !errorMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Error")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "pem") ?? UTType.data, UTType(filenameExtension: "p8") ?? UTType.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Failed to access the selected file"
                showingError = true
                return
            }
            
            defer {
                // Stop accessing the security-scoped resource when done
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                privateKeyData = try Data(contentsOf: url)
                
                // Debug: Check the key format
                if let pemString = String(data: privateKeyData!, encoding: .utf8) {
                    print("Private key content preview: \(String(pemString.prefix(100)))...")
                    if pemString.contains("-----BEGIN PRIVATE KEY-----") {
                        print("Detected PKCS#8 PEM format")
                    } else if pemString.contains("-----BEGIN EC PRIVATE KEY-----") {
                        print("Detected SEC1 PEM format")
                    } else {
                        print("Unknown PEM format")
                    }
                }
            } catch {
                errorMessage = "Failed to read private key file: \(error.localizedDescription)"
                showingError = true
            }
            
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    @MainActor
    private func saveToken() async {
        isGeneratingToken = true
        errorMessage = ""
        
        do {
            // Create the token configuration
            let tokenConfig = TokenConfiguration(
                name: name,
                appleID: appleIDEmail,
                clientID: clientID,
                keyID: keyID,
                serviceType: serviceType
            )
            
            print("Created token configuration: \(tokenConfig.name) for \(tokenConfig.appleID)")
            
            // Save sensitive data to keychain first
            if let keyData = privateKeyData {
                try KeychainService.shared.storePrivateKey(keyData, for: tokenConfig.id)
                print("Private key saved to keychain")
            }
            
            // Insert into SwiftData context and save immediately
            print("Inserting token into model context...")
            modelContext.insert(tokenConfig)
            
            print("Saving token to database...")
            try modelContext.save()
            print("Token configuration saved to SwiftData")
            
            // Verify the save worked
            let verifyDescriptor = FetchDescriptor<TokenConfiguration>()
            let verifyTokens = try modelContext.fetch(verifyDescriptor)
            print("IMMEDIATE VERIFICATION: Found \(verifyTokens.count) tokens in database")
            
            // Close the dialog first to avoid context issues
            print("Dismissing AddTokenView...")
            dismiss()
            
            // Generate token in the background without blocking the UI
            Task {
                do {
                    print("Starting background token generation...")
                    try await TokenService.shared.generateAccessToken(for: tokenConfig)
                    print("Background token generation completed successfully")
                } catch {
                    print("Background token generation failed: \(error)")
                }
            }
            
        } catch {
            print("Error saving token: \(error)")
            errorMessage = "Failed to save token: \(error.localizedDescription)"
            showingError = true
        }
        
        isGeneratingToken = false
    }
    
    private func generateAccessToken(for tokenConfig: TokenConfiguration) async {
        do {
            print("Starting token generation for: \(tokenConfig.name)")
            try await TokenService.shared.generateAccessToken(for: tokenConfig)
            print("Token generation successful")
            // No need to save model context again here since TokenService updates the same object
            // and it's already saved to the context
        } catch {
            print("Failed to generate access token: \(error)")
            // Don't show error to user here as the token was saved successfully
            // They can regenerate the token later from the management view
        }
    }
}

struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.secondary))
                .textFieldStyle(.roundedBorder)
        }
    }
}

#Preview {
    AddTokenView()
        .modelContainer(for: TokenConfiguration.self)
}