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

enum ImagePipeline {
    static func parse(fetched: FetchedImage) async -> Sticker? {
        let pets = detectPet(sourceImage: fetched.image)

        guard let firstPet = pets.first else {
            return nil
        }

        let isolatedImage = isolateSubject(fetched.image, subjectPosition: CGPoint(x: firstPet.rect.midX, y: firstPet.rect.midY))

        guard let imageData = isolatedImage?.pngData() else {
            return nil
        }

        return Sticker(
            id: fetched.photo.identifier?.localIdentifier ?? UUID().uuidString,
            imageData: imageData,
            animals: pets
        )
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
        let size = 375*2
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
        let composited = apply(mask: mask, to: inputImage) //.cropped(to: scaledBox)

        let scaledBox = contours.boundingBox.insetBy(dx: -inputImage.extent.width, dy: -inputImage.extent.height)
        // Render to UIImage
        guard let renderedImage = render(ciImage: composited).cropping(to: scaledBox) else {
            return nil
        }

        return UIImage(cgImage: renderedImage)
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

        print("contours \(result.contourCount)")

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
