import SwiftUI
import PhotosUI

struct AddListingView: View {
    @EnvironmentObject private var viewModel: ListingViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title       = ""
    @State private var location    = "University Village"
    @State private var price       = ""
    @State private var description = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showPriceError = false

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

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    PhotosPicker(
                        selection: $photoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Choose a photo…")
                    }
                    if let data = imageData,
                       let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    }
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
            }
           // .navigationTitle("New Listing")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        guard
                            let data = imageData,
                            !title.isEmpty,
                            !price.isEmpty,
                            !description.isEmpty
                        else { return }

                        // Extend Listing model to include `location` if needed
                        let new = Listing(
                            id: Int(Date().timeIntervalSince1970 * 1000), // Temporary unique id
                            title: title,
                            price: price,
                            description: description,
                            location: location,
                            imageData: data
                        )
                        viewModel.listings.append(new)
                        dismiss()
                    }
                    .disabled(
                        title.isEmpty ||
                        price.isEmpty ||
                        description.isEmpty ||
                        imageData == nil
                    )
                }
            }
        }
        .task(id: photoItem) {
            if let item = photoItem {
                imageData = try? await item.loadTransferable(type: Data.self)
            }
        }
    }
}
