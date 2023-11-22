/*
 See the LICENSE.txt file for this sample’s licensing information.

 Abstract:
 Handles subject lifting, visual effects application, and compositing.
 */

import Foundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Presets for the subjects' visual effects.
enum Effect: String, Equatable, CaseIterable {
    case none = "None"
    case highlight = "Highlight"
    case bokeh = "Bokeh Halo"
    case noir = "Noir"
}

/// Presets for the background's visual effects.
enum Background: String, Equatable, CaseIterable {
    case original = "Original"
    case transparent = "Transparent"
    //    case sunset = "Sunset"
    case greenScreen = "Green Screen"
}


/// A namespace producing and publishing the postprocessed output.

extension CGImage {

    func cropAlpha(scale: CGFloat, orientation: UIImage.Orientation) -> UIImage? {

        let width = self.width
        let height = self.height

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel:Int = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
              let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return nil
        }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minX = width
        var minY = height
        var maxX: Int = 0
        var maxY: Int = 0

        for x in 1 ..< width {
            for y in 1 ..< height {

                let i = bytesPerRow * y + bytesPerPixel * x
                let a = CGFloat(ptr[i + 3]) / 255.0

                if(a>0) {
                    if (x < minX) { minX = x };
                    if (x > maxX) { maxX = x };
                    if (y < minY) { minY = y};
                    if (y > maxY) { maxY = y};
                }
            }
        }

        let rect = CGRect(x: CGFloat(minX),y: CGFloat(minY), width: CGFloat(maxX-minX), height: CGFloat(maxY-minY))
        let croppedImage =  self.cropping(to: rect)!
        let ret = UIImage(cgImage: croppedImage, scale: scale, orientation: orientation)

        return ret;
    }

}
