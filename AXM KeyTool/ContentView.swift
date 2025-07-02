//
//  ContentView.swift
//  AXM KeyTool
//
//  Created by Mathijs de Ruiter on 01/07/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: TokenConfiguration.self)
}
