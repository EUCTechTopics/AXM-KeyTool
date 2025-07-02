import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Help & Documentation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Everything you need to know about using AXM KeyTool")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Getting Started
                HelpSection(
                    title: "Getting Started",
                    icon: "play.circle.fill",
                    content: [
                        "1. Obtain your credentials from Apple Developer Portal",
                        "2. Download your private key (.p8 file)",
                        "3. Add a new token configuration",
                        "4. Upload your private key and enter credentials",
                        "5. Generate your first access token"
                    ]
                )
                
                // Token Management
                HelpSection(
                    title: "Managing Tokens",
                    icon: "key.fill",
                    content: [
                        "• View all your token configurations in Token Management",
                        "• Check token status and expiration dates",
                        "• Refresh tokens before they expire",
                        "• Delete unused token configurations",
                        "• Monitor token health on the Dashboard"
                    ]
                )
                
                // Security
                HelpSection(
                    title: "Security",
                    icon: "lock.shield.fill",
                    content: [
                        "• All sensitive data is stored in macOS Keychain",
                        "• Private keys are encrypted and never leave your device",
                        "• Access tokens are automatically encrypted",
                        "• App uses sandboxing for additional security",
                        "• No data is sent to third-party services"
                    ]
                )
                
                // Troubleshooting
                HelpSection(
                    title: "Troubleshooting",
                    icon: "wrench.and.screwdriver.fill",
                    content: [
                        "• Ensure your private key file is in P8 format",
                        "• Verify your Client ID and Key ID are correct",
                        "• Check that your Apple Developer account has proper permissions",
                        "• Make sure your certificates haven't expired",
                        "• Try refreshing tokens if authentication fails"
                    ]
                )
                
                // Support
                VStack(alignment: .leading, spacing: 12) {
                    Label("Support", systemImage: "questionmark.circle.fill")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Button("Apple Business Manager API Documentation") {
                            openURL("https://developer.apple.com/documentation/apple-school-and-business-manager-api")
                        }
                        
                        Button("Apple School Manager API Documentation") {
                            openURL("https://developer.apple.com/documentation/apple-school-and-business-manager-api")
                        }
                        
                        Button("Report an Issue") {
                            openURL("https://github.com/yourusername/axm-keytool/issues")
                        }
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct HelpSection: View {
    let title: String
    let icon: String
    let content: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(content, id: \.self) { item in
                    Text(item)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    HelpView()
}