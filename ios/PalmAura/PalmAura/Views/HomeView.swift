import SwiftUI

/// Home / Welcome screen — V7 "Constellation" design. Palm image with star
/// constellation overlaid on the mounts and line endpoints, then headline +
/// theme chips + primary/secondary CTAs. For returning users, shows the
/// last reading panel as well.
struct HomeView: View {
    @State private var lastReading = LastReadingStore.load()
    @State private var hasProfile = PersonalizationStore.hasCompleteProfile()
    private var lastBundle: ReadingBundle? { lastReading.map { ReadingBundle.restore(reading: $0) } }

    var body: some View {
        ZStack {
            DarkScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 26) {
                    ScreenHeader(eyebrow: "PalmAura", showsHomeButton: false, activeNavItem: .home)
                        .padding(.horizontal, -DesignSystem.Spacing.lg)

                    // Constellation palm hero
                    ConstellationPalm()
                        .frame(maxWidth: 216)
                        .padding(.top, -14)

                    // Title block
                    VStack(spacing: 6) {
                        Text("What answer")
                            .font(DesignSystem.FontToken.display(44))
                            .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                        Text("are you seeking?")
                            .font(DesignSystem.FontToken.display(40, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.goldCream)
                    }
                    .multilineTextAlignment(.center)

                    // Theme chips
                    HStack(spacing: 10) {
                        ForEach(["LOVE", "WORK", "MONEY", "THE PATH"], id: \.self) { chip in
                            Text(chip)
                                .font(DesignSystem.FontToken.caps(9))
                                .tracking(2.5)
                                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))
                                .padding(.vertical, 7)
                                .padding(.horizontal, 11)
                                .overlay(Capsule().stroke(DesignSystem.ColorToken.borderSoft, lineWidth: 1))
                        }
                    }

                    // CTAs
                    VStack(spacing: 12) {
                        NavigationLink {
                            if hasProfile { ReadingQuestionView() } else { OnboardingView() }
                        } label: {
                            Text(lastReading == nil ? "Ask the Palm" : "Ask Again")
                                .font(DesignSystem.FontToken.caps(11))
                                .tracking(4)
                                .textCase(.uppercase)
                                .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.94)))
                                .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.28), radius: 15)
                        }
                        .buttonStyle(.plain)

                        if let bundle = lastBundle {
                            NavigationLink {
                                ReadingResultView(bundle: bundle)
                            } label: {
                                HStack(spacing: 8) {
                                    Text("☽").font(DesignSystem.FontToken.display(15))
                                    Text("Revisit Past Answers")
                                        .font(DesignSystem.FontToken.caps(10))
                                        .tracking(3)
                                        .textCase(.uppercase)
                                }
                                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.86))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.35), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Last-reading recap card (returning users)
                    if let lastReading, let bundle = lastBundle {
                        ParchmentPanel {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("LAST ANSWER")
                                    .font(DesignSystem.FontToken.caps(9))
                                    .tracking(DesignSystem.Tracking.caps)
                                    .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                                Text(lastReading.title)
                                    .font(DesignSystem.FontToken.display(28))
                                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                                Text(lastReading.oneLineSummary)
                                    .font(DesignSystem.FontToken.body(15, italic: true))
                                    .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                                    .lineSpacing(3)
                                NavigationLink {
                                    ReadingResultView(bundle: bundle)
                                } label: {
                                    Text("Full Report")
                                        .font(DesignSystem.FontToken.caps(10))
                                        .tracking(2.6)
                                        .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(DesignSystem.ColorToken.goldCream.opacity(0.94))
                                        )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 2)
                            }
                        }
                    }

                    // How it works (first-time visitors)
                    if lastReading == nil {
                        ParchmentPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("THE RITUAL")
                                    .font(DesignSystem.FontToken.caps(9))
                                    .tracking(DesignSystem.Tracking.caps)
                                    .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                                HomeBullet(numeral: "I",   title: "Ask one question",     detail: "Pick a focus and bring the one thing you want the palm to look into.")
                                HomeBullet(numeral: "II",  title: "Photograph your palm", detail: "Open hand, fingers spread, soft even light.")
                                HomeBullet(numeral: "III", title: "Receive the answer",   detail: "A private reading, palm map, and full report — no share step.")
                            }
                        }
                    }

                    DisclaimerFoot()
                }
                .padding(DesignSystem.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .swipeBackEnabled()
        .onAppear {
            lastReading = LastReadingStore.load()
            hasProfile = PersonalizationStore.hasCompleteProfile()
        }
    }
}

