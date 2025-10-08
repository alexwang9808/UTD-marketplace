import SwiftUI

struct TitleView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 28, weight: .bold))
    }
}
