import SwiftUI

struct DisclaimerFooter: View {
    var body: some View {
        Text(BrandConfig.entertainmentDisclaimer)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.62))
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
    }
}
