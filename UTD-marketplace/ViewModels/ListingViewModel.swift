import Foundation

/// Shared source-of-truth for your listings.
final class ListingViewModel: ObservableObject {
    @Published var listings: [Listing] = []
}
