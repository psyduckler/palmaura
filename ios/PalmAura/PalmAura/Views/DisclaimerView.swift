import SwiftUI

struct DisclaimerView: View {
    @AppStorage("disclaimerAccepted") private var disclaimerAccepted = false

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 24) {
                ScreenHeader(eyebrow: BrandConfig.appName, moon: true)
                    .padding(.horizontal, -24)
                Spacer()
                Image("PalmPlateGold")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170)
                    .opacity(0.72)
                OrnamentRule()
                VStack(spacing: 10) {
                    Text(BrandConfig.appName)
                        .font(DesignSystem.FontToken.display(58))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text("A symbolic palmistry oracle for entertainment and self-reflection.")
                        .font(DesignSystem.FontToken.body(19, italic: true))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .lineSpacing(3)
                }
                ParchmentPanel {
                    VStack(spacing: 10) {
                        Text("ENTERTAINMENT ONLY")
                            .font(DesignSystem.FontToken.caps(10))
                            .tracking(DesignSystem.Tracking.caps)
                            .foregroundStyle(DesignSystem.ColorToken.goldCream)
                        Text("Your photo is sent only to create the reading, then kept locally on this device for your reveal, palm map, and share card unless you delete saved photos in Settings.")
                            .font(DesignSystem.FontToken.body(14))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Not medical, legal, financial, psychological, or life-critical advice.")
                            .font(DesignSystem.FontToken.body(14, italic: true))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                GoldButton(title: "I understand · Begin") {
                    Analytics.shared.track("disclaimer_accepted")
                    disclaimerAccepted = true
                }
                DisclaimerFoot()
            }
            .padding(24)
        }
    }
}

#Preview { DisclaimerView() }
