//
//  ContentView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import Photos
import VisionKit
import Vision

/// A view that displays the final postprocessed output.
struct OutputView: View {

    @Binding var output: UIImage

    var body: some View {
        Image(uiImage: output)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct PhotoView: View {
    @StateObject private var pipeline = EffectsPipeline()

    var asset: PhotoAsset
    var cache: CachedImageManager?
    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?
    @Environment(\.dismiss) var dismiss
    private let imageSize = CGSize(width: 1024, height: 1024)

    @State var points : String = ""
    @State var originalImage: UIImage?
    @State var editedImage: UIImage?

    var body: some View {
        Group {
//            if let originalImage, let editedImage  {
                OutputView(output: $pipeline.output)
//            } else {
//                ProgressView()
//            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .background(Color.secondary)
        .navigationTitle("Photo")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            buttonsView()
                .offset(x: 0, y: -50)
        }
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestUIImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result?.image, let data = result.pngData() {
                        DispatchQueue.main.async {
                            pipeline.inputImage = CIImage(data: data)
                        }
                    }
                }
            }
        }
    }

    private func buttonsView() -> some View {
        HStack(spacing: 60) {

            Button {
                Task {
                    await asset.setIsFavorite(!asset.isFavorite)
                }
            } label: {
                Label("Favorite", systemImage: asset.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 24))
            }

            Button {
                Task {
                    await asset.delete()
                    await MainActor.run {
                        dismiss()
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.system(size: 24))
            }

//            Button("Detect Contours", action: {
//                detectVisionContours()
//            })
        }
        .buttonStyle(.plain)
        .labelStyle(.iconOnly)
        .padding(EdgeInsets(top: 20, leading: 30, bottom: 20, trailing: 30))
        .background(Color.secondary.colorInvert())
        .cornerRadius(15)
    }
}
