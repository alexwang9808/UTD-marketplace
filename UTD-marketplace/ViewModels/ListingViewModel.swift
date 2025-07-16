import Foundation

final class ListingViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var messages: [Int: [Message]] = [:]

    /// Appends a new outgoing message for a listing.
    func sendMessage(to listingID: Int, text: String) {
        let msg = Message(
            id: Int(Date().timeIntervalSince1970 * 1000), // Temporary unique id
            listingID: listingID,
            text: text,
            date: Date(),
            isSender: true
        )
        messages[listingID, default: []].append(msg)
        // TODO: hook up real backend / notify seller here
    }
}
