import SwiftUI

struct ListingsView: View {
    @EnvironmentObject var viewModel: ListingViewModel
    @State private var sortOption: SortOption = .newest
    @State private var showingSortMenu = false
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool

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
            VStack(spacing: 0) {
                                            // Clean, straight black line under nav bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(height: 4)
                    .edgesIgnoringSafeArea(.horizontal)
                
                // Search and Sort buttons below orange bar
                HStack {
                    // Search button or search bar (left side)
                    if isSearching {
                        // Search bar replaces search button
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search listings...", text: $searchText, onEditingChanged: { editing in
                                if !editing {
                                    // When user taps outside and loses focus, revert to search button
                                    isSearching = false
                                }
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .focused($isSearchFieldFocused)
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    isSearching = false
                                    isSearchFieldFocused = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    } else {
                        // Search button
                        Button(action: {
                            isSearching = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isSearchFieldFocused = true
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .font(.caption)
                                Text("Search")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    // Sort button (right)
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                // Close search bar if it's open
                                if isSearching {
                                    isSearching = false
                                    isSearchFieldFocused = false
                                }
                                sortOption = option
                            }) {
                                HStack {
                                    Text(option.rawValue)
                                    Spacer()
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Sort")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                VStack(spacing: 20) {
                ScrollView {
                    if viewModel.listings.isEmpty {
                        VStack(spacing: 16) {
                            Text("No listings at the moment.")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sortedListings) { item in
                                NavigationLink {
                                    ListingDetailView(listing: item)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let imageUrl = item.primaryImageUrl, let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                case .failure(_):
                                                    Rectangle()
                                                        .fill(Color.red.opacity(0.3))
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            Image(systemName: "exclamationmark.triangle")
                                                                .foregroundColor(.red)
                                                        )
                                                case .empty:
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                        .overlay(
                                                            ProgressView()
                                                        )
                                                @unknown default:
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .aspectRatio(1, contentMode: .fill)
                                                        .frame(maxWidth: .infinity)
                                                        .clipped()
                                                        .cornerRadius(8)
                                                }
                                            }
                                                                } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .aspectRatio(1, contentMode: .fill)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .cornerRadius(8)
                                                .overlay(
                                                    Image(systemName: "photo")
                                                        .foregroundColor(.gray)
                                                        .font(.title)
                                                )
                                        }

                                        Text(item.title)
                                            .font(.subheadline)
                                            .lineLimit(1)

                                        // Seller info
                                        HStack(spacing: 6) {
                                            // Seller profile picture
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
                                                            .fill(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2))
                                                            .overlay(
                                                                Image(systemName: "person.fill")
                                                                    .font(.system(size: 8))
                                                                    .foregroundColor(.blue)
                                                            )
                                                    }
                                                } else {
                                                    Circle()
                                                        .fill(Color(red: 0.0, green: 0.4, blue: 0.2).opacity(0.2))
                                                        .overlay(
                                                            Image(systemName: "person.fill")
                                                                .font(.system(size: 8))
                                                                .foregroundColor(.blue)
                                                        )
                                                }
                                            }
                                            .frame(width: 16, height: 16)
                                            .clipShape(Circle())
                                            
                                            // Seller name
                                            Text(item.user?.name ?? "User \(item.userId ?? 0)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                        }

                                        Text("$\(item.priceString)")
                                            .font(.headline)

                                        if let location = item.location {
                                            Text(location)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
                }
            
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        TitleView(title: "Listings")
                    }
                }

            }

        }
    }
}