// MARK: - Constellation palm (the V7 hero visualization)

private struct ConstellationPalm: View {
    // Coordinates in a 320×480 viewBox — calibrated to the transparent palm
    // PNG so each star sits on its real anatomical landmark.
    private struct Star: Identifiable {
        let id: String
        let x: CGFloat
        let y: CGFloat
        let r: CGFloat
        let label: String?
        let labelDir: LabelDir
        enum LabelDir { case left, right, top, bottom, none }
    }

    private let viewBoxW: CGFloat = 320
    private let viewBoxH: CGFloat = 480

    private var stars: [Star] {[
        .init(id: "jup",    x: 133, y: 228, r: 3.0, label: "Jupiter", labelDir: .left),
        .init(id: "sat",    x: 181, y: 215, r: 3.4, label: "Saturn",  labelDir: .top),
        .init(id: "apo",    x: 228, y: 215, r: 3.0, label: "Apollo",  labelDir: .top),
        .init(id: "mer",    x: 272, y: 242, r: 2.6, label: "Mercury", labelDir: .right),
        .init(id: "heartR", x: 267, y: 244, r: 2.0, label: nil,       labelDir: .none),
        .init(id: "heartC", x: 181, y: 236, r: 3.6, label: "Heart",   labelDir: .right),
        .init(id: "heartL", x:  91, y: 238, r: 2.0, label: nil,       labelDir: .none),
        .init(id: "headR",  x: 260, y: 263, r: 2.0, label: nil,       labelDir: .none),
        .init(id: "headC",  x: 181, y: 267, r: 2.2, label: nil,       labelDir: .none),
        .init(id: "headL",  x:  77, y: 260, r: 2.0, label: nil,       labelDir: .none),
        .init(id: "mars",   x: 269, y: 287, r: 2.4, label: "Mars",    labelDir: .right),
        .init(id: "lifeT",  x: 140, y: 231, r: 2.0, label: nil,       labelDir: .none),
        .init(id: "lifeM",  x: 108, y: 281, r: 2.0, label: nil,       labelDir: .none),
        .init(id: "venus",  x: 124, y: 317, r: 3.4, label: "Venus",   labelDir: .left),
        .init(id: "lifeB",  x: 154, y: 394, r: 2.4, label: "Life",    labelDir: .bottom),
        .init(id: "luna",   x: 262, y: 337, r: 2.8, label: "Luna",    labelDir: .right),
        .init(id: "wrist",  x: 179, y: 417, r: 2.0, label: nil,       labelDir: .none),
    ]}

