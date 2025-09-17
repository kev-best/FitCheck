//
//  CameraManager.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//

import Foundation
import AVFoundation
import UIKit

/// Bundles images captured from one tap. If Dual Shot is enabled & supported,
/// both `front` and `back` may be present. Otherwise only `primary` is filled.
struct CameraCaptureResult {
    let front: UIImage?
    let back: UIImage?
    var primary: UIImage? { back ?? front }
}

@MainActor
final class CameraManager: NSObject, ObservableObject {
    // MARK: - Published state
    @Published private(set) var isRunning = false
    @Published private(set) var isDualSupported = AVCaptureMultiCamSession.isMultiCamSupported
    @Published private(set) var isDualEnabled = false
    @Published private(set) var activePosition: AVCaptureDevice.Position = .back

    // MARK: - Sessions & IO
    private var singleSession: AVCaptureSession?
    private var multiSession: AVCaptureMultiCamSession?

    private var primaryPhotoOutput = AVCapturePhotoOutput()
    private var secondaryPhotoOutput = AVCapturePhotoOutput()

    private var backInput: AVCaptureDeviceInput?
    private var frontInput: AVCaptureDeviceInput?

    // Preview layers (externally hosted)
    private(set) var primaryPreviewLayer: AVCaptureVideoPreviewLayer?
    private(set) var secondaryPreviewLayer: AVCaptureVideoPreviewLayer?

    // Capture completion holding
    private var continuation: CheckedContinuation<CameraCaptureResult, Error>?

    // MARK: - Public lifecycle
    func start(isDualPreferred: Bool) async {
        #if targetEnvironment(simulator)
        await configureSimulated()
        #else
        if isDualPreferred, isDualSupported {
            await configureDual()
        } else {
            await configureSingle(position: activePosition)
        }
        #endif
        isRunning = true
    }

    func stop() {
        singleSession?.stopRunning()
        multiSession?.stopRunning()
        isRunning = false
    }

    func setDualMode(_ on: Bool) async {
        guard isDualSupported else {
            isDualEnabled = false
            return
        }
        stop()
        if on {
            await configureDual()
        } else {
            await configureSingle(position: activePosition)
        }
        isRunning = true
    }

    func flipCamera() async {
        if isDualEnabled {
            // Swap which preview is "primary" by flipping activePosition
            activePosition = (activePosition == .back) ? .front : .back
            attachPreviewLayersForDual() // just rewire which is main
        } else {
            // Rebuild single session with opposite camera
            activePosition = (activePosition == .back) ? .front : .back
            await configureSingle(position: activePosition)
        }
    }

