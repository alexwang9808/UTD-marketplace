import SwiftUI

struct ListingDetailView: View {
    let listing: Listing

    @EnvironmentObject private var viewModel: ListingViewModel
    @State private var newMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // — Detail Header —
                    if let data = listing.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    }

                    Text(listing.title)
                        .font(.largeTitle).bold()

                    Text("$\(listing.priceString)")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    if let location = listing.location {
                        Text(location)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let description = listing.description {
                        Text(description)
                            .font(.body)
                    }

                    // — Message History —
                    Divider().padding(.vertical, 8)
                    if let id = listing.id {
                        ForEach(viewModel.messages[id] ?? []) { msg in
                            HStack {
                                if msg.isSender { Spacer() }
                                Text(msg.text)
                                    .padding(10)
                                    .background(
                                        msg.isSender
                                            ? Color.blue.opacity(0.7)
                                            : Color.gray.opacity(0.3)
                                    )
                                    .foregroundColor(msg.isSender ? .white : .primary)
                                    .cornerRadius(8)
                                if !msg.isSender { Spacer() }
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // — Input Bar —
            HStack(spacing: 8) {
                TextField("Message…", text: $newMessage)
                    .textFieldStyle(.roundedBorder)

                Button("Send") {
                    let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    if let id = listing.id {
                        viewModel.sendMessage(to: id, text: text)
                        newMessage = ""
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Listing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
