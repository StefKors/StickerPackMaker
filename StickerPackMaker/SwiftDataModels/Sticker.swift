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
    // CloudKit integration does not support unique constraints... -.-
    @Attribute(.unique)
    var id: String = UUID().uuidString

    @Attribute(.externalStorage) var imageData: Data = Data()

    var image: UIImage? {
        UIImage(data: imageData)
    }

    var animals: [Pet] = []

    @Attribute(.transformable(by: BezierPathValueTransformer.self))
    var bezierPathContour: UIBezierPath = UIBezierPath(cgPath: .preview)

    init(id: String = UUID().uuidString, imageData: Data, animals: [Pet], contour: CGPath) {
        self.id = id
        self.imageData = imageData
        self.animals = animals
        self.bezierPathContour = UIBezierPath(cgPath: contour)
    }
}

extension Sticker {
    static let preview = Sticker(imageData: UIImage(resource: .nemo).pngData()!, animals: [.preview], contour: .preview)
}

//extension CGPath {
//    func toData() -> Data? {
//        let path = UIBezierPath(cgPath: self)
//        return try? NSKeyedArchiver.archivedData(withRootObject: path, requiringSecureCoding: true)
//    }
//}
//
//extension Data {
//    func toPath() -> CGPath? {
//        try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: self)?.cgPath
//    }
//}

@objc(BezierPathValueTransformer)
final class BezierPathValueTransformer: ValueTransformer {
    override public class func transformedValueClass() -> AnyClass {
        return UIBezierPath.self
    }

    override public class func allowsReverseTransformation() -> Bool {
        return true
    }

    override public func transformedValue(_ value: Any?) -> Any? {
        guard let path = value as? UIBezierPath else { return nil }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: path, requiringSecureCoding: true)
            return data
        } catch {
            assertionFailure("Failed to transform `UIColor` to `Data`")
            return nil
        }
    }

    override public func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? NSData else { return nil }

        do {
            let path = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: data as Data)
            return path
        } catch {
            assertionFailure("Failed to transform `Data` to `UIColor`")
            return nil
        }
    }
}

extension BezierPathValueTransformer {
    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: BezierPathValueTransformer.self))

    /// Registers the value transformer with `ValueTransformer`.
    public static func register() {
        let transformer = BezierPathValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}


enum PathCodableError: Error {
    // Throw when an invalid password is entered
    case noPathFoundInDecodedData
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

extension CGPath {
    static let preview = CGPath(rect: CGRect(origin: .zero, size: CGSize(width: 200, height: 400)), transform: nil)
}

extension Pet {
    static let preview = Pet(rect: .zero, name: "Dog", confidence: 0.8)
}
