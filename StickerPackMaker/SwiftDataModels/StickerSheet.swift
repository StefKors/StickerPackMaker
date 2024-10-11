//
//  StickerSheet.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 13/12/2023.
//

import Foundation
import SwiftData
import SwiftUI

//enum StickerSheetTheme: Codable, Color {
//    case christmas2023 = Color(.red)
//    case pastelGreen
//    case pastelRed
//    case pastelBlue
//    case pastelOrange
//    case pastelPurple
//    case pastelYellow
//}


@Model
final class StickerSheet: Identifiable, Sendable {
    // CloudKit integration does not support unique constraints... -.-
    @Attribute(.unique)
    var id: String = UUID().uuidString

    var createdAt: Date = Date.now

//    @Relationship(deleteRule: .noAction, inverse: \Sticker.sheet)
    var stickers: [Sticker] = []

    var label: String = ""
    var byline: String? = nil

    @Attribute(.transformable(by: ColorValueTransformer.self))
    var theme: UIColor = UIColor.SheetThemes.themeChristmas2023


    init(stickers: [Sticker], label: String, byline: String? = nil, theme: UIColor) {
        self.id = id
        self.createdAt = createdAt
        self.stickers = stickers
        self.label = label
        self.byline = byline
        self.theme = theme
    }
}

extension StickerSheet {
    static let preview = StickerSheet(stickers: [], label: "Puppy Pals", theme: UIColor.SheetThemes.themeChristmas2023)
}

@objc(ColorValueTransformer)
final class ColorValueTransformer: ValueTransformer {
    override public class func transformedValueClass() -> AnyClass {
        return UIColor.self
    }

    override public class func allowsReverseTransformation() -> Bool {
        return true
    }

    override public func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        return try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
    }

    override public func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let colorData = value as? NSData else { return UIColor.black }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData as Data) ?? UIColor.black
    }
}

extension ColorValueTransformer {
    /// The name of the transformer. This is the name used to register the transformer using `ValueTransformer.setValueTrandformer(_"forName:)`.
    static let name = NSValueTransformerName(rawValue: String(describing: ColorValueTransformer.self))

    /// Registers the value transformer with `ValueTransformer`.
    public static func register() {
        let transformer = ColorValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
