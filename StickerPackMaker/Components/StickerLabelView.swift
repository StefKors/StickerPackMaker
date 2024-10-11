//
//  StickerLabelView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import SwiftUI

struct StickerLabelView: View {
    let sticker: Sticker
    let animation: Namespace.ID

    var body: some View {
        if let image = sticker.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: sticker.id, in: animation)
        } else {
            Text("failed to load image")
                .foregroundStyle(.red)
        }
    }
}

//#Preview {
//    @Namespace var animation
//    return StickerLabelView(sticker: .preview, animation: animation)
//}
