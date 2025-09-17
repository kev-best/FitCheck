import SwiftUI
import PhotosUI

struct CaptureView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme

    @State private var selectionFront: PhotosPickerItem?
    @State private var selectionBack: PhotosPickerItem?
    @State private var imageDataFront: Data?
    @State private var imageDataBack: Data?
    @State private var showPosted = false

    var canPost: Bool { imageDataFront != nil && imageDataBack != nil }

    var body: some View {
        VStack(spacing: 16) {
            Text("Today’s Fit").font(.title2.bold()).padding(.top)
            Text("Capture back (fit) and front (selfie). No filters, just you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                CaptureSlot(title: "Back Camera", imageData: $imageDataBack) {
                    PhotosPicker(selection: $selectionBack, matching: .images, photoLibrary: .shared()) {
                        Label("Choose", systemImage: "photo.on.rectangle")
                    }
                }
                CaptureSlot(title: "Front Camera", imageData: $imageDataFront) {
                    PhotosPicker(selection: $selectionFront, matching: .images, photoLibrary: .shared()) {
                        Label("Choose", systemImage: "photo.on.rectangle")
                    }
                }
            }
            .padding(.horizontal)

            Button {
                app.hasPostedToday = true
                showPosted = true
            } label: {
                Text(canPost ? "Post Fit" : "Select both photos")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .disabled(!canPost)
            .background(canPost ? AnyShapeStyle(.tint) : AnyShapeStyle(.gray.opacity(0.3)))
            .foregroundStyle(canPost ? .white : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
            .padding(.bottom)
            .alert("Posted!", isPresented: $showPosted) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your outfit is now visible to friends.")
            }

            Spacer()
        }
        .background(theme.bg.ignoresSafeArea())
        .onChange(of: selectionFront) { _, new in
            Task { imageDataFront = await loadImageData(from: new) }
        }
        .onChange(of: selectionBack) { _, new in
            Task { imageDataBack = await loadImageData(from: new) }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { /* later: AVFoundation custom camera */ } label: {
                    Image(systemName: "camera.viewfinder")
                }
            }
        }
    }

    func loadImageData(from item: PhotosPickerItem?) async -> Data? {
        guard let item else { return nil }
        return try? await item.loadTransferable(type: Data.self)
    }
}

struct CaptureSlot<Content: View>: View {
    var title: String
    @Binding var imageData: Data?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.bold())
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: 180)
                if let data = imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.aperture").font(.title2)
                        Text("Tap to choose").font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            content
        }
        .frame(maxWidth: .infinity)
    }
}
