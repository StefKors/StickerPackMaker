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
        print(absolutePath.boundingRect)
        print(rect)


//        return path

        // Scaling path to fit
        // https://stackoverflow.com/a/75911341/3199999
        let boundingRect = absolutePath.boundingRect
//        let newWidth = rect.width*boundingRect.width

        let scale = rect.width
        print(scale)
//        let otherScale = rect.width/boundingRect.width //min(rect.width/boundingRect.width, rect.height/boundingRect.height)
//        print(otherScale)
        let scaled = absolutePath.applying(.init(scaleX: rect.width, y: -rect.height))
        let scaledBoundingRect = scaled.boundingRect
        let offsetX = (scaledBoundingRect.midX - rect.midX)
        let offsetY = (scaledBoundingRect.midY - rect.midY)
        return scaled.offsetBy(dx: -offsetX, dy: -offsetY)
    }
}

struct StickerDetailView: View {
    let sticker: Sticker
    let animation: Namespace.ID

    @State private var drawnImage: UIImage?
    @State private var path: CGPath?
    @State private var box: CGRect?

    var body: some View {
        VStack {
            if let image = sticker.image {
                VStack {
                    GeometryReader { GeometryProxy in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .matchedGeometryEffect(id: sticker.id, in: animation)
                        //                        .scaledToFill()
                            .border(.red, width: 1)
                            .shinySticker()
                            .overlay(alignment: .bottom) {
                                if let path = sticker.path {
                                    ContourShape(path: path)
                                        .stroke(.blue, lineWidth: 4)
                                        .fill(.red)
                                        .aspectRatio(contentMode: .fit)
                                        .border(.blue, width: 2)
                                }
                            }
                    }
                }

            } else {
                Text("failed to load image")
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    @Namespace var animation
    return StickerDetailView(sticker: .preview, animation: animation)
}
