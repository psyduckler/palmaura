import SwiftUI

struct DisclaimerView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false

    var body: some View {
        ZStack {
            MysticalBackground()
            VStack(spacing: 24) {
                Spacer()
                Text(BrandConfig.appName)
                    .font(.custom("Georgia", size: 56).weight(.bold))
                    .foregroundStyle(.white)
                Text("Mystical palm readings for entertainment and self-reflection.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                Text("Not medical, legal, financial, psychological, or life-critical advice.")
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.yellow.opacity(0.9))
                    .padding()
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                Spacer()
                PrimaryButton(title: "I understand — begin") {
                    Analytics.shared.track("disclaimer_accepted")
                    disclaimerAccepted = true
                }
                DisclaimerFooter()
            }
            .padding(24)
        }
    }
}

#Preview { DisclaimerView() }
