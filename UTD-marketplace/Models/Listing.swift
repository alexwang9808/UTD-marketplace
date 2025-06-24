import Foundation

struct Listing: Identifiable {
    let id = UUID()
    let title: String
    let price: String
    let description: String
    let imageData: Data
}
