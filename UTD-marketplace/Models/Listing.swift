import Foundation

struct Listing: Identifiable {
    let id: Int
    let title: String
    let price: String
    let description: String
    let location: String
    let imageData: Data
}
