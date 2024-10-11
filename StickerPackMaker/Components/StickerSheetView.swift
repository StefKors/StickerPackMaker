//
//  StickerSheetView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 13/12/2023.
//

import SwiftUI
import Algorithms

struct StickerSheetView: View {
    private var sheet: StickerSheet {
        StickerSheet(stickers: [], label: "Puppy Pals", theme: .SheetThemes.themeChristmas2023)
    }
    
    var stickers: [Sticker]
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text(sheet.label)
                        .font(Font.custom("Modak", size: 55, relativeTo: .largeTitle))
                    
                    //                    .font(Font.custom("Modak", size: 55))
                }
                
                
                MasonryVStack(columns: 3, spacing: 20) {
                    ForEach(stickers) { sticker in
                        StickerView(sticker: sticker)
                    }
                }
            }
            .padding()
            .foregroundStyle(Color(uiColor: UIColor.SheetThemes.oker))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(uiColor: sheet.theme))
                    .strokeBorder(Color(uiColor: sheet.theme), lineWidth: 1)
            )
            
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.background)
                    .shadow(color: Color(uiColor: sheet.theme), radius: 10, x: 0, y: 0)
            )
        }
    }
}

#Preview {
    StickerSheetView(stickers: [.preview])
        .safeAreaPadding()
}
