//
//  FitCheckView.swift
//  FitCheck
//

import SwiftUI
import AVFoundation

struct FitCheckView: View {
    @EnvironmentObject var router: Router
    @StateObject private var camera = CameraManager()

    @State private var isDualShot = true
    @State private var showAlert = false
    @State private var alertMsg = ""

    var body: some View {
        ZStack {
            // Keep the bottom safe area for the tab bar so its color doesn't change.
            CameraPreviewContainer(camera: camera)
                .ignoresSafeArea(edges: .top)

            // Top-right toggle (appears only if MultiCam is supported)
            VStack {
                HStack {
                    Spacer()
                    if camera.isDualSupported {
                        Toggle(isOn: $isDualShot) {
                            Text("Dual Shot")
                                .font(.callout.bold())
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()
                        // === Option 1: iOS 17-friendly onChange via custom modifier ===
                        .modifier(OnChangeCompat(value: isDualShot) {
                            Task { await camera.setDualMode(isDualShot) }
                        })
                        .padding(.trailing, 12)
                        .padding(.top, 6)
                    }
                }
                Spacer()
            }
        }
        // Bottom control bar (stays above the tab bar)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 24) {
                Button {
                    Task { await camera.flipCamera() }
                } label: {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: "arrow.triangle.2.circlepath.camera").font(.title3))
                }

                Button {
                    Task {
                        do {
                            let result = try await camera.capturePhoto()
                            router.sheet = .postReview(result)
                        } catch {
                            alertMsg = "Capture failed: \(error)"
                            showAlert = true
                        }
                    }
                } label: {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .shadow(radius: 6)
                        .accessibilityLabel("Shutter")
                }

                Button {
                    router.push(.cameraSettings, in: .fitCheck)
                } label: {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: "gearshape").font(.title3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.clear)
        }
        .task { await camera.start(isDualPreferred: isDualShot) }
        .onDisappear { camera.stop() }
        .alert(alertMsg, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .navigationTitle("FitCheck")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - iOS 17-compatible onChange helper (Option 1)

/// Backward-compatible onChange: uses the iOS 17 API when available, otherwise falls back.
private struct OnChangeCompat<V: Equatable>: ViewModifier {
    let value: V
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            // zero-parameter closure (recommended in iOS 17)
            content.onChange(of: value, initial: false, action)
        } else {
            // old API (deprecated in iOS 17 but needed for iOS 16 targets)
            content.onChange(of: value) { _ in action() }
        }
    }
}

// MARK: - Camera Preview Hosts

private struct CameraPreviewContainer: View {
    @ObservedObject var camera: CameraManager

    var body: some View {
        ZStack {
            // Main (primary) preview
            CameraPreview(layerProvider: { camera.primaryPreviewLayer })

            // If Dual Shot is on, show secondary as PiP
            if camera.isDualEnabled, camera.secondaryPreviewLayer != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CameraPreview(layerProvider: { camera.secondaryPreviewLayer })
                            .frame(width: 120, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(12)
                            .shadow(radius: 6)
                    }
                }
            }
        }
        // On Simulator (no layer) this stays black, which is expected.
        .background(Color.black)
    }
}

/// Hosts an externally-managed AVCaptureVideoPreviewLayer.
private struct CameraPreview: UIViewRepresentable {
    let layerProvider: () -> AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Remove any existing preview layers
        uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        if let layer = layerProvider() {
            layer.frame = uiView.bounds
            layer.videoGravity = .resizeAspectFill
            uiView.layer.addSublayer(layer)
        }
    }
}
