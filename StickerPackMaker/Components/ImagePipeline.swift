//
//  ImagePipeline.swift
//  StickerPackMaker
//
//  Created by Stef Kors on 22/11/2023.
//

import Algorithms
import MediaCore
import MediaSwiftUI
import OSLog
import Photos
import SwiftData
import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

struct StickerViewRenderer: View {
    let image: UIImage
    let path: CGPath

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .background(alignment: .center) {
                ContourShape(path: path)
                    .stroke(.white, lineWidth: 3)
            }
    }
}

import CoreImage
import UIKit
import AVFoundation

public extension UIImage {
    /// Resize image while keeping the aspect ratio. Original image is not modified.
    /// - Parameters:
    ///   - width: A new width in pixels.
    ///   - height: A new height in pixels.
    /// - Returns: Resized image.
    func resize(_ width: Int, _ height: Int) -> UIImage {
        // Keep aspect ratio
        let maxSize = CGSize(width: width, height: height)

        let availableRect = AVFoundation.AVMakeRect(
            aspectRatio: self.size,
            insideRect: .init(origin: .zero, size: maxSize)
        )
        let targetSize = availableRect.size

        // Set scale of renderer so that 1pt == 1px
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        // Resize the image
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resized
    }
}

extension CGImage {
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel


        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}


extension CGRect {
    func scaleToFit(rect: CGRect) -> CGRect {
        let sourceWidth = self.width
        let sourceHeight = self.height
        let destWidth = rect.width
        let destHeight = rect.height

        var outputWidth: CGFloat = 0
        var outputHeight: CGFloat = 0
        var outputX: CGFloat = 0
        var outputY: CGFloat = 0

        if (sourceWidth == 0 && sourceHeight == 0) {
            // scale = Infinity;
            outputWidth = 0;
            outputHeight = 0;
            outputX = destWidth / 2;
            outputY = destHeight / 2;
        } else if (destWidth * sourceHeight > destHeight * sourceWidth) {
            //            scale = destHeight / sourceHeight;
            outputWidth = sourceWidth * destHeight / sourceHeight;
            outputHeight = destHeight;
            outputX = (destWidth - outputWidth) / 2;
            outputY = 0;
        } else {
            //            scale = destWidth / sourceWidth;
            outputWidth = destWidth;
            outputHeight = sourceHeight * destWidth / sourceWidth;
            outputX = 0;
            outputY = (destHeight - outputHeight) / 2;
        }

        return CGRect(x: outputX, y: outputY, width: outputWidth, height: outputHeight)
    }
}

enum ImagePipeline {
    static func parse(fetched: FetchedImage) -> Sticker? {
        let pets = detectPet(sourceImage: fetched.image)

        guard let firstPet = pets.first else {
            return nil
        }

        let subjectPosition = CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY)

        guard let data = fetched.image.pngData(), let inputImage = CIImage(data: data) else {
            print("failed image")
            return nil
        }

        // Generate the input-image mask.
        guard let mask = subjectMask(fromImage: inputImage, atPoint: subjectPosition) else {
            print("failed mask")
            return nil
        }

        // Get contours from masked image
        guard let contours = contours(from: mask, orientation: fetched.image.imageOrientation) else {
            print("failed to get contours")
            return nil
        }



        let fullRect = CGRect(origin: .zero, size: fetched.image.size).scaleToFit(rect: CGRect(origin: .zero, size: CGSize(width: 1200, height: 1200)))

        // Apply the visual effect and composite.
        guard let composited = render(ciImage: apply(mask: mask, to: inputImage)).resize(size: fullRect.size) else {
            return nil
        }

        let size = CGSize(
            width: contours.boundingBox.width * fullRect.size.width,
            height: contours.boundingBox.height * fullRect.size.height
        )

        let origin = CGPoint(
            x: contours.boundingBox.minX * fullRect.size.width,
            y: (1 - contours.boundingBox.maxY) * fullRect.size.height
        )

        let scaledBox = CGRect(origin: origin, size: size)

        var imageData: Data? = nil

        let addContourToImage = false
        if addContourToImage {
            let imageWithContours = drawContoursWithMask(path: contours, sourceImage: composited, croppedTo: scaledBox)
            imageData = imageWithContours.pngData()
        } else {
            guard let cropped = composited.cropping(to: scaledBox) else {
                return nil
            }
            imageData = write(cgimage: cropped)
        }


