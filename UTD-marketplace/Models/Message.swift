import Foundation

struct Message: Identifiable {
    let id = UUID()
    let listingID: UUID      // which listing this message belongs to
    let text: String
    let date: Date
    let isSender: Bool       // true = me, false = seller
}
