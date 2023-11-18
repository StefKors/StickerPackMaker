//
//  StickerPackMakerApp.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 12/11/2023.
//

import SwiftUI
import SwiftData

//        RENAME STICKY PET MAKER!!!!
// VNDetectContoursRequest

@main
struct StickerPackMakerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Sticker.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
//            Image(.sticker)
//                .resizable()
//                .scaledToFit()
//                .modifier(ShinySticker())
//                .padding(20)
//                .clipped()
//                .clipShape(RoundedRectangle(cornerRadius: 50.0, style: .continuous))
//                .frame(width: 300, height: 300, alignment: .center)
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