    /// Pairs of star ids to connect with thin gold lines.
    private let connectorIDs: [(String, String)] = [
        ("jup","sat"), ("sat","apo"), ("apo","mer"),
        ("heartL","heartC"), ("heartC","heartR"),
        ("headL","headC"), ("headC","headR"),
        ("heartC","headC"),
        ("jup","lifeT"), ("lifeT","lifeM"), ("lifeM","venus"),
        ("venus","lifeB"), ("lifeB","wrist"),
        ("mer","mars"), ("mars","luna"), ("luna","lifeB"),
        ("heartR","mer"),
    ]

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width / viewBoxW, geo.size.height / viewBoxH)
            let offsetX = (geo.size.width - viewBoxW * s) / 2
            let offsetY = (geo.size.height - viewBoxH * s) / 2

            ZStack {
                // Transparent engraved palm plate. Use the detailed palmistry PNG here
                // instead of the flat gold mask so the hero shows the actual hand artwork.
                Image("PalmPlate")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.68)
                    .shadow(color: DesignSystem.ColorToken.goldCream.opacity(0.12), radius: 10, y: 4)

                // Connector lines + stars
                Canvas { ctx, size in
                    let starByID: [String: Star] = Dictionary(uniqueKeysWithValues: stars.map { ($0.id, $0) })

                    // lines
                    for (a, b) in connectorIDs {
                        guard let s1 = starByID[a], let s2 = starByID[b] else { continue }
                        var path = Path()
                        path.move(to: CGPoint(x: offsetX + s1.x * s, y: offsetY + s1.y * s))
                        path.addLine(to: CGPoint(x: offsetX + s2.x * s, y: offsetY + s2.y * s))
                        ctx.stroke(path, with: .color(DesignSystem.ColorToken.goldCream.opacity(0.55)),
                                   style: .init(lineWidth: 0.8, lineCap: .round))
                    }

                    // halos + cores
                    for star in stars {
                        let cx = offsetX + star.x * s
                        let cy = offsetY + star.y * s
                        let haloRadius = star.r * 3 * s
                        let coreRadius = star.r * s
                        let halo = Path(ellipseIn: CGRect(x: cx - haloRadius, y: cy - haloRadius, width: haloRadius * 2, height: haloRadius * 2))
                        ctx.fill(halo, with: .color(DesignSystem.ColorToken.goldCream.opacity(0.22)))
                        let core = Path(ellipseIn: CGRect(x: cx - coreRadius, y: cy - coreRadius, width: coreRadius * 2, height: coreRadius * 2))
                        ctx.fill(core, with: .color(DesignSystem.ColorToken.goldCreamSoft))
                    }
                }

                // Labels (rendered as SwiftUI Text so they get nice antialiasing + paint-order trick via shadow)
                ForEach(stars) { star in
                    if let label = star.label {
                        Text(label)
                            .font(DesignSystem.FontToken.body(10.5, italic: true))
                            .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.95))
                            .shadow(color: DesignSystem.ColorToken.skyDeep.opacity(0.95), radius: 1)
                            .shadow(color: DesignSystem.ColorToken.skyDeep.opacity(0.85), radius: 2)
                            .position(labelPosition(for: star, scale: s, offsetX: offsetX, offsetY: offsetY))
                    }
                }
            }
        }
        .aspectRatio(viewBoxW / viewBoxH, contentMode: .fit)
    }

    private func labelPosition(for star: Star, scale s: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> CGPoint {
        let baseX = offsetX + star.x * s
        let baseY = offsetY + star.y * s
        switch star.labelDir {
        case .left:   return CGPoint(x: baseX - 28, y: baseY)
        case .right:  return CGPoint(x: baseX + 30, y: baseY)
        case .top:    return CGPoint(x: baseX, y: baseY - 12)
        case .bottom: return CGPoint(x: baseX, y: baseY + 14)
        case .none:   return CGPoint(x: baseX, y: baseY)
        }
    }
}

private struct HomeBullet: View {
    let numeral: String
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(numeral)
                .font(DesignSystem.FontToken.caps(9))
                .foregroundStyle(DesignSystem.ColorToken.skyDeep)
                .frame(width: 28, height: 28)
                .background(Circle().fill(DesignSystem.ColorToken.goldCream.opacity(0.9)))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(DesignSystem.FontToken.display(17)).foregroundStyle(DesignSystem.ColorToken.textPrimary)
                Text(detail).font(DesignSystem.FontToken.body(13)).foregroundStyle(DesignSystem.ColorToken.textSecondary)
            }
        }
    }
}

#Preview { NavigationStack { HomeView() } }
