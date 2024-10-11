//
//  ContentView.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import SwiftData
import OSLog


fileprivate let logger = Logger(subsystem: "com.stefkors.StickerPackMaker", category: "ContentView")

struct ContentView: View {
    @Query private var stickers: [Sticker]

    @State private var isPresentingImporter: Bool = false

    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack {
                    StickerSheetView(stickers: stickers)
                }
                .scenePadding()
            }
            .preferredColorScheme(.light)
                .sheet(isPresented: $isPresentingImporter) {
                    PhotosImporterSheetView(isPresentingImporter: $isPresentingImporter)
                        .presentationDetents([.fraction(0.3 )])
                }
                .toolbar {
                    ToolbarItem {
                        Button {
                            isPresentingImporter.toggle()
                        } label: {
                            Text("Import Stickers")
                        }
                    }
                }
        }
        .navigationBarTitle("\(stickers.count) Stickers", displayMode: .inline)
    }



    //    private func deleteItems(offsets: IndexSet) {
    //        withAnimation {
    //            for index in offsets {
    //                modelContext.delete(items[index])
    //            }
    //        }
    //    }
}

#Preview {
    ContentView()
        .modelContainer(for: Sticker.self, inMemory: true)
}
