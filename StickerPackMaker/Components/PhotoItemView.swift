//
//  PhotoCollection.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import Photos

struct PhotoItemView: View {
    var asset: PhotoAsset
    var cache: CachedImageManager?
    var imageSize: CGSize
    @State private var pets: [String] = []

    @State private var image: Image?
    @State private var imageRequestID: PHImageRequestID?

    var body: some View {

        Group {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .overlay(alignment: .center, content: {
            HStack {
                ForEach(pets, id: \.self) { pet in
                    Text("🐶")
                        .padding()
                        .background(alignment: .center) {
                            Circle().fill(.tint)
                        }
                }
            }

        })
        .task {
            guard image == nil, let cache = cache else { return }
            imageRequestID = await cache.requestUIImage(for: asset, targetSize: imageSize) { result in
                Task {
                    if let result = result {
                        if let image = result.image {
                            self.image = Image(uiImage: image)
                            self.pets = Sticker.detectPet(sourceImage: image)
                        }
                    }
                }
            }
        }
    }
}
