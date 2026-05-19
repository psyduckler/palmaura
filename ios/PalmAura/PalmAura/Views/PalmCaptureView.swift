import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct PalmCaptureView: View {
    let onboardingAnswers: OnboardingAnswers
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @StateObject private var camera = PalmCameraController()

    var body: some View {
        ZStack {
            DarkScreenBackground()
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Capture · Your Palm", back: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Lay your hand")
                        .font(DesignSystem.FontToken.display(36))
                        .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    Text("open.")
                        .font(DesignSystem.FontToken.display(36, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.goldCream)
                    Text("Fingers gently spread. Soft, even light. Hand fills the frame.")
                        .font(DesignSystem.FontToken.body(15, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                        .lineSpacing(2)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.top, 8)
                .padding(.bottom, 18)

                viewfinderCard
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                Spacer(minLength: 18)

                actionStack
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { camera.prepare() }
        .onDisappear { camera.stop() }
        .onChange(of: selectedItem) { _, item in Task { await load(item) } }
        .onChange(of: camera.capturedImage) { _, image in
            guard let image else { return }
            selectedImage = image
        }
        .navigationDestination(isPresented: Binding(get: { selectedImage != nil }, set: { if !$0 { selectedImage = nil } })) {
            if let selectedImage {
                PalmReviewView(image: selectedImage, onboardingAnswers: onboardingAnswers)
            }
        }
    }

    private var viewfinderCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.42))

            if camera.showsLivePreview {
                PalmCameraPreview(session: camera.session)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(Color.black.opacity(0.16))
                    .padding(8)
                    .transition(.opacity)
            }

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.35), lineWidth: 1)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 0.5)
                .padding(8)

            if let message = camera.statusMessage {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 14) {
                        Text(message)
                            .font(DesignSystem.FontToken.body(12, italic: true))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                            .padding(.horizontal, 24)
                        if camera.canOpenSettings {
                            Button {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                                Analytics.shared.track("camera_settings_deeplink_tapped")
                            } label: {
                                Text("OPEN SETTINGS")
                                    .font(DesignSystem.FontToken.caps(9))
                                    .tracking(2.5)
                                    .foregroundStyle(DesignSystem.ColorToken.goldCream)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 18)
                                    .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.6), lineWidth: 0.8))
                                    .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 54)
                }
                .allowsHitTesting(camera.canOpenSettings)
            }

            CornerTicks(color: DesignSystem.ColorToken.goldCream.opacity(0.85), inset: 16, size: 22, thickness: 1.5)

            VStack {
                Spacer()
                Text(camera.alignmentChipTitle)
                    .font(DesignSystem.FontToken.caps(9))
                    .tracking(2.5)
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(Capsule().fill(DesignSystem.ColorToken.goldCream.opacity(0.16)))
                    .overlay(Capsule().stroke(DesignSystem.ColorToken.goldCream.opacity(0.4), lineWidth: 0.6))
                    .padding(.bottom, 18)
            }
        }
        .frame(height: 440)
        .animation(.easeInOut(duration: 0.25), value: camera.showsLivePreview)
    }

    private var actionStack: some View {
        VStack(spacing: 12) {
            GoldButton(title: camera.primaryActionTitle) {
                camera.capturePhoto()
            }
            .disabled(!camera.canCapture)
            .opacity(camera.canCapture ? 1 : 0.5)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: 8) {
                    Text("❑").font(DesignSystem.FontToken.display(15))
                    Text("Choose From Library")
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

    private func load(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        selectedImage = image
        Analytics.shared.track("photo_chosen")
    }
}

/// Four L-shaped corner ticks that frame a viewfinder.
private struct CornerTicks: View {
    let color: Color
    let inset: CGFloat
    let size: CGFloat
    let thickness: CGFloat
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // top-left
            tick(at: CGPoint(x: inset, y: inset), corners: [.topLeading])
            // top-right
            tick(at: CGPoint(x: w - inset - size, y: inset), corners: [.topTrailing])
            // bottom-left
            tick(at: CGPoint(x: inset, y: h - inset - size), corners: [.bottomLeading])
            // bottom-right
            tick(at: CGPoint(x: w - inset - size, y: h - inset - size), corners: [.bottomTrailing])
        }
        .allowsHitTesting(false)
    }
    private func tick(at p: CGPoint, corners: Set<Corner>) -> some View {
        Path { path in
            // horizontal segment
            let yEdge = corners.contains(.topLeading) || corners.contains(.topTrailing) ? p.y : p.y + size
            let xStart: CGFloat = corners.contains(.topLeading) || corners.contains(.bottomLeading) ? p.x : p.x + size * 0.45
            let xEnd: CGFloat = corners.contains(.topLeading) || corners.contains(.bottomLeading) ? p.x + size * 0.55 : p.x + size
            path.move(to: CGPoint(x: xStart, y: yEdge))
            path.addLine(to: CGPoint(x: xEnd, y: yEdge))
            // vertical segment
            let xEdge = corners.contains(.topLeading) || corners.contains(.bottomLeading) ? p.x : p.x + size
            let yStart: CGFloat = corners.contains(.topLeading) || corners.contains(.topTrailing) ? p.y : p.y + size * 0.45
            let yEnd: CGFloat = corners.contains(.topLeading) || corners.contains(.topTrailing) ? p.y + size * 0.55 : p.y + size
            path.move(to: CGPoint(x: xEdge, y: yStart))
            path.addLine(to: CGPoint(x: xEdge, y: yEnd))
        }
        .stroke(color, style: .init(lineWidth: thickness, lineCap: .round))
    }
    enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }
}

