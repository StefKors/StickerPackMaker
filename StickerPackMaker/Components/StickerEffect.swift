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
enum StickerEffect {
    // Refresh the pipeline and generate a new output.
    // TOOD: speedup this image processing
    static func isolateSubject(_ uiImage: UIImage?, subjectPosition: CGPoint? = nil) -> UIImage? {
        guard let uiImage, let data = uiImage.pngData(), let inputImage = CIImage(data: data) else {
            print("failed image")
            return nil
        }

        // Generate the input-image mask.
        guard let mask = subjectMask(fromImage: inputImage, atPoint: subjectPosition) else {
            print("failed mask")
            return nil
        }

        // Get contours from masked image
        guard let contours = contours(from: mask, orientation: uiImage.imageOrientation) else {
            print("failed to get contours")
            return nil
        }

        // Apply the visual effect and composite.
        let composited = apply(mask: mask, to: inputImage)

        // Render to UIImage
        let renderedImage = render(ciImage: composited)

        // Draw image contours
        let contouredImage = drawContours(path: contours, sourceImage: renderedImage)

        guard let contouredImageCG = contouredImage.cgImage else {
            print("failed converting image to cgImage")
            return nil
        }

        // Crop all transparent space around image
        guard let croppedImage = contouredImageCG.cropAlpha(scale: uiImage.scale, orientation: uiImage.imageOrientation) else {
            print("failed to crop image")
            return nil
        }

        return croppedImage
    }
}

func drawContours(path: CGPath, sourceImage: CGImage) -> UIImage {
    let size = CGSize(width: sourceImage.width, height: sourceImage.height)
    let renderer = UIGraphicsImageRenderer(size: size)

    let renderedImage = renderer.image { (context) in
        let renderingContext = context.cgContext
        let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
        renderingContext.concatenate(flipVertical)
        renderingContext.draw(sourceImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        renderingContext.scaleBy(x: size.width, y: size.height)
        renderingContext.setLineWidth(5.0 / CGFloat(size.width))
        renderingContext.setStrokeColor(UIColor.white.cgColor)
        renderingContext.addPath(path)
        renderingContext.strokePath()
    }

    return renderedImage
}


private func contours(from image: CIImage, orientation: UIImage.Orientation) -> CGPath? {
//    guard let sourceImage else { return nil }
    // Create a request.
    let request = VNDetectContoursRequest()

    request.detectsDarkOnLight = false

    // Create a request handler.

    let handler = VNImageRequestHandler(ciImage: image, orientation: .init(orientation))

    // Perform the request.
    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform Vision request.")
        return nil
    }

    // Acquire the instance mask observation.
    guard let result = request.results?.first else {
        print("No contour observations found.")
        return nil
    }

    print("contours \(result.contourCount)")

    return result.normalizedPath
}

/// Applies the current effect and returns the composited image.
private func apply(mask: CIImage, to inputImage: CIImage) -> CIImage {
    let filter = CIFilter.blendWithMask()
    filter.inputImage = inputImage
    filter.backgroundImage = CIImage(color: CIColor.clear).cropped(to: inputImage.extent)
    filter.maskImage = mask
    return filter.outputImage!
}

/// Returns the subject alpha mask for the given image.
///
/// - parameter image: The image to extract a foreground subject from.
/// - parameter atPoint: An optional normalized point for selecting a subject instance.
private func subjectMask(fromImage image: CIImage, atPoint point: CGPoint?) -> CIImage? {
    // Create a request.
    let request = VNGenerateForegroundInstanceMaskRequest()

    // Create a request handler.
    let handler = VNImageRequestHandler(ciImage: image)

    // Perform the request.
    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform Vision request.")
        return nil
    }

    // Acquire the instance mask observation.
    guard let result = request.results?.first else {
        print("No subject observations found.")
        return nil
    }

    let instances = instances(atPoint: point, inObservation: result)

    // Create a matted image with the subject isolated from the background.
    do {
        let mask = try result.generateScaledMaskForImage(forInstances: instances, from: handler)
        return CIImage(cvPixelBuffer: mask)
    } catch {
        print("Failed to generate subject mask.")
        return nil
    }
}

/// Returns the indices of the instances at the given point.
///
/// - parameter atPoint: A point with a top-left origin, normalized within the range [0, 1].
/// - parameter inObservation: The observation instance to extract subject indices from.
private func instances(
    atPoint maybePoint: CGPoint?,
    inObservation observation: VNInstanceMaskObservation
) -> IndexSet {
    guard let point = maybePoint else {
        return observation.allInstances
    }

    // Transform the normalized UI point to an instance map pixel coordinate.
    let instanceMap = observation.instanceMask
    let coords = VNImagePointForNormalizedPoint(
        point,
        CVPixelBufferGetWidth(instanceMap) - 1,
        CVPixelBufferGetHeight(instanceMap) - 1)

    // Look up the instance label at the computed pixel coordinate.
    CVPixelBufferLockBaseAddress(instanceMap, .readOnly)
    guard let pixels = CVPixelBufferGetBaseAddress(instanceMap) else {
        fatalError("Failed to access instance map data.")
    }
    let bytesPerRow = CVPixelBufferGetBytesPerRow(instanceMap)
    let instanceLabel = pixels.load(
        fromByteOffset: Int(coords.y) * bytesPerRow + Int(coords.x),
        as: UInt8.self)
    CVPixelBufferUnlockBaseAddress(instanceMap, .readOnly)

    // If the point lies on the background, select all instances.
    // Otherwise, restrict this to just the selected instance.
    return instanceLabel == 0 ? observation.allInstances : [Int(instanceLabel)]
}

/// Renders a CIImage onto a CGImage.
private func render(ciImage img: CIImage) -> CGImage {
    guard let cgImage = CIContext(options: nil).createCGImage(img, from: img.extent) else {
        fatalError("Failed to render CIImage.")
    }
    return cgImage
}

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
