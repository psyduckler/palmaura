import SwiftUI

struct PalmCanvasView: View {
    let photoURL: URL?
    let auraColor: AuraColor

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                palmImage
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                Rectangle()
                    .fill(Color.black.opacity(0.10))
                    .blendMode(.multiply)

                Rectangle()
                    .fill(auraGradient)
                    .opacity(0.24)
                    .blendMode(.screen)

                LinearGradient(
                    colors: [.clear, DesignSystem.ColorToken.skyDeep.opacity(0.34)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.multiply)

                PalmMapFrame()
                    .padding(13)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Palm photo map with aura glow.")
        }
        .aspectRatio(0.72, contentMode: .fit)
        .onAppear {
            Analytics.shared.track("palm_canvas_rendered", properties: ["mode": "photo_map"])
        }
    }

    private var palmImage: some View {
        Group {
            if let photoURL, let image = UIImage(contentsOfFile: photoURL.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            DesignSystem.ColorToken.skyDeep,
                            DesignSystem.ColorToken.skyMulberry.opacity(0.55),
                            DesignSystem.ColorToken.skyDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    PalmAuraMark(style: .capture, size: 120).opacity(0.75)
                }
            }
        }
    }

    private var auraGradient: RadialGradient {
        RadialGradient(colors: [swiftUIColor.opacity(0.9), .clear], center: .center, startRadius: 24, endRadius: 340)
    }

    private var swiftUIColor: Color {
        switch auraColor {
        case .violet: return .purple
        case .gold: return .yellow
        case .fire: return .orange
        case .moon: return .white
        case .water: return .cyan
        case .rose: return .pink
        }
    }
}

private struct PalmMapFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.28), lineWidth: 1)

            VStack {
                HStack {
                    corner
                    Spacer()
                    corner.rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    corner.rotationEffect(.degrees(-90))
                    Spacer()
                    corner.rotationEffect(.degrees(180))
                }
            }
            .padding(10)
        }
    }

    private var corner: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignSystem.ColorToken.goldCream.opacity(0.62))
                .frame(width: 24, height: 1)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(DesignSystem.ColorToken.goldCream.opacity(0.62))
                    .frame(width: 1, height: 24)
                Spacer(minLength: 0)
            }
            .frame(width: 24, height: 24)
        }
        .frame(width: 24, height: 24)
    }
}