private final class PalmCameraController: NSObject, ObservableObject {
    enum Status: Equatable {
        case idle
        case requestingAccess
        case configuring
        case ready
        case capturing
        case denied
        case unavailable
        case failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published var capturedImage: UIImage?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.zonted.palmaura.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var isConfigured = false

    var showsLivePreview: Bool {
        status == .ready || status == .capturing
    }

    var canCapture: Bool {
        status == .ready
    }

    /// True when the user has denied camera access and we can deep-link to
    /// Settings.app so they can re-enable it.
    var canOpenSettings: Bool {
        status == .denied
    }

    var primaryActionTitle: String {
        switch status {
        case .capturing:
            "Holding Still…"
        case .requestingAccess, .configuring, .idle:
            "Opening Camera…"
        case .denied:
            "Camera Access Off"
        case .unavailable:
            "Camera Unavailable"
        case .failed:
            "Try Camera Again"
        case .ready:
            "Take Photo"
        }
    }

    var alignmentChipTitle: String {
        switch status {
        case .ready:
            "LIVE · OPEN PALM"
        case .capturing:
            "CAPTURING · HOLD STILL"
        case .denied:
            "CAMERA ACCESS NEEDED"
        case .unavailable:
            "CAMERA UNAVAILABLE"
        case .failed:
            "CAMERA PAUSED"
        default:
            "OPENING · CAMERA"
        }
    }

    var statusMessage: String? {
        switch status {
        case .idle, .requestingAccess, .configuring:
            "Opening the camera inside this frame…"
        case .denied:
            "Camera access is off. Enable it in Settings, or choose a palm photo from your library."
        case .unavailable:
            "Camera is not available here. On an iPhone, this frame becomes the live palm viewfinder."
        case .failed(let message):
            message
        case .ready, .capturing:
            nil
        }
    }

    func prepare() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            setStatus(.requestingAccess)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.configureAndStart()
                } else {
                    self.setStatus(.denied)
                }
            }
        case .denied, .restricted:
            setStatus(.denied)
        @unknown default:
            setStatus(.failed("Camera permission returned an unknown state. Choose from library for now."))
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func capturePhoto() {
        guard canCapture else { return }
        setStatus(.capturing)
        let settings = AVCapturePhotoSettings()
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureAndStart() {
        setStatus(.configuring)

        sessionQueue.async { [weak self] in
            guard let self else { return }

            do {
                if !self.isConfigured {
                    try self.configureSession()
                    self.isConfigured = true
                }

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                self.setStatus(.ready)
            } catch CameraError.unavailable {
                self.setStatus(.unavailable)
            } catch {
                self.setStatus(.failed("Camera could not start. Try again, or choose from library."))
            }
        }
    }

    private func configureSession() throws {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(for: .video) else {
            setStatus(.unavailable)
            throw CameraError.unavailable
        }

        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        session.sessionPreset = .photo
        defer { session.commitConfiguration() }

        guard session.canAddInput(input) else { throw CameraError.cannotAddInput }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else { throw CameraError.cannotAddOutput }
        session.addOutput(photoOutput)
    }

    private func setStatus(_ status: Status) {
        DispatchQueue.main.async { [weak self] in
            self?.status = status
        }
    }

    private enum CameraError: Error {
        case unavailable
        case cannotAddInput
        case cannotAddOutput
    }
}

extension PalmCameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            setStatus(.failed("Photo capture failed: \(error.localizedDescription)"))
            return
        }

        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            setStatus(.failed("Photo capture failed. Try again, or choose from library."))
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.status = .ready
            Analytics.shared.track("photo_captured")
        }
    }
}

private struct PalmCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        uiView.updateOrientation()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateOrientation()
        }

        func updateOrientation() {
            guard let connection = previewLayer.connection else { return }
            let portraitRotation: CGFloat = 90
            if connection.isVideoRotationAngleSupported(portraitRotation) {
                connection.videoRotationAngle = portraitRotation
            }
        }
    }
}
