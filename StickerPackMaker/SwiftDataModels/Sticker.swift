//
//  Sticker.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 17/11/2023.
//

import Foundation
import SwiftData
import Vision
import UIKit
import CoreGraphics

@Model
final class Sticker: Identifiable, Sendable {
//    @Attribute(.unique) 
    var id: String = UUID().uuidString

    @Attribute(.externalStorage) var imageData: Data = Data()

    var image: UIImage? {
        UIImage(data: imageData)
    }

    var animals: [Pet] = []

//    @Attribute(.externalStorage)
    var pathData: Data?

    init(id: String = UUID().uuidString, imageData: Data, animals: [Pet]) {
        self.id = id
        self.imageData = imageData
        self.animals = animals
    }
}

extension Sticker {
    static let preview = Sticker(imageData: UIImage(resource: .nemo).pngData()!, animals: [.preview])
}

struct Pet: Codable {
    var rect: CGRect
    var name: String
    // [0 - 1]
    var confidence: CGFloat

    init(rect: CGRect, name: String, confidence: CGFloat) {
        self.rect = rect
        self.name = name
        self.confidence = confidence
    }
}

extension CGRect: Hashable {
    public var hashValue: Int {
        return NSCoder.string(for: self).hashValue
    }
}


extension Pet {
    static let preview = Pet(rect: .zero, name: "Dog", confidence: 0.8)
}
