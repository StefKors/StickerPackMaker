//
//  StickerView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import SwiftUI
import Vision

struct ContourShape: Shape {
    var path: Path

    init(path: CGPath) {
        self.path = Path(path)
    }

    func path(in rect: CGRect) -> Path {
        let absolutePath = path

        // Scaling path to fit
        // https://stackoverflow.com/a/75911341/3199999
        let boundingRect = absolutePath.boundingRect
        let scale = min(rect.width/boundingRect.width, rect.height/boundingRect.height)
        let scaled = absolutePath.applying(.init(scaleX: scale, y: scale))
        let scaledBoundingRect = scaled.boundingRect
        let offsetX = scaledBoundingRect.midX - rect.midX
        let offsetY = scaledBoundingRect.midY - rect.midY
        return scaled.offsetBy(dx: -offsetX, dy: -offsetY)
    }
}

struct StickerDetailView: View {
    let sticker: Sticker

    @State private var drawnImage: UIImage?
    @State private var path: CGPath?
    @State private var box: CGRect?

    var body: some View {
        VStack {
//            if let image = drawnImage {
//                Text("drawnImage")
//                ZStack {
//                    if let path, let box {
//                        ContourShape(path: path)
//                            .stroke(.pink, lineWidth: 4)
//                            .frame(width: 400, height: 400)
//                    }
//
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 400)
//
//
//
//                }
//            } else 

            if let image = sticker.image {
                Text("stickerImage")
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

//                    if let animal = sticker.animals.first {
//                        ContourShape(path: animal.rect)
//                            .stroke(.blue, lineWidth: 4)
//                            .fill(.red)
//                            .frame(width: 400, height: 400)
//                    }
                }
            } else {
                Text("failed to load image")
                    .foregroundStyle(.red)
            }
        }.task {
//            drawBoxes()
        }
    }

//    func drawBoxes() -> [CGRect] {
//        print("draw boxes")
//        guard let ciImage = CIImage(data: sticker.imageData), let image = sticker.image else {
//            print("failed to make ciImage")
//            return [] }
//        let animalsRequest = VNRecognizeAnimalsRequest()
//        let requestHandler = VNImageRequestHandler(ciImage: ciImage,
//                                                   orientation: .init(image.imageOrientation),
//                                                   options: [:])
//
//        do {
//            try requestHandler.perform([animalsRequest])
//        } catch {
//            print("Can't make the request due to \(error)")
//        }
//
//        guard let results = animalsRequest.results else {
//            print("failed to cast")
//            return [] }
//
//        let rectangles = results
//            .map { $0.boundingBox.rectangle(in: image) }
//
//        return rectangles
//    }
}

#Preview {
    StickerDetailView(sticker: .preview)
}
