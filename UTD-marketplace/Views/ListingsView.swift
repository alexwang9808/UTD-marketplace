import SwiftUI

struct ListingsView: View {
    @EnvironmentObject var viewModel: ListingViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var sortOption: SortOption = .newest
    @State private var showingSortMenu = false
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var showingSortSheet = false
    @State private var timeSnapshot = Date() // Snapshot for time ago calculations
    @State private var pressedListingId: Int? = nil

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    enum SortOption: String, CaseIterable {
        case priceHighToLow = "Price: High to Low"
        case priceLowToHigh = "Price: Low to High"
        case alphabetical = "A-Z"
        case oldest = "Oldest"
        case newest = "Newest"
    }
    
    var sortedListings: [Listing] {
        let filteredListings: [Listing]
        
        // Filter by search text if searching
        if isSearching && !searchText.isEmpty {
            filteredListings = viewModel.listings.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchText) ||
                (listing.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (listing.location?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        } else {
            filteredListings = viewModel.listings
        }
        
        // Then sort the filtered results
        switch sortOption {
        case .newest:
            return filteredListings.sorted { $0.id ?? 0 > $1.id ?? 0 }
        case .oldest:
            return filteredListings.sorted { $0.id ?? 0 < $1.id ?? 0 }
        case .priceHighToLow:
            return filteredListings.sorted { $0.price > $1.price }
        case .priceLowToHigh:
            return filteredListings.sorted { $0.price < $1.price }
        case .alphabetical:
            return filteredListings.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Clean background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                    .onAppear {
                        // Refresh time snapshot when view appears
                        timeSnapshot = Date()
                        // Ensure listings are fetched when view appears
                        viewModel.fetchListings()
                    }
                
                // Listings content with header
                modernListingsContentWithHeader
            }
            .overlay(
                // Floating sort dropdown overlay
                sortDropdownOverlay,
                alignment: .topTrailing
            )

        }
    }
    
