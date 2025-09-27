//
//  UTD_marketplaceApp.swift
//  UTD-marketplace
//
//  Created by Alex Wang on 6/11/25.
//

import SwiftUI
import Firebase

@main
struct UTD_marketplaceApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var listingViewModel = ListingViewModel()
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Initialize Firebase when app starts
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(listingViewModel)
                .environmentObject(firebaseManager)
                .onAppear {
                    // Set auth manager reference after state objects are created
                    firebaseManager.authManager = authManager
                }
        }
    }
}
