# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AXM KeyTool is a macOS SwiftUI application for managing Apple Business Manager and Apple School Manager API tokens. The app generates JWT tokens from Apple-provided private keys and exchanges them for access tokens to interact with Apple's business APIs.

## Build Commands

### Building the project
```bash
# Build for Debug
xcodebuild -scheme "AXM KeyTool" -configuration Debug build

# Build for Release
xcodebuild -scheme "AXM KeyTool" -configuration Release build

# Build and run (requires Xcode)
open "AXM KeyTool.xcodeproj"
```

### Running the app
The app must be built and run through Xcode since it's a macOS application with SwiftUI.

## Architecture

### Core Components

**Data Layer (SwiftData)**
- `TokenConfiguration.swift` - Core data model for storing token configurations
- Uses SwiftData for persistence with automatic model container setup
- Stores Apple ID, Client ID, Key ID, service type, and token metadata

**Services Layer**
- `JWTGenerator.swift` - Handles JWT token generation using ES256 algorithm
  - Supports multiple private key formats (PEM, PKCS#8, SEC1, DER)
  - Converts between key formats as needed
  - Generates Apple-compliant JWT tokens with proper claims
- `AppleAPIClient.swift` - Manages OAuth2 token exchange with Apple's servers
- `KeychainService.swift` - Secure storage for private keys and sensitive data
- `TokenService.swift` - Orchestrates token generation and management workflow

**UI Layer (SwiftUI)**
- `MainView.swift` - Main navigation container with sidebar/detail layout
- `DashboardView.swift` - Overview and status dashboard
- `TokenManagementView.swift` - CRUD operations for token configurations
- `AddTokenView.swift` - Form for adding new token configurations
- `SettingsView.swift` - Application settings and preferences
- `SidebarView.swift` - Navigation sidebar with tab selection
- `ErrorView.swift` - Error handling and display
- `HelpView.swift` - Documentation and help content

### Key Design Patterns

**SwiftData Integration**
- Model container configured in app entry point with error handling
- `@Query` property wrappers for reactive data binding
- `@Environment(\.modelContext)` for data operations

**JWT Token Generation**
- ES256 algorithm using P-256 curve
- Supports Apple's specific JWT claims structure (iss, aud, sub, iat, exp, jti)
- Handles multiple private key formats with automatic conversion
- 180-day maximum token expiry as per Apple requirements

**OAuth2 Flow**
- Client credentials grant type
- JWT bearer assertion for authentication
- Proper URL encoding and header configuration for Apple's API

**Navigation Architecture**
- NavigationSplitView with sidebar/detail pattern
- Enum-based tab system for type safety
- Centralized navigation state management

## Security Considerations

- Private keys stored securely in Keychain
- JWT tokens have proper expiration handling
- No hardcoded credentials or sensitive data
- Secure key format validation and conversion

## Development Notes

- Uses native SwiftUI and SwiftData (iOS 17+/macOS 14+)
- CryptoKit for cryptographic operations
- Foundation URLSession for network requests
- Requires macOS development environment with Xcode