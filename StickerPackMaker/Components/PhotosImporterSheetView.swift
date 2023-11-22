//
//  PhotosImporterSheetView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import SwiftUI
import MediaCore
import MediaSwiftUI
import OSLog
import SwiftData
import Photos

import Vision

fileprivate let logger = Logger(subsystem: "com.stefkors.StickerPackMaker", category: "PhotosImporterSheetView")

extension Photo: @unchecked Sendable {}

enum ImportError: Error {
    case Err
}

struct PhotosImporterSheetView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var isPresentingImporter: Bool

    @State private var progress: Progress = Progress()
    @State private var showProgressView: Bool = false
    @State private var stickersFound: Double = 0

    var body: some View {
        VStack {
            if showProgressView {
                HStack {
                    Text("Stickers Found: ")
                    Text(Int(stickersFound).description)
                        .contentTransition(.numericText(value: stickersFound))
                        .monospaced()
                }
            } else {
                VStack {
                    Text("Search PhotoLibrary for Pet Stickers")
                }
                .transition(.slide.animation(.bouncy))
            }

            HStack {
                Button {
                    // action
                    showProgressView = true

                    Task.detached {
                        await startImport()
                    }
                } label: {
                    Text("Search Photos for Stickers")
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)

                Button(role: .destructive) {
                    do {
                        try modelContext.delete(model: Sticker.self)
                    } catch {
                        print("Failed to clear all Sticker data.")
                    }
                } label: {
                    Label("Remove All Stickers", systemImage: "trash")
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
                .labelStyle(.iconOnly)
            }
        }
    }

    func startImport() async {
        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }

        // Set limit to 2000 so it doesn't run out of memory...
        await asyncImporter(limit: 2000)
        isPresentingImporter = false
    }

    func asyncImporter(limit: Int? = nil) async {
        stickersFound = 0
        let options = PHFetchOptions()
        if let limit {
            options.fetchLimit = limit
        }
        let assets = PHAsset.fetchAssets(with: options)
        let sets = assets.count.chunk(of: 30)
        print("number of sets \(sets.count)")

        for set in sets {
            await runImportBatch(set: set, assets: assets)
        }

        print("end result = \(stickersFound)")
    }

    func runImportBatch(set: IndexSet, assets: PHFetchResult<PHAsset>) async {
        var photos: [Photo] = []
        let _ = assets.enumerateObjects(at: set) { asset, _, _ in
            photos.append(Photo(phAsset: asset))
        }

        let images = await getAllHightQualityImages(of: photos)

        var stickers: [Sticker] = []
        for image in images {
            if let sticker = await parse(fetched: image) {
                withAnimation(.snappy) {
                    stickersFound += 1
                }
                stickers.append(sticker)
            }
        }

        bulkInsert(of: stickers)
    }

    func bulkInsert(of stickers: [Sticker]) {
        let newContext = ModelContext(modelContext.container)
        newContext.autosaveEnabled = false
        for sticker in stickers {
            newContext.insert(sticker)
        }
        try? newContext.save()
    }

    func parse(fetched: FetchedImage) async -> Sticker? {
        let pets = Sticker.detectPet(sourceImage: fetched.image)

        guard let firstPet = pets.first else {
            return nil
        }
        
        let isolatedImage = StickerEffect.isolateSubject(fetched.image, subjectPosition: CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY))

        guard let imageData = isolatedImage?.pngData() else {
            return nil
        }

        return Sticker(
            id: fetched.photo.identifier?.localIdentifier ?? UUID().uuidString,
            imageData: imageData,
            animals: pets
        )
    }

    func getPhotos(limit: Int? = nil) async -> [Photo] {
        var allPhotos: [Photo] = []
        let options = PHFetchOptions()
        if let limit {
            options.fetchLimit = limit
        }
        let assets = PHAsset.fetchAssets(with: options)

        assets.enumerateObjects { asset, _, _ in
            allPhotos.append(Photo(phAsset: asset))
        }

        return allPhotos
    }

    func getAllHightQualityImages(of allPhotos: [Photo]) async -> [FetchedImage] {
        let size = 375*2
        let totalUnitCount = allPhotos.count
        var images: [FetchedImage] = []
        var completedUnitCount: Int = 0

        return await withCheckedContinuation { continuation in
            for photo in allPhotos {
                photo.uiImage(targetSize: CGSize(width: size, height: size), contentMode: .default) { result  in
                    if let getResult = try? result.get(), getResult.quality == .high {
                        images.append(FetchedImage(image: getResult.value, photo: photo))
                        completedUnitCount += 1
                        if completedUnitCount == totalUnitCount {
                            continuation.resume(returning: images)
                        }
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

extension Int {
    func chunk(of size: Int = 200) -> [IndexSet] {
        // Iterate over array, chunk it and convert to indexset
        return Array(0...self).chunked(by: size).compactMap { chunk -> IndexSet? in
            guard let first = chunk.first, let last = chunk.last else { return nil }
//            print("first: \(first.description), last: \(last.description)")
            return IndexSet(first..<last)
        }
    }
}

struct FetchedImage {
    let image: UIImage
    let photo: Photo
}

#Preview {
    PhotosImporterSheetView(isPresentingImporter: .constant(true))
        .modelContainer(for: Sticker.self, inMemory: true)
}
