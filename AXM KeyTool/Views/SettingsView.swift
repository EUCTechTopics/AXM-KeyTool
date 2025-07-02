import SwiftUI

struct SettingsView: View {
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("refreshInterval") private var refreshInterval = 24.0
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("notificationThreshold") private var notificationThreshold = 7.0
    
    var body: some View {
        Form {
            Section("Token Management") {
                Toggle("Auto-refresh tokens", isOn: $autoRefreshEnabled)
                    .help("Automatically refresh tokens before they expire")
                
                if autoRefreshEnabled {
                    VStack(alignment: .leading) {
                        Text("Refresh interval: \(Int(refreshInterval)) hours")
                            .font(.subheadline)
                        
                        Slider(value: $refreshInterval, in: 1...168, step: 1) {
                            Text("Refresh Interval")
                        }
                    }
                }
            }
            
            Section("Notifications") {
                Toggle("Enable notifications", isOn: $enableNotifications)
                    .help("Show notifications for token expiration and other events")
                
                if enableNotifications {
                    VStack(alignment: .leading) {
                        Text("Notify when tokens expire in \(Int(notificationThreshold)) days")
                            .font(.subheadline)
                        
                        Slider(value: $notificationThreshold, in: 1...30, step: 1) {
                            Text("Notification Threshold")
                        }
                    }
                }
            }
            
            Section("Security") {
                Button("Clear All Keychain Data") {
                    clearKeychainData()
                }
                .foregroundColor(.red)
                .help("Remove all stored tokens and credentials")
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
                
                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/yourusername/axm-keytool") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private func clearKeychainData() {
        // This would need to be implemented to clear specific keychain items
        // For now, we'll just show an alert
        let alert = NSAlert()
        alert.messageText = "Clear Keychain Data"
        alert.informativeText = "This will remove all stored tokens and credentials. Are you sure?"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Clear")
        alert.alertStyle = .warning
        
        if alert.runModal() == .alertSecondButtonReturn {
            // Clear keychain data
            print("Clearing keychain data...")
        }
    }
}

#Preview {
    SettingsView()
}