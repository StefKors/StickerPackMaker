//
//  UtilityExtensions.swift
//  VisionDemo
//
//  Created by Kamil Tustanowski on 09/10/2021.
//

import Vision
import UIKit
import SwiftUI

struct DisplayableText {
    let frame: CGRect?
    let text: String
}

extension VNRectangleObservation {
    var points: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }
}

extension CVPixelBuffer {
    func makeImage() -> UIImage? {
        let ciImage = CIImage(cvImageBuffer: self)
        
        guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

extension UIImage {
    func draw(rectangles: [CGRect],
              displayableTexts: [DisplayableText],
              strokeColor: UIColor = .red,
              lineWidth: CGFloat = 2) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))

            context.cgContext.setStrokeColor(strokeColor.cgColor)
            context.cgContext.setLineWidth(lineWidth)
            rectangles.forEach { context.cgContext.addRect($0) }
            context.cgContext.drawPath(using: .stroke)

            let textAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold),
                                  NSAttributedString.Key.foregroundColor: strokeColor,
                                  NSAttributedString.Key.backgroundColor: UIColor.black]

            displayableTexts.forEach { displayableText in
                displayableText.text.draw(with: displayableText.frame!,
                                          options: [],
                                          attributes: textAttributes,
                                          context: nil)
            }
        }
    }
}

extension UIImage {

    func draw(openPaths: [[CGPoint]]? = nil,
              closedPaths: [[CGPoint]]? = nil,
              points: [CGPoint]? = nil,
              displayableTexts: [DisplayableText],
              images: [UIImage]?,
              fillColor: UIColor = .blue,
              strokeColor: UIColor = .red,
              radius: CGFloat = 5,
              lineWidth: CGFloat = 2) -> UIImage? {
        let scale: CGFloat = 0

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero)

// Uncomment to draw gray background
//        let rect = CGRect(origin: .zero, size: size)
//        UIColor.background.setFill()
//        UIRectFill(rect)
        
        let imageSize = size
        images?.forEach {
            $0.draw(in: CGRect(origin: .zero, size: imageSize), blendMode: .hue, alpha: 1.0)
        }

        points?.forEach { point in
            let path = UIBezierPath(arcCenter: point,
                                    radius: radius,
                                    startAngle: CGFloat(0),
                                    endAngle: CGFloat(Double.pi * 2),
                                    clockwise: true)
            
            fillColor.setFill()
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            
            path.fill()
            path.stroke()
        }

        openPaths?.forEach { points in
            draw(points: points, isClosed: false, color: strokeColor, lineWidth: lineWidth)
        }

        closedPaths?.forEach { points in
            draw(points: points, isClosed: true, color: strokeColor, lineWidth: lineWidth)
        }
        
        displayableTexts.forEach { displayableText in
            guard let frame = displayableText.frame else { return }
            let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .bold),
                              NSAttributedString.Key.foregroundColor: fillColor,
                              NSAttributedString.Key.backgroundColor: UIColor.black]

            displayableText.text.draw(with: frame,
                                      options: [],
                                      attributes: attributes,
                                      context: nil)
        }
                
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        return newImage
    }
    
    private func draw(points: [CGPoint], isClosed: Bool, color: UIColor, lineWidth: CGFloat) {
        let bezierPath = UIBezierPath()
        bezierPath.drawLinePath(for: points, isClosed: isClosed)
        color.setStroke()
        bezierPath.lineWidth = lineWidth
        bezierPath.stroke()
    }
}

extension UIBezierPath {
    func drawLinePath(for points: [CGPoint], isClosed: Bool) {
        points.enumerated().forEach { [unowned self] iterator in
            let index = iterator.offset
            let point = iterator.element

            let isFirst = index == 0
            let isLast = index == points.count - 1
            
            if isFirst {
                move(to: point)
            } else if isLast {
                addLine(to: point)
                move(to: point)
                
                guard isClosed, let firstItem = points.first else { return }
                addLine(to: firstItem)
            } else {
                addLine(to: point)
                move(to: point)
            }
        }
    }
}

extension UIImage {
    func resizeImage(to newSize: CGSize) -> UIImage? {
        let size = self.size
        let widthRatio  = newSize.width  / size.width
        let heightRatio = newSize.height / size.height
        let newSize = widthRatio > heightRatio ? CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
                                               : CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}

extension CGPoint {
    func translateFromCoreImageToUIKitCoordinateSpace(using height: CGFloat) -> CGPoint {
        let transform = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -height);
        
        return self.applying(transform)
    }
    
    func location(in image: UIImage) -> CGPoint {
        VNImagePointForNormalizedPoint(self,
                                       Int(image.size.width),
                                       Int(image.size.height))
    }
}

extension VNRecognizedPoint {
    func location(in image: UIImage) -> CGPoint {
        location.location(in: image)
    }
}

extension CGRect {
    func rectangle(in image: UIImage) -> CGRect {
        VNImageRectForNormalizedRect(self,
                                     Int(image.size.width),
                                     Int(image.size.height))
    }
    
    var points: [CGPoint] {
        return [origin, CGPoint(x: origin.x + width, y: origin.y),
                CGPoint(x: origin.x + width, y: origin.y + height), CGPoint(x: origin.x, y: origin.y + height)]
    }
    
    var area: CGFloat {
        height * width
    }
}

extension Color: RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else{
            self = .black
            return
        }

        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) ?? .black
            self = Color(color)
        } catch {
            self = .black
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(self), requiringSecureCoding: false) as Data
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
