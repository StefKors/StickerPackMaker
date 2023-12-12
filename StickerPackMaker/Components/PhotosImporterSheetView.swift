//
//  PhotosImporterSheetView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import Algorithms
import MediaCore
import MediaSwiftUI
import OSLog
import Photos
import SwiftData
import SwiftUI
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
    @State private var imageCount: Double = 0
    @State private var totalImagesCount: Double = 0

    var body: some View {
        VStack {
            if showProgressView {
                HStack {
                    Text("Stickers Found: ")
                    Text(Int(stickersFound).description)
                        .contentTransition(.numericText(value: stickersFound))
                        .monospaced()
                }

                HStack {
                    Text("Parse images: ")
                    Text("\(Int(imageCount).description)/\(Int(totalImagesCount).description)")
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

                    Task.detached(priority: .high) {
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
        .animation(.snappy, value: stickersFound)
        .animation(.snappy, value: imageCount)
    }

    func startImport() async {
        guard await PhotoLibrary.checkAuthorization() else {
            logger.error("Photo library access was not authorized.")
            return
        }

        // Set limit to 2000 so it doesn't run out of memory...
        isPresentingImporter = true
        await asyncImporter(limit: 300)
        isPresentingImporter = false
    }

    func asyncImporter(limit: Int? = nil, maxGroups: Int = 6) async {
        stickersFound = 0
        let options = PHFetchOptions()
        if let limit {
            options.fetchLimit = limit
        }

        let assets = PHAsset.fetchAssets(with: options)
        totalImagesCount = Double(assets.count)
        let chunksCount = Int(totalImagesCount)/maxGroups
        let sets = (0 ..< assets.count).chunks(ofCount: 250).map { IndexSet($0) }

//        print("number of sets \(sets.count) \(sets)")

//        let chunkSize = assets.count > 10 ? assets.count/10 : 1

//        for thing in sets[0] {
//            thing
//        }
//        let batchedSets = sets.chunks(ofCount: chunkSize)

//        print("number of batches \(batchedSets.count) of size \(batchedSets.first?.count) \(batchedSets)")
        for batch in sets {
            print("running batch")
            await withTaskGroup(of: Void.self) { taskGroup in
                let assets = assets.objects(at: batch)
                taskGroup.addTask { await runImportBatch(set: batch, assets: assets) }
//                for set in batch {
//                    print(set.description)
//                    let assets = assets.objects(at: set)
//                    taskGroup.addTask { await runImportBatch(set: set, assets: assets) }
//                }
            }
        }
    }

    func runImportBatch(set: IndexSet, assets: [PHAsset]) async {
        let photos: [Photo] = assets.map { Photo(phAsset: $0) }

        let images = await ImagePipeline.getAllHightQualityImages(of: photos)

        let stickers = images.compactMap { image in
            let sticker = ImagePipeline.parse(fetched: image)
            imageCount += 1
            if sticker != nil {
                stickersFound += 1
            }
            return sticker
        }

        bulkInsert(of: stickers)
    }

    func bulkInsert(of stickers: [Sticker]) {
        print(#function)
        let newContext = ModelContext(modelContext.container)
        newContext.autosaveEnabled = false
        for sticker in stickers {
            newContext.insert(sticker)
        }
        try? newContext.save()
    }
}

struct FetchedImage {
    let image: UIImage
    let photo: Photo?
}

#Preview {
    PhotosImporterSheetView(isPresentingImporter: .constant(true))
        .modelContainer(for: Sticker.self, inMemory: true)
}
