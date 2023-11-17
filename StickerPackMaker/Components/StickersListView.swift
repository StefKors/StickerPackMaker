//
//  StickersView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import SwiftUI
import SwiftData

struct StickersListView: View {
    @Query private var stickers: [Sticker] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(stickers) { sticker in
                    VStack {
                        NavigationLink(destination: StickerDetailView(sticker: sticker)) {
                            HStack {
                                StickerDetailView(sticker: sticker)
                                    .frame(width: 90, height: 90, alignment: .center)

                                Text(sticker.animals.debugDescription)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                        }
                    }
                }
            }
            .padding()
        }
    }
}



#Preview {
    StickersListView()
        .modelContainer(for: Sticker.self)
}
