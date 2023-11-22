//
//  StickersCollectionView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import os.log
import Photos
import SwiftData

struct StickersCollectionView: View {
    @Query private var stickers: [Sticker] = []

    @Environment(\.displayScale) private var displayScale

    private static let itemSpacing = 12.0
    private static let itemCornerRadius = 15.0
    private static let itemSize = CGSize(width: 80, height: 80)

    private var imageSize: CGSize {
        return CGSize(width: Self.itemSize.width * min(displayScale, 2), height: Self.itemSize.height * min(displayScale, 2))
    }

    private let columns = [
        GridItem(.adaptive(minimum: itemSize.width, maximum: itemSize.height), spacing: itemSpacing)
    ]

    @State private var isShowingDetail: Bool = false
    @State private var selectedSticker: Sticker?
    @Namespace var animation

    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
                    ForEach(stickers) { sticker in
                        if let image = sticker.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .overlay(alignment: .center) {
                                    if let path = sticker.path {
                                        renderPath(path: path)
                                    }
                                }
//                                .shinySticker()
                                .matchedGeometryEffect(id: sticker.id, in: animation)
                                .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .center)
                                .onTapGesture {
                                    withAnimation(.spring) {
                                        selectedSticker = sticker
                                        isShowingDetail.toggle()
                                    }
                                }
                        }
//                        StickerView(sticker: sticker)
//                            .matchedGeometryEffect(id: sticker.id, in: animation)
//                            .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .center)
//                            .onTapGesture {
//                                withAnimation(.spring) {
//                                    selectedSticker = sticker
//                                    isShowingDetail.toggle()
//                                }
//                            }
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            .opacity(isShowingDetail ? 0 : 1)

            if isShowingDetail, let selectedSticker, let image = selectedSticker.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .overlay(alignment: .center) {
                            if let path = selectedSticker.path {
                                renderPath(path: path)
                            }
                        }

//                        .shinySticker()
//                        .mask {
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFit()
//                        }
                        
                        .matchedGeometryEffect(id: selectedSticker.id, in: animation)
                        .scenePadding()
                        .onTapGesture {
                            withAnimation(.spring) {
                                isShowingDetail = false
                            }
                        }


//                StickerView(sticker: selectedSticker)
//                    .matchedGeometryEffect(id: selectedSticker.id, in: animation)
//                    .scenePadding()
//                    .onTapGesture {
//                        withAnimation(.spring) {
//                            isShowingDetail = false
//                        }
//                    }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .statusBar(hidden: false)
    }

    func renderPath(path: CGPath) -> some View {
        var canvas = Canvas { context, size in
            context.stroke(
                OutlinePathView.draw(path: path, in: CGRect(origin: .zero, size: size)),
                with: .color(.green),
                lineWidth: 4)
        }
        canvas.rendersAsynchronously = true
        return canvas
    }
}

//@State private var isShowingDetail: Bool = false
//@State private var selectedSticker: Sticker?
//
//var body: some View {
//    ZStack {
//        if isShowingDetail, let selectedSticker {
//            StickerDetailView(sticker: selectedSticker)
//        } else {
//            ScrollView {
//                LazyVGrid(columns: columns, spacing: Self.itemSpacing) {
//                    ForEach(stickers) { sticker in
//                        StickerLabelView(sticker: sticker)
//                            .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .center)
//                    }
//                }
//                .padding([.vertical], Self.itemSpacing)
//            }
//        }
//    }
//    .navigationBarTitleDisplayMode(.inline)
//    .statusBar(hidden: false)
//}

#Preview {
    StickersCollectionView()
        .modelContainer(for: Sticker.self)
}
