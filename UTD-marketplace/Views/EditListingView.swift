import SwiftUI
import PhotosUI

struct EditListingView: View {
    let listing: Listing
    @EnvironmentObject private var viewModel: ListingViewModel
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var location: String
    @State private var price: String
    @State private var description: String

    @State private var showPriceError = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var isUpdating = false
    
    // Dropdown options
    private let locations = [
        "University Village",
        "Canyon Creek",
        "Northside",
        "Vega Hall",
        "Andromeda Hall",
        "Capella Hall",
        "Helix Hall",
        "Sirius Hall",
        "Other"
    ]
    
    init(listing: Listing) {
        self.listing = listing
        self._title = State(initialValue: listing.title)
        self._location = State(initialValue: listing.location ?? "University Village")
        self._price = State(initialValue: String(format: "%.0f", listing.price))
        self._description = State(initialValue: listing.description ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Photos") {
                    if !listing.imageUrls.isEmpty {
                        Text("Current photos: \(listing.imageUrls.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(listing.imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                    if let url = URL(string: "http://localhost:3001\(imageUrl)") {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .overlay(ProgressView())
                                        }
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    } else {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                            Text("No photos")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                    
                    Text("Photos cannot be changed when editing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Details") {
                    TextField("Title", text: $title)
                    
                    // Location dropdown
                    Picker("Location", selection: $location) {
                        ForEach(locations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Price with digits-only filtering
                    TextField("Price", text: Binding(
                        get: { price },
                        set: { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            showPriceError = (filtered != newValue)
                            price = filtered
                        }
                    ))
                    .keyboardType(.numberPad)
                    
                    if showPriceError {
                        Text("Numbers only")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Description", text: $description, axis: .vertical)
                }
                
                Section {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .foregroundColor(.red)
                    }
                    .disabled(isDeleting)
                }
            }
            .navigationTitle("Manage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateListing()
                    }
                    .disabled(
                        title.isEmpty ||
                        price.isEmpty ||
                        description.isEmpty ||
                        isUpdating
                    )
                    .foregroundColor(
                        (title.isEmpty || price.isEmpty || description.isEmpty || isUpdating)
                        ? .gray : Color(red: 0.0, green: 0.4, blue: 0.2)
                    )
                }
            }
            .alert("Delete", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteListing()
                }
            } message: {
                Text("Are you sure you want to delete this listing?")
            }
        }
    }
    
    private func updateListing() {
        guard let listingId = listing.id else { return }
        
        isUpdating = true
        
        viewModel.updateListing(
            id: listingId,
            title: title,
            price: price,
            description: description,
            location: location,
            imageDataArray: nil,
            authToken: authManager.authToken
        ) { success in
            DispatchQueue.main.async {
                isUpdating = false
                if success {
                    dismiss()
                } else {
                    print("Failed to update listing")
                }
            }
        }
    }
    
    private func deleteListing() {
        guard let listingId = listing.id else { return }
        
        isDeleting = true
        
        viewModel.deleteListing(id: listingId, authToken: authManager.authToken) { success in
            DispatchQueue.main.async {
                isDeleting = false
                if success {
                    dismiss()
                } else {
                    print("Failed to delete listing")
                }
            }
        }
    }
}