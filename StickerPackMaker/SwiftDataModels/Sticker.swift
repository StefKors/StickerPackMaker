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

extension UIImage {
    func crop(to rect: CGRect) -> UIImage {
        // Center crop the image
        let sourceCGImage = self.cgImage!
        let croppedCGImage = sourceCGImage.cropping(
            to: rect
        )!

        // Use the cropped cgImage to initialize a cropped
        // UIImage with the same image scale and orientation
        return UIImage(
            cgImage: croppedCGImage,
            scale: self.imageRendererFormat.scale,
            orientation: self.imageOrientation
        )
    }
}



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

    static func detectPet(sourceImage: UIImage) -> [Pet] {
        guard let image = sourceImage.cgImage else { return [] }
        let inputImage = CIImage.init(cgImage: image)
        let animalRequest = VNRecognizeAnimalsRequest()
        let requestHandler = VNImageRequestHandler.init(ciImage: inputImage, options: [:])
        try? requestHandler.perform([animalRequest])

        let identifiers = animalRequest.results?.compactMap({ result in
            if let name = result.labels.first {
                return Pet(rect: result.boundingBox, name: name.identifier, confidence: CGFloat(result.confidence))
            }
            return nil
        }).flatMap { $0 }

        return identifiers ?? []
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