    // MARK: - Capture
    func capturePhoto() async throws -> CameraCaptureResult {
        #if targetEnvironment(simulator)
        // Simulator path: return placeholder images so the flow is testable.
        let back = placeholderImage("Back (Sim)")
        let front = placeholderImage("Front (Sim)")
        return isDualEnabled
            ? CameraCaptureResult(front: front, back: back)
            : (activePosition == .front
               ? CameraCaptureResult(front: front, back: nil)
               : CameraCaptureResult(front: nil, back: back))
        #else
        guard continuation == nil else { throw ServiceError.unknown("Capture already in progress") }

        // Preflight: ensure there is an active & enabled video connection.
        if !isDualEnabled {
            guard singleSession?.isRunning == true,
                  primaryPhotoOutput.connections.first(where: { $0.isEnabled && $0.isActive }) != nil
            else { throw ServiceError.unsupported }
        } else {
            guard multiSession?.isRunning == true else { throw ServiceError.unsupported }
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CameraCaptureResult, Error>) in
            self.continuation = cont

            if self.isDualEnabled, let _ = self.multiSession {
                // Dual: capture from both outputs
                let proxy = DualDelegateProxy { result in
                    self.continuation?.resume(returning: result)
                    self.continuation = nil
                }
                self.primaryPhotoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: proxy.primary)
                self.secondaryPhotoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: proxy.secondary)
            } else {
                // Single: capture from primary output
                let singleDel = SingleDelegate { image in
                    let result = CameraCaptureResult(
                        front: (self.activePosition == .front ? image : nil),
                        back:  (self.activePosition == .back  ? image : nil)
                    )
                    self.continuation?.resume(returning: result)
                    self.continuation = nil
                } onError: { error in
                    self.continuation?.resume(throwing: error)
                    self.continuation = nil
                }
                self.primaryPhotoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: singleDel)
            }
        }
        #endif
    }

    // MARK: - Configure (Simulator)
    private func configureSimulated() async {
        stop()
        // No real session/layers on Simulator; show a plain black preview.
        primaryPreviewLayer = nil
        secondaryPreviewLayer = nil
        isDualEnabled = false
        singleSession = nil
        multiSession = nil
    }

    private func placeholderImage(_ label: String) -> UIImage {
        let size = CGSize(width: 1080, height: 1440)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let text = NSString(string: label)
            let textSize = text.size(withAttributes: attrs)
            let p = CGPoint(x: (size.width - textSize.width)/2, y: (size.height - textSize.height)/2)
            text.draw(at: p, withAttributes: attrs)
        }
    }

    // MARK: - Configure (Single)
    private func configureSingle(position: AVCaptureDevice.Position) async {
        stop()

        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Clear old preview layers
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        primaryPreviewLayer = preview
        secondaryPreviewLayer = nil

        // Inputs
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else { return }
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(input) { session.addInput(input) }
        backInput = (position == .back) ? input : nil
        frontInput = (position == .front) ? input : nil

        // Outputs
        if session.canAddOutput(primaryPhotoOutput) { session.addOutput(primaryPhotoOutput) }

        session.commitConfiguration()
        session.startRunning()

        // Mirror the front preview for a selfie feel
        if let conn = preview.connection, position == .front {
            conn.isVideoMirrored = true
        }

        isDualEnabled = false
        singleSession = session
        multiSession = nil
    }

    // MARK: - Configure (Dual via MultiCam)
    private func configureDual() async {
        stop()

        guard isDualSupported else {
            await configureSingle(position: activePosition)
            return
        }
        let session = AVCaptureMultiCamSession()
        session.beginConfiguration()

        // Devices
        guard let backDev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let frontDev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            session.commitConfiguration()
            await configureSingle(position: activePosition)
            return
        }

        // Inputs
        guard let backIn = try? AVCaptureDeviceInput(device: backDev),
              let frontIn = try? AVCaptureDeviceInput(device: frontDev) else {
            session.commitConfiguration()
            await configureSingle(position: activePosition)
            return
        }

        if session.canAddInput(backIn) { session.addInputWithNoConnections(backIn) }
        if session.canAddInput(frontIn) { session.addInputWithNoConnections(frontIn) }
        backInput = backIn
        frontInput = frontIn

        // Photo outputs
        let backPhoto = AVCapturePhotoOutput()
        let frontPhoto = AVCapturePhotoOutput()
        if session.canAddOutput(backPhoto) { session.addOutputWithNoConnections(backPhoto) }
        if session.canAddOutput(frontPhoto) { session.addOutputWithNoConnections(frontPhoto) }
        primaryPhotoOutput = backPhoto
        secondaryPhotoOutput = frontPhoto

        // Preview layers (no connections yet)
        let backPreview = AVCaptureVideoPreviewLayer()
        backPreview.videoGravity = .resizeAspectFill
        backPreview.setSessionWithNoConnection(session)
        let frontPreview = AVCaptureVideoPreviewLayer()
        frontPreview.videoGravity = .resizeAspectFill
        frontPreview.setSessionWithNoConnection(session)
        primaryPreviewLayer = backPreview
        secondaryPreviewLayer = frontPreview

        // Connections
        if let backPort = backIn.ports(for: .video,
                                       sourceDeviceType: backDev.deviceType,
                                       sourceDevicePosition: .back).first {
            let backPhotoConn = AVCaptureConnection(inputPorts: [backPort], output: backPhoto)
            if session.canAddConnection(backPhotoConn) { session.addConnection(backPhotoConn) }

            let backPrevConn = AVCaptureConnection(inputPort: backPort, videoPreviewLayer: backPreview)
            if session.canAddConnection(backPrevConn) { session.addConnection(backPrevConn) }
        }

        if let frontPort = frontIn.ports(for: .video,
                                         sourceDeviceType: frontDev.deviceType,
                                         sourceDevicePosition: .front).first {
            let frontPhotoConn = AVCaptureConnection(inputPorts: [frontPort], output: frontPhoto)
            if session.canAddConnection(frontPhotoConn) { session.addConnection(frontPhotoConn) }

            let frontPrevConn = AVCaptureConnection(inputPort: frontPort, videoPreviewLayer: frontPreview)
            if session.canAddConnection(frontPrevConn) { session.addConnection(frontPrevConn) }
            frontPreview.connection?.automaticallyAdjustsVideoMirroring = false
            frontPreview.connection?.isVideoMirrored = true
        }

        session.commitConfiguration()
        session.startRunning()

        multiSession = session
        singleSession = nil
        isDualEnabled = true
        activePosition = .back

        // Attach layers to show correct primary/secondary view
        attachPreviewLayersForDual()
    }

    // When user flips while dual is on, swap which layer is "primary".
    func attachPreviewLayersForDual() {
        guard let backLayer = previewLayer(for: .back),
              let frontLayer = previewLayer(for: .front) else { return }

        if activePosition == .back {
            primaryPreviewLayer = backLayer
            secondaryPreviewLayer = frontLayer
        } else {
            primaryPreviewLayer = frontLayer
            secondaryPreviewLayer = backLayer
        }
    }

    private func previewLayer(for position: AVCaptureDevice.Position) -> AVCaptureVideoPreviewLayer? {
        guard let session = multiSession else { return nil }
        // Find an existing layer for the position by checking connections
        let layers = [primaryPreviewLayer, secondaryPreviewLayer].compactMap { $0 }
        for layer in layers {
            if let inputPort = layer.connection?.inputPorts.first,
               inputPort.sourceDevicePosition == position {
                layer.setSessionWithNoConnection(session) // already set
                return layer
            }
        }
        return nil
    }
}

