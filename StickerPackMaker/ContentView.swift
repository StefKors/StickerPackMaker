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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var  photoCollection = PhotoCollection(smartAlbum: .smartAlbumUserLibrary)

    @State var thumbnailImage: Image?
    @State var isPhotosLoaded = false
    @State var stickers: [Sticker] = []

    @Query private var items: [Item]


    var body: some View {
        NavigationView {
            VStack {
                Text("stickers \(stickers.count)")
                PhotoCollectionView(photoCollection: photoCollection)
            }

//            NavigationLink {
//                PhotoCollectionView(photoCollection: photoCollection)
//            } label: {
//                Label {
//                    Text("Gallery")
//                } icon: {
//                    if let thumbnailImage {
//                        ThumbnailView(image: thumbnailImage)
//                    } else {
//                        Image(systemName: "photo.on.rectangle.angled")
//                    }
//                }
//            }
        }
        .task {
            await self.loadPhotos()
        }
    }



    func loadPhotos() async {
        guard !isPhotosLoaded else { return }

        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }

        Task {
            do {
                try await self.photoCollection.load()
//                await self.loadThumbnail()
//                print("starting fetching stickers \(photoCollection.photoAssets.endIndex.description)")
//                self.stickers = await run(collection: photoCollection.photoAssets, cache: photoCollection.cache)
//                print("finished fetching stickers")
            } catch let error {
                logger.error("Failed to load photo collection: \(error.localizedDescription)")
            }
            self.isPhotosLoaded = true
        }
    }


    func run(collection: PhotoAssetCollection, cache: CachedImageManager) async -> [Sticker] {
        var assets: [PHAsset] = []
        var stickers: [Sticker] = []

        collection.fetchResult.enumerateObjects { (object, count, stop) in
            assets.append(object)
        }

        for (index, asset) in assets.enumerated() {
            print("fetching: \(index.description)/\(collection.endIndex.description)")
            for await image in await cache.requestImage(for: asset) {
                if let image {
                    let pets = Sticker.detectPet(sourceImage: image)
                    if !pets.isEmpty {
                        stickers.append(Sticker(asset: asset, image: image, pets: pets))
                    }
                }
            }
        }

        return stickers
    }

    func loadThumbnail() async {
        guard let asset = photoCollection.photoAssets.first  else { return }
        await photoCollection.cache.requestImage(for: asset, targetSize: CGSize(width: 256, height: 256))  { result in
            if let result = result {
                Task { @MainActor in
                    self.thumbnailImage = result.image
                }
            }
        }
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
