//
//  StickerLabelView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import SwiftUI

struct StickerLabelView: View {
    let sticker: Sticker
    
    var body: some View {
        if let image = sticker.appplyStickerEffect() {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Text("failed to load image")
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    StickerLabelView(sticker: .preview)
}
