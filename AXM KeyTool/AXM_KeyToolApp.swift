//
//  AXM_KeyToolApp.swift
//  AXM KeyTool
//
//  Created by Mathijs de Ruiter on 01/07/2025.
//

import SwiftUI
import SwiftData
import Foundation

@main
struct AXM_KeyToolApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(createModelContainer())
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([TokenConfiguration.self])
        let configuration = ModelConfiguration(schema: schema)
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            container.mainContext.autosaveEnabled = true
            print("SwiftData container initialized successfully")
            return container
        } catch {
            print("Failed to initialize SwiftData container: \(error)")
            
            // If container creation fails (likely due to schema migration), 
            // clear the problematic data store and create a fresh one
            print("Attempting to clear data store and create fresh container...")
            
            do {
                // Clear the existing data store files
                clearDataStore()
                
                // Create a fresh container
                let freshContainer = try ModelContainer(for: schema, configurations: [configuration])
                freshContainer.mainContext.autosaveEnabled = true
                print("Fresh SwiftData container created successfully after clearing old data")
                return freshContainer
            } catch {
                print("Failed to create fresh container after clearing data: \(error)")
                // As a last resort, create an in-memory container
                print("Creating in-memory container as fallback...")
                do {
                    let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    let memoryContainer = try ModelContainer(for: schema, configurations: [memoryConfiguration])
                    memoryContainer.mainContext.autosaveEnabled = true
                    print("In-memory SwiftData container created successfully")
                    return memoryContainer
                } catch {
                    fatalError("Failed to create any SwiftData container: \(error)")
                }
            }
        }
    }
    
    private func clearDataStore() {
        // Clear SwiftData store files from Application Support directory
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                           in: .userDomainMask).first else {
            print("Could not find Application Support directory")
            return
        }
        
        let storeURL = appSupportURL.appendingPathComponent("default.store")
        let walURL = appSupportURL.appendingPathComponent("default.store-wal")
        let shmURL = appSupportURL.appendingPathComponent("default.store-shm")
        
        let filesToRemove = [storeURL, walURL, shmURL]
        
        for fileURL in filesToRemove {
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                    print("Removed old data store file: \(fileURL.lastPathComponent)")
                }
            } catch {
                print("Failed to remove file \(fileURL.lastPathComponent): \(error)")
            }
        }
    }
}
