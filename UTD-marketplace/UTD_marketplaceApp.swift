//
//  UTD_marketplaceApp.swift
//  UTD-marketplace
//
//  Created by Alex Wang on 6/11/25.
//

import SwiftUI

@main
struct UTD_marketplaceApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var listingViewModel = ListingViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(listingViewModel)
        }
    }
}
