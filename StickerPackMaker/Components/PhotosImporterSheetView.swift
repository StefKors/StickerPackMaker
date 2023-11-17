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

fileprivate let logger = Logger(subsystem: "com.stefkors.StickerPackMaker", category: "PhotosImporterSheetView")

extension Photo: @unchecked Sendable {}

struct PhotosImporterSheetView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var progress: Progress = Progress()
    @State private var showProgressView: Bool = false

    var body: some View {
        VStack {
            if showProgressView {
                ProgressView(progress)
                    .progressViewStyle(.linear)
                    .transition(.slide.animation(.bouncy))
                    .scenePadding()
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
                    Text("Start")
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
                    Text("Remove All Stickers")
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
        }
    }

    func startImport() async {
        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }

        runImporter(limit: 700)
    }

    func runImporter(limit: Int? = nil) {
        let options = PHFetchOptions()
        if let limit {
            options.fetchLimit = limit
        }
        let assets = PHAsset.fetchAssets(with: options)

        let newContext = ModelContext(modelContext.container)
        newContext.autosaveEnabled = false


        let size = 1024

        self.progress.totalUnitCount = Int64(assets.count)

        assets.enumerateObjects { asset, _, _ in
            let photo = Photo.init(phAsset: asset)
            photo.uiImage(targetSize: CGSize(width: size, height: size), contentMode: .default) { result  in
                if let getResult = try? result.get() {
                    if getResult.quality == .high {
                        let image = getResult.value
                        let pets = Sticker.detectPet(sourceImage: image)
                        if !pets.isEmpty {
                            if let firstPet = pets.first {
                                let isolatedImage = StickerEffect.isolateSubject(image, subjectPosition: CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY))

                                if let imageData = isolatedImage?.pngData() {
                                    if let id = photo.identifier?.localIdentifier {

                                        print("image.. \(id)")
                                        let sticker = Sticker(id: id, imageData: imageData, animals: pets)
                                        //                                            modelContext.insert(sticker)
                                        newContext.insert(sticker)

                                    }
                                }
                            }
                        }
                        self.progress.completedUnitCount += 1
                        if self.progress.completedUnitCount == Int64(assets.count) {
                            try? newContext.save()
                            print("finished?")
                        }
                    }
                }
            }
        }
    }

//    func runImporter( limit: Int? = nil) {
//        let options = PHFetchOptions()
//        options.fetchLimit = 600
//        let result = PHAsset.fetchAssets(with: options)
//
//        var photos: [Photo] = []
//        result.enumerateObjects { asset, _, _ in
//            let item = Photo.init(phAsset: asset)
//            photos.append(item)
//        }
//
//        let newContext = ModelContext(modelContext.container)
//        newContext.autosaveEnabled = false
//
//
//        let size = 1024
//
//        var photoSetSize = photos.count
//        if let limit {
//            photoSetSize = min(limit, photoSetSize)
//        }
//
//        let smallPhotoSet = photos[0..<photoSetSize]
//
//        self.progress.totalUnitCount = Int64(smallPhotoSet.count)
//
//        for photo in smallPhotoSet {
//            photo.uiImage(targetSize: CGSize(width: size, height: size), contentMode: .default) { result  in
//                if let getResult = try? result.get() {
//                    if getResult.quality == .high {
//                        let image = getResult.value
//                        let pets = Sticker.detectPet(sourceImage: image)
//                        if !pets.isEmpty {
//                            if let firstPet = pets.first {
//                                let isolatedImage = StickerEffect.isolateSubject(image, subjectPosition: CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY))
//
//                                if let imageData = isolatedImage?.pngData() {
//                                    if let id = photo.identifier?.localIdentifier {
//
//                                        print("image.. \(id)")
//                                        let sticker = Sticker(id: id, imageData: imageData, animals: pets)
//                                        //                                            modelContext.insert(sticker)
//                                        newContext.insert(sticker)
//
//                                    }
//                                }
//                            }
//                        }
//                        self.progress.completedUnitCount += 1
//                        if self.progress.completedUnitCount == Int64(smallPhotoSet.count) {
//                            try? newContext.save()
//                            print("finished?")
//                        }
//                    }
//                }
//            }
//        }
//    }
}

#Preview {
    PhotosImporterSheetView()
        .modelContainer(for: Sticker.self, inMemory: true)
}
