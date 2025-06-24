import SwiftUI

struct MessagesView: View {
    // Replace with your real DM data source
    let sampleDMs = [
        ("Alice", "Hey, is that desk still available?"),
        ("Bob", "Can you drop the price by $10?")
    ]

    var body: some View {
        NavigationStack {
            List(sampleDMs, id: \.0) { sender, preview in
                HStack(spacing: 12) {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading) {
                        Text(sender).bold()
                        Text(preview).lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Messages")
        }
    }
}
