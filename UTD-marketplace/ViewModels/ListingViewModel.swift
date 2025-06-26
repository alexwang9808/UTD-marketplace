import Foundation

final class ListingViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var messages: [UUID: [Message]] = [:]

    /// Appends a new outgoing message for a listing.
    func sendMessage(to listingID: UUID, text: String) {
        let msg = Message(
            listingID: listingID,
            text: text,
            date: Date(),
            isSender: true
        )
        messages[listingID, default: []].append(msg)
        // TODO: hook up real backend / notify seller here
    }
}
