import Foundation

struct Message: Identifiable {
    let id: Int
    let listingID: Int      // which listing this message belongs to
    let text: String
    let date: Date
    let isSender: Bool       // true = me, false = seller
}