    // MARK: - Sort Dropdown Overlay
    @ViewBuilder
    private var sortDropdownOverlay: some View {
        if showingSortSheet {
            ZStack(alignment: .topTrailing) {
                // Invisible background to catch taps outside
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingSortSheet = false
                        }
                    }
                    .ignoresSafeArea()
                
                // Dropdown positioned correctly
                CustomSortDropdown(
                    currentSelection: $sortOption,
                    isPresented: $showingSortSheet,
                    onSelectionChanged: { timeSnapshot = Date() }
                )
                .offset(x: -16, y: 70) // Position right below the sort button
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity),
                    removal: .scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity)
                ))
            }
            .zIndex(1000)
        }
    }
    
    // MARK: - Modern Toolbar
    private var modernToolbar: some View {
        HStack(spacing: 12) {
            // Search button or search bar
            if isSearching {
                // Modern search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.body)
                    TextField("Search listings...", text: $searchText, onEditingChanged: { editing in
                        if !editing {
                            isSearching = false
                            timeSnapshot = Date() // Refresh time when search editing ends
                        }
                    })
                    .font(.body)
                    .focused($isSearchFieldFocused)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearching = false
                            isSearchFieldFocused = false
                            timeSnapshot = Date() // Refresh time when clearing search
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                )
            } else {
                // Modern search button
                Button(action: {
                    isSearching = true
                    timeSnapshot = Date() // Refresh time when starting search
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFieldFocused = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                        Text("Search")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                }
            }
            
            Spacer()
            
            // Modern sort button
            Button(action: {
                if isSearching {
                    isSearching = false
                    isSearchFieldFocused = false
                    timeSnapshot = Date() // Refresh time when closing search via sort button
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingSortSheet.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Sort")
                        .font(.body)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .rotationEffect(.degrees(showingSortSheet ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: showingSortSheet)
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Modern Listings Content with Header
    private var modernListingsContentWithHeader: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title and orange bar that scroll with content
                VStack(spacing: 0) {
                    TitleView(title: "Listings")
                        .padding(.top, 10)
                    
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                
                // Modern Search and Sort toolbar
                modernToolbar
                
                if viewModel.listings.isEmpty {
                    modernEmptyState
                } else {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                        ForEach(sortedListings) { item in
                            NavigationLink {
                                ListingDetailView(listing: item)
                                    .onAppear {
                                        // Track click when detail view appears
                                        trackListingClick(for: item)
                                    }
                            } label: {
                                modernListingCard(item: item, isPressed: pressedListingId == item.id)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in
                                        pressedListingId = item.id
                                    }
                                    .onEnded { _ in
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            pressedListingId = nil
                                        }
                                    }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Modern Empty State
    private var modernEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Simple shopping illustration
            ZStack {
                
                Image(systemName: "cart")
                    .font(.system(size: 70, weight: .regular))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                Text("No listings yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
    
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Modern Listing Card
    private func modernListingCard(item: Listing, isPressed: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Modern image with enhanced styling
            Group {
                if let imageUrl = item.imageUrls.first, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure(_):
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                                .clipped()
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                        Text("Failed to load")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                )
                        case .empty:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                                .clipped()
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.2)
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                                .clipped()
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1, contentMode: .fill)
                        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
                        .clipped()
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("No image")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(item.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                // Price
                Text("$\(item.priceString)")
                    .font(.title3)
                    .fontWeight(.bold)

                // Seller info
                HStack(spacing: 8) {
                    Group {
                        if let user = item.user,
                           let imageUrl = user.imageUrl,
                           let url = URL(string: "http://localhost:3001\(imageUrl)") {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    )
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .overlay(
                                                                          Image(systemName: "person.fill")
                                          .font(.system(size: 10))
                                          .foregroundColor(.gray)
                                  )
                        }
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    
                    Text(item.user?.name ?? "User \(item.userId ?? 0)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                }

                // Time ago and Click count
                HStack(spacing: 12) {
                    // Time ago
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(item.timeAgo(from: timeSnapshot))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Spacer()
                    
                    // Click count
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(item.clickCount ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            ZStack {
                // Base white rounded rectangle background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
                
                // Gray bubble overlay when pressed
                if isPressed {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                }
            }
        )
    }
    
    // MARK: - Click Tracking
    private func trackListingClick(for listing: Listing) {
        guard let listingId = listing.id else { return }
        
        // Only track clicks if user is authenticated
        if authManager.isAuthenticated {
            viewModel.trackClick(for: listingId, authToken: authManager.authToken) { success, newClickCount in
                if success {
                    print("Click tracked successfully, new count: \(newClickCount ?? 0)")
                    // Refresh listings to show updated count
                    viewModel.fetchListings()
                } else {
                    print("Failed to track click")
                }
            }
        }
    }
}

// MARK: - Custom Sort Dropdown
struct CustomSortDropdown: View {
    @Binding var currentSelection: ListingsView.SortOption
    @Binding var isPresented: Bool
    let onSelectionChanged: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(ListingsView.SortOption.allCases, id: \.self) { option in
                modernSortOptionRow(option: option)
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .frame(width: 240)
        .onTapGesture {
            // Prevent dismissing when tapping inside the dropdown
        }
    }
    
    private func modernSortOptionRow(option: ListingsView.SortOption) -> some View {
        Button(action: {
            currentSelection = option
            onSelectionChanged() // Refresh time snapshot when sort changes
            withAnimation(.easeInOut(duration: 0.2)) {
                isPresented = false
            }
        }) {
            HStack(spacing: 12) {
                // Text
                Text(option.rawValue)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(
                        currentSelection == option ? .orange : .primary
                    )
                
                Spacer()
                
                // Selection indicator
                if currentSelection == option {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        currentSelection == option
                            ? Color.orange.opacity(0.08)
                            : Color.clear
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func sortIconForOption(_ option: ListingsView.SortOption) -> String {
        switch option {
        case .newest:
            return "clock.arrow.circlepath"
        case .oldest:
            return "clock"
        case .priceHighToLow:
            return "arrow.down.circle"
        case .priceLowToHigh:
            return "arrow.up.circle"
        case .alphabetical:
            return "textformat.abc"
        }
    }
}

// MARK: - ListingsView Extension
extension ListingsView {
    
    // MARK: - Helper Functions
    private func sortIconForOption(_ option: SortOption) -> String {
        switch option {
        case .newest:
            return "clock.arrow.circlepath"
        case .oldest:
            return "clock"
        case .priceHighToLow:
            return "arrow.down.circle"
        case .priceLowToHigh:
            return "arrow.up.circle"
        case .alphabetical:
            return "textformat.abc"
        }
    }
}