// MARK: - Photo Delegates

private final class SingleDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let onImage: (UIImage) -> Void
    let onError: (Error) -> Void

    init(onImage: @escaping (UIImage) -> Void, onError: @escaping (Error) -> Void) {
        self.onImage = onImage
        self.onError = onError
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error { onError(error); return }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            onError(ServiceError.unknown("Image decoding failed"))
            return
        }
        onImage(image)
    }
}

private final class DualDelegateProxy {
    final class PartDelegate: NSObject, AVCapturePhotoCaptureDelegate {
        let onFinish: (UIImage?) -> Void
        init(_ onFinish: @escaping (UIImage?) -> Void) { self.onFinish = onFinish }
        func photoOutput(_ output: AVCapturePhotoOutput,
                         didFinishProcessingPhoto photo: AVCapturePhoto,
                         error: Error?) {
            guard error == nil,
                  let data = photo.fileDataRepresentation(),
                  let img = UIImage(data: data) else {
                onFinish(nil)
                return
            }
            onFinish(img)
        }
    }

    // Lazy so they can capture `self` safely after init
    lazy var primary: PartDelegate = PartDelegate { [weak self] img in
        self?.assign(img, isPrimary: true)
    }
    lazy var secondary: PartDelegate = PartDelegate { [weak self] img in
        self?.assign(img, isPrimary: false)
    }

    private var front: UIImage?
    private var back: UIImage?
    private var callbacks = 0
    private let complete: (CameraCaptureResult) -> Void

    init(_ complete: @escaping (CameraCaptureResult) -> Void) {
        self.complete = complete
    }

    private func assign(_ image: UIImage?, isPrimary: Bool) {
        // Heuristic: primary == back, secondary == front
        if isPrimary { back = image } else { front = image }
        callbacks += 1
        if callbacks == 2 {
            complete(CameraCaptureResult(front: front, back: back))
        }
    }
}
