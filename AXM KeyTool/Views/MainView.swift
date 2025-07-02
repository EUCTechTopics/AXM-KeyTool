import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedTab: SidebarTab = .tokenManagement
    @Environment(\.modelContext) private var modelContext
    @Query private var tokenConfigurations: [TokenConfiguration]
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            Group {
                switch selectedTab {
                case .tokenManagement:
                    TokenManagementView()
                case .devices:
                    DeviceListView()
                case .help:
                    HelpView()
                }
            }
            .navigationTitle(selectedTab.title)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

enum SidebarTab: String, CaseIterable {
    case tokenManagement = "Token Management"
    case devices = "Devices"
    case help = "Help & Documentation"
    
    var title: String {
        return self.rawValue
    }
    
    var systemImage: String {
        switch self {
        case .tokenManagement:
            return "key.fill"
        case .devices:
            return "laptopcomputer.and.iphone"
        case .help:
            return "questionmark.circle.fill"
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: TokenConfiguration.self)
}