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

final class Sticker: Identifiable {
    var id: String
    var asset: PHAsset
    var image: UIImage
    var pets: [String]

    init(asset: PHAsset, image: UIImage, pets: [String]) {
        self.id = UUID().uuidString
        self.asset = asset
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

    let cache = CachedImageManager()


    func loadPhotos() async -> [Sticker] {
        let fetchOptions = PHFetchOptions()
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)
        guard let collection = collections.firstObject else {
            print("failed to load photos")
            return []
        }

        let fetchOptionsAsset = PHFetchOptions()
        fetchOptionsAsset.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptionsAsset)
        let photoCollection = PhotoAssetCollection(fetchResult)

        var assets: [PHAsset] = []
        var stickers: [Sticker] = []

        photoCollection.fetchResult.enumerateObjects { (object, count, stop) in
            assets.append(object)
        }

        let subsetAssets =  assets // Array(assets[0..<100])

        progress.totalUnitCount = Int64(subsetAssets.endIndex)

        for asset in subsetAssets {
            for await image in await cache.requestImage(for: asset) {
                if let image {
                    let pets = Sticker.detectPet(sourceImage: image)
                    if !pets.isEmpty {
                        let stickerImage = StickerEffect.generate(usingInputImage: image)
                        if let stickerImage {
                            stickers.append(Sticker(asset: asset, image: stickerImage, pets: pets))
                        }
                    }
                }
            }
            progress.completedUnitCount += 1
        }

        return stickers
    }

}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    //    @StateObject private var photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)
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


        self.stickerCollection.stickers = await stickerCollection.loadPhotos()
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