        guard let imageData else {
            return nil
        }

        return Sticker(
            id: fetched.photo?.identifier?.localIdentifier ?? UUID().uuidString,
            imageData: imageData,
            animals: pets,
            contour: contours
        )
    }

    // TODO Merge with drawContoursWithMask
    static func imageWithImage(image: UIImage, croppedTo rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()

        let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y,
                              width: image.size.width, height: image.size.height)

        context?.clip(to: CGRect(x: 0, y: 0,
                                 width: rect.size.width, height: rect.size.height))

        image.draw(in: drawRect)

        let subImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        return subImage!
    }

    static func imageWithImage2(image: UIImage, croppedTo rect: CGRect) -> UIImage {
        let renderedImage = UIGraphicsImageRenderer(size: rect.size).image { (context) in
            let drawRect = CGRect(x: Int(-rect.origin.x), y: Int(-rect.origin.y), width: Int(image.size.width), height: Int(image.size.height))
            context.clip(to: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
            image.draw(in: drawRect)
        }

        return renderedImage
    }

    static func drawContoursWithMask(path: CGPath, sourceImage: CGImage, croppedTo: CGRect) -> UIImage {
        let size = CGSize(width: sourceImage.width, height: sourceImage.height)
        let lineWidth =  0.02
        let renderer = UIGraphicsImageRenderer(size: size)
        let renderedImage = renderer.image { (context) in
            let renderingContext = context.cgContext
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
            renderingContext.concatenate(flipVertical)

            renderingContext.scaleBy(x: size.width, y: size.height)
            renderingContext.setLineWidth(lineWidth)
            renderingContext.setStrokeColor(UIColor.white.cgColor)
            renderingContext.addPath(path)
            renderingContext.drawPath(using: .stroke)
            renderingContext.saveGState()

            renderingContext.draw(sourceImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            renderingContext.saveGState()
        }

        return imageWithImage(image: renderedImage, croppedTo: croppedTo.insetBy(dx: -(40), dy: -(40)))
    }

    


    static func getPhotos(limit: Int? = nil) async -> [Photo] {
        var allPhotos: [Photo] = []
        let options = PHFetchOptions()
        if let limit {
            options.fetchLimit = limit
        }
        let assets = PHAsset.fetchAssets(with: options)

        assets.enumerateObjects { asset, _, _ in
            allPhotos.append(Photo(phAsset: asset))
        }

        return allPhotos
    }

    static func getAllHightQualityImages(of allPhotos: [Photo]) async -> [FetchedImage] {
        let size = 1200*2
        let totalUnitCount = allPhotos.count
        var images: [FetchedImage] = []
        var completedUnitCount: Int = 0

        return await withCheckedContinuation { continuation in
            for photo in allPhotos {
                photo.uiImage(targetSize: CGSize(width: size, height: size), contentMode: .default) { result  in
                    if let getResult = try? result.get(), getResult.quality == .high {
                        images.append(FetchedImage(image: getResult.value, photo: photo))
                        completedUnitCount += 1
                        if completedUnitCount == totalUnitCount {
                            continuation.resume(returning: images)
                        }
                    }
                }
            }
        }
    }

    static func write(cgimage: CGImage) -> Data? {
        let cicontext = CIContext()
        let ciimage = CIImage(cgImage: cgimage)
        return cicontext.pngRepresentation(of: ciimage, format: .RGBA8, colorSpace: ciimage.colorSpace!)
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

    static func drawContours(path: CGPath, sourceImage: CGImage) -> UIImage {
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


    private static func contours(from image: CIImage, orientation: UIImage.Orientation) -> CGPath? {
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

        return result.normalizedPath
    }

    /// Applies the current effect and returns the composited image.
    private static func apply(mask: CIImage, to inputImage: CIImage) -> CIImage {
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
    private static func subjectMask(fromImage image: CIImage, atPoint point: CGPoint?) -> CIImage? {
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
    private static func instances(
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
    private static func render(ciImage img: CIImage) -> CGImage {
        guard let cgImage = CIContext(options: nil).createCGImage(img, from: img.extent) else {
            fatalError("Failed to render CIImage.")
        }
        return cgImage
    }

}
