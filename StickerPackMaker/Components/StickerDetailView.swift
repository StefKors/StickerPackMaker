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

    /// based on: https://stackoverflow.com/a/75911341/3199999
    /// but with indipendent x & y scaling
    func path(in rect: CGRect) -> Path {
        let boundingRect = path.boundingRect
        let scaleX = rect.width/boundingRect.width
        let scaleY = rect.height/boundingRect.height
        let scaled = path.applying(.init(scaleX: scaleX, y: -scaleY))
        let scaledBoundingRect = scaled.boundingRect
        let offsetX = scaledBoundingRect.midX - rect.midX
        let offsetY = scaledBoundingRect.midY - rect.midY
        return scaled.offsetBy(dx: -offsetX, dy: -offsetY)
    }
}

struct StickerView: View {
    let sticker: Sticker

    var body: some View {
        VStack {
            if let image = sticker.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(alignment: .center) {
                        if let path = sticker.path {
                            ContourShape(path: path)
                                .fill(.white)
                                .stroke(.white, lineWidth: 4)
                                .shadow(radius: 12)
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
    return StickerView(sticker: .preview)
}
