//
//  PhotoCollection.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import os.log
import Photos

struct StickerCollectionView: View {
    var stickers: [Sticker]

    @Environment(\.displayScale) private var displayScale

    private static let itemSpacing = 12.0
    private static let itemCornerRadius = 15.0
    private static let itemSize = CGSize(width: 90, height: 90)

    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
    }

    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                ForEach(stickers) { sticker in
                    StickerView(sticker: sticker)
                }
            }
            .padding([.vertical], Self.itemSpacing)
        }
        .navigationBarTitleDisplayMode(.inline)
        .statusBar(hidden: false)
    }
}

struct StickerView: View {
    let sticker: Sticker
    var body: some View {
        Image(uiImage: sticker.image)
            .resizable()
            .scaledToFill()
    }
}

