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

        await asyncImporter()
        isPresentingImporter = false
    }

    func asyncImporter() async {
        stickersFound = 0
        let images = await getAllHightQualityImages()
        
        var stickers: [Sticker] = []

        for image in images {
            if let sticker = await parse(image: image) {
                withAnimation(.snappy) {
                    stickersFound += 1
                }
                stickers.append(sticker)
            }
        }

        bulkInsert(of: stickers)
        print("end result = \(stickers.count)")
    }

    func bulkInsert(of stickers: [Sticker]) {
        let newContext = ModelContext(modelContext.container)
        newContext.autosaveEnabled = false
        for sticker in stickers {
            newContext.insert(sticker)
        }
        try? newContext.save()
    }

    func parse(image: UIImage) async -> Sticker? {
        guard let firstPet = Sticker.detectPet(sourceImage: image).first else {
            return nil
        }
        
        let isolatedImage = StickerEffect.isolateSubject(image, subjectPosition: CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY))

        guard let imageData = isolatedImage?.pngData() else {
            return nil
        }

        return Sticker(id: UUID().uuidString, imageData: imageData, animals: [firstPet])
    }

    func getAllHightQualityImages() async -> [UIImage] {
        let size = 375
        let allPhotos = Media.Photos.all[0..<2000]
        let totalUnitCount = allPhotos.count

        var images: [UIImage] = []
        var completedUnitCount: Int = 0

        return await withCheckedContinuation { continuation in
            for photo in allPhotos {
                photo.uiImage(targetSize: CGSize(width: size, height: size), contentMode: .default) { result  in
                    if let getResult = try? result.get(), getResult.quality == .high {
                        images.append(getResult.value)
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

#Preview {
    PhotosImporterSheetView(isPresentingImporter: .constant(true))
        .modelContainer(for: Sticker.self, inMemory: true)
}
