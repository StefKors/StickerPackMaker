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


/// A class that produces and publishes the postprocessed output.
final class StickerEffect {
    private var processingQueue = DispatchQueue(label: "EffectsProcessing")

    // Refresh the pipeline and generate a new output.
    static func isolateSubject(_ uiImage: UIImage?, subjectPosition: CGPoint? = nil) -> UIImage? {
        guard let data = uiImage?.pngData(), let inputImage = CIImage(data: data) else {
            print("failed image")
            return nil
        }

        // Generate the input-image mask.
        guard let mask = subjectMask(fromImage: inputImage, atPoint: subjectPosition) else {
            print("failed mask")
            return nil
        }

        // Apply the visual effect and composite.
        let composited = apply(mask: mask, to: inputImage)

        return UIImage(ciImage: composited)
    }
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
