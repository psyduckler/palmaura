import AVFoundation
import CoreVideo
import SwiftUI
import UIKit

@MainActor
final class ShareCardRenderer {
    func renderImage(card: ShareCard, oneLineSummary: String) -> UIImage? {
        let view = ShareCardView(card: card, summary: oneLineSummary)
            .frame(width: 1080, height: 1920)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }

    func renderPalmMapImage(bundle: ReadingBundle, title: String = "Palm Map", summary: String) -> UIImage? {
        let view = PalmMapShareCardView(bundle: bundle, title: title, summary: summary)
            .frame(width: 1080, height: 1920)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

private struct PalmMapShareCardView: View {
    let bundle: ReadingBundle
    let title: String
    let summary: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.15, green: 0.05, blue: 0.26), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 42) {
                Spacer(minLength: 90)
                VStack(spacing: 12) {
                    Text("PALMAURA")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(.yellow.opacity(0.86))
                    Text(title.uppercased())
                        .font(.system(size: 76, weight: .black, design: .serif))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(.white)
                }

                PalmCanvasView(
                    photoURL: bundle.photoURL,
                    lineSet: bundle.lineSet,
                    auraColor: bundle.auraColor,
                    activeLine: nil,
                    ignitionProgress: 1,
                    renderingMode: bundle.shouldUsePreciseLines ? .preciseLines : .softGlow
                )
                .frame(width: 820, height: 1120)
                .shadow(color: .yellow.opacity(0.30), radius: 42)

                VStack(spacing: 18) {
                    Text(summary)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.62)
                        .foregroundStyle(.white.opacity(0.95))
                    Text("heart · head · life · fate")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.yellow.opacity(0.78))
                }
                .padding(.horizontal, 84)

                Spacer(minLength: 60)
                Text("\(BrandConfig.domain) · \(BrandConfig.socialHandle) · entertainment only")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.bottom, 58)
            }
        }
    }
}

final class ShareVideoRenderer {
    enum RenderError: Error {
        case couldNotCreateCGImage
        case couldNotCreateWriter
        case couldNotCreatePixelBuffer
        case writerFailed
    }

    func renderVideo(from image: UIImage, duration: TimeInterval = 4, framesPerSecond: Int32 = 24) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            guard let cgImage = image.cgImage else { throw RenderError.couldNotCreateCGImage }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("palmaura-share-\(UUID().uuidString)")
                .appendingPathExtension("mp4")

            let width = 1080
            let height = 1920
            let frameCount = max(1, Int(duration * Double(framesPerSecond)))
            let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            let settings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6_000_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = false
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)

            guard writer.canAdd(input) else { throw RenderError.couldNotCreateWriter }
            writer.add(input)
            guard writer.startWriting() else { throw writer.error ?? RenderError.writerFailed }
            writer.startSession(atSourceTime: .zero)

            let frameDuration = CMTime(value: 1, timescale: framesPerSecond)
            for frame in 0..<frameCount {
                while !input.isReadyForMoreMediaData {
                    try await Task.sleep(nanoseconds: 10_000_000)
                }
                guard let buffer = adaptor.pixelBufferPool.flatMap({ pool in
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                    return pixelBuffer
                }) else { throw RenderError.couldNotCreatePixelBuffer }

                let progress = CGFloat(frame) / CGFloat(max(1, frameCount - 1))
                self.draw(cgImage: cgImage, into: buffer, progress: progress, width: width, height: height)
                let time = CMTimeMultiply(frameDuration, multiplier: Int32(frame))
                if !adaptor.append(buffer, withPresentationTime: time) {
                    throw writer.error ?? RenderError.writerFailed
                }
            }

            input.markAsFinished()
            await writer.finishWriting()
            if writer.status != .completed { throw writer.error ?? RenderError.writerFailed }
            return outputURL
        }.value
    }

    private func draw(cgImage: CGImage, into pixelBuffer: CVPixelBuffer, progress: CGFloat, width: Int, height: Int) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let pulse = sin(progress * .pi)
        let scale = 1.0 + pulse * 0.035
        let drawWidth = CGFloat(width) * scale
        let drawHeight = CGFloat(height) * scale
        let drawRect = CGRect(
            x: (CGFloat(width) - drawWidth) / 2,
            y: (CGFloat(height) - drawHeight) / 2,
            width: drawWidth,
            height: drawHeight
        )
        context.draw(cgImage, in: drawRect)

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.09 + 0.08 * pulse).cgColor)
        context.setLineWidth(10)
        let inset = 54 + 14 * pulse
        context.stroke(CGRect(x: inset, y: inset, width: CGFloat(width) - inset * 2, height: CGFloat(height) - inset * 2))
    }
}
