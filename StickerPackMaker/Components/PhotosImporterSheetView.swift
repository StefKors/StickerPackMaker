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

fileprivate let logger = Logger(subsystem: "com.stefkors.StickerPackMaker", category: "PhotosImporterSheetView")

struct PhotosImporterSheetView: View {
    @Environment(\.modelContext) private var modelContext

    @FetchAssets(sort: [Media.Sort(key: .creationDate, ascending: false)], fetchLimit: 600)
    private var photos: [Photo]

    @State private var progress: Progress = Progress()
    @State private var showProgressView: Bool = false

    var body: some View {
        VStack {
            if showProgressView {
                ProgressView()
                    .progressViewStyle(.linear)
                    .transition(.slide.animation(.bouncy))
                    .scenePadding()
            } else {
                VStack {
                    Text("Search PhotoLibrary for Pet Stickers")
                    Text("Photos: ") + Text(photos.count.description).monospaced()
                }
                .transition(.slide.animation(.bouncy))
            }

            HStack {
                Button {
                    // action
                    showProgressView.toggle()
                    Task {
                        await runImporter(photos: photos)
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

    func runImporter(photos: [Photo], limit: Int? = nil) async {
        let authorized = await PhotoLibrary.checkAuthorization()
        guard authorized else {
            logger.error("Photo library access was not authorized.")
            return
        }

        let newContext = ModelContext(modelContext.container)
        newContext.autosaveEnabled = false


        let size = 1024

        var photoSetSize = photos.count
        if let limit {
            photoSetSize = min(limit, photoSetSize)
        }

        let smallPhotoSet = photos[0..<photoSetSize]

        self.progress.totalUnitCount = Int64(smallPhotoSet.count)

        for photo in smallPhotoSet {
            photo.uiImage(targetSize: CGSize(width: size, height: size), contentMode: .default) { result in
                if let getResult = try? result.get() {

                    if getResult.quality == .high {
                        let image = getResult.value

                        //                    print("fetched image")
                        let pets = Sticker.detectPet(sourceImage: image)
                        if !pets.isEmpty {
                            if let firstPet = pets.first {
                                //                            let stickerImage = StickerEffect.generate(usingInputImage: image)
                                //                        print("found pets")

                                //                            let croppedImage = image.crop(to: firstPet.rect)
                                let isolatedImage = StickerEffect.generate(usingInputImage: image, subjectPosition: CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY))

                                if let imageData = isolatedImage?.pngData() {
                                    //                            print("created imageData")
                                    if let id = photo.identifier?.localIdentifier {

                                        print("image.. \(id)")
                                        let sticker = Sticker(id: id, imageData: imageData, animals: pets)
                                        modelContext.insert(sticker)
                                        newContext.insert(sticker)
                                    }
                                }
                            }
                        }

                        self.progress.completedUnitCount += 1
                    }
                }

            }
        }

        //        try? newContext.save()
        //        self.progress = nil
        //        print("!!! finished updating stickers !!!")
    }
}

#Preview {
    PhotosImporterSheetView()
        .modelContainer(for: Sticker.self, inMemory: true)
}
