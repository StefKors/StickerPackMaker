//
//  ContentView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import SwiftData
import OSLog
import Photos
import Vision
import MediaCore

final class Sticker: Identifiable {
    var id: String
    var image: UIImage
    var pets: [String]

    init(image: UIImage, pets: [String]) {
        self.id = UUID().uuidString
        self.image = image
        self.pets = pets
    }

    static func detectPet(sourceImage: UIImage) -> [String] {
        guard let image = sourceImage.cgImage else { return [] }
        let inputImage = CIImage.init(cgImage: image)
        let animalRequest = VNRecognizeAnimalsRequest()
        let requestHandler = VNImageRequestHandler.init(ciImage: inputImage, options: [:])
        try? requestHandler.perform([animalRequest])

        let identifiers = animalRequest.results?.compactMap({ result in
            return result.labels.compactMap({ label in
                return label.identifier
            })
        }).flatMap { $0 }

        return identifiers ?? []
    }
}



class StickerCollection: ObservableObject {
    @Published var isPhotosLoaded = false
    @Published var progress = Progress()
    @Published var stickers: [Sticker] = []

    private let imageManager = PHCachingImageManager()

    var cache: [String: UIImage?] = [:]

    private var targetSize = CGSize(width: 1024, height: 1024)
    private var imageContentMode = PHImageContentMode.aspectFit
    private lazy var requestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        return options
    }()



    func loadPhotos(limit: Int?) async -> [Sticker] {
        imageManager.allowsCachingHighQualityImages = false

        if let limit {
            progress.totalUnitCount = Int64(limit)
        }

        let fetchOptions = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
        print("collections count: \(collections.count)")
        guard let collection = collections.firstObject else {
            print("failed to load photos")
            return []
        }

        if let limit {
            progress.totalUnitCount = Int64(limit)
        } else {
            progress.totalUnitCount = Int64(collection.estimatedAssetCount)
        }

        let fetchOptionsAsset = PHFetchOptions()
        fetchOptionsAsset.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptionsAsset)

        var stickers: [Sticker] = []

        // Limit count by some number
        var lastIndex = fetchResult.count
        if let limit {
            lastIndex = min(limit, fetchResult.count)
        }

        let subsetAssets = 0..<lastIndex

        progress.totalUnitCount = Int64(subsetAssets.endIndex)

        for index in subsetAssets {
            let asset = fetchResult.object(at: index)

            for await image in self.requestImage(for: asset) {
                if let image {
                    let pets = Sticker.detectPet(sourceImage: image)
                    if !pets.isEmpty {
                        let stickerImage = StickerEffect.generate(usingInputImage: image)
                        if let stickerImage {
                            stickers.append(Sticker(image: stickerImage, pets: pets))
                        }
                    }
                }
            }
            progress.completedUnitCount += 1
        }

        return stickers
    }

    func requestImage(for asset: PHAsset) -> AsyncStream<UIImage?> {
        AsyncStream { continuation in
            let _ = imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: imageContentMode, options: requestOptions) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    logger.error("CachedImageManager requestImage error: \(error.localizedDescription)")
                    continuation.yield(nil)
                } else if let cancelled = (info?[PHImageCancelledKey] as? NSNumber)?.boolValue, cancelled {
                    logger.debug("CachedImageManager request canceled")
                    continuation.yield(nil)
                } else if let image = image {
                    continuation.yield(image)
                } else {
                    continuation.yield(nil)
                }
            }

            continuation.finish()
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var stickerCollection = StickerCollection()


    @Query private var items: [Item]


    var body: some View {
        NavigationView {
            if stickerCollection.isPhotosLoaded {
                VStack {
                    Text("Sticker Library has loaded \(stickerCollection.stickers.count.description)")
                    StickerCollectionView(stickers: stickerCollection.stickers)
                }
                .transition(.slide)
            } else {
                VStack {
                    Text("Updating Sticker Library")
                    ProgressView(stickerCollection.progress)
                        .progressViewStyle(.linear)
                }
                .transition(.slide)
            }
        }
        .animation(.snappy, value: stickerCollection.isPhotosLoaded)
        .task {
            await self.loadPhotos()
        }
    }



    func loadPhotos() async {
        guard !stickerCollection.isPhotosLoaded else { return }

        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }

        self.stickerCollection.stickers = await stickerCollection.loadPhotos(limit: nil)
        self.stickerCollection.isPhotosLoaded.toggle()
    }


    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

fileprivate let logger = Logger(subsystem: "com.stefkors.StickerPackMaker", category: "DataModel")

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
