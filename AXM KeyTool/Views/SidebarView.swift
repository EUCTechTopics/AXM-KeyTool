import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab
    
    var body: some View {
        List(SidebarTab.allCases, id: \.self, selection: $selectedTab) { tab in
            Label(tab.title, systemImage: tab.systemImage)
                .tag(tab)
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("AXM KeyTool")
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selectedTab: .constant(.tokenManagement))
    } detail: {
        Text("Detail View")
    }
}