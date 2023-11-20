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
                        StickerView(sticker: sticker)
                            .matchedGeometryEffect(id: sticker.id, in: animation)
                            .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .center)
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selectedSticker = sticker
                                    isShowingDetail.toggle()
                                }
                            }
                    }
                }
                .padding([.vertical], Self.itemSpacing)
            }
            .opacity(isShowingDetail ? 0 : 1)

            if isShowingDetail, let selectedSticker {
                StickerView(sticker: selectedSticker)
                    .matchedGeometryEffect(id: selectedSticker.id, in: animation)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            isShowingDetail = false
                        }
                    }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .statusBar(hidden: false)
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
