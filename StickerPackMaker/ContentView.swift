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
            ZStack(alignment: .bottom) {
                StickersCollectionView()
                
                NavigationLink {
                    PhotosImporterSheetView()
                } label: {
                    Text("Import Stickers")
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
            .navigationBarTitle("\(stickers.count) Stickers", displayMode: .inline)
        }
//        .sheet(isPresented: $isPresentingImporter) {
//            PhotosImporterSheetView()
//                .presentationDetents([.medium])
//                .presentationDragIndicator(.visible)
//        }
//        .task(priority: .medium) {
//            logger.debug("Starting Stickers Update")
//        }
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
