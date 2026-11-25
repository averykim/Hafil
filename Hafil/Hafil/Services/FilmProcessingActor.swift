//
//  FilmProcessingActor.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation
import CoreImage

actor FilmProcessingActor: FilmProcessingEngineInterface {
    
    private let context = CIContext(options: [.useSoftwareRenderer: false])

    func stitchAndApplyRecipe(frameA: FrameData, frameB: FrameData, recipeName: String) async -> Result<URL, any Error> {
        return await withCheckedContinuation({ continuation in
            autoreleasepool {
                do {
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let urlA = tempDirectory.appendingPathComponent("\(frameA.rawPixelBufferId).jpg")
                    let urlB = tempDirectory.appendingPathComponent("\(frameB.rawPixelBufferId).jpg")

                    guard let imageA = CIImage(contentsOf: urlA),
                          let imageB = CIImage(contentsOf: urlB) else {
                        throw NSError(domain: "ProcessingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Can't find original image"])
                    }

                    // 2. Diptych Stitching
                    let width = imageA.extent.width
                    // move image B to right as much as image A's width
                    let transform = CGAffineTransform(translationX: width, y: 0)
                    let shiftedimageB = imageB.transformed(by: transform)

                    // combine image A and B on the image A
                    var stitchedImage = shiftedimageB.composited(over: imageA)

                    // 3. Apply film recipe
                    stitchedImage = applyRecipe(to:stitchedImage, recipeName:recipeName)

                    // 4. Transform CIImage to JPEG
                    let outputURL = tempDirectory.appendingPathComponent("Diptych_\(UUID().uuidString).jpg")

                    guard let colorSpace = stitchedImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
                        throw NSError(domain: "Processing Error", code: 2, userInfo: [NSLocalizedDescriptionKey: "Color Space Error"])
                    }

                    try self.context.writeJPEGRepresentation(of: stitchedImage,
                                                             to: outputURL,
                                                             colorSpace: colorSpace,
                                                             options: [CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String): 0.95])

                    continuation.resume(returning: .success(outputURL))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        })
    }

    // Helper: Logic for applying filter based on recipe Name
    private func applyRecipe(to image: CIImage, recipeName: String) -> CIImage {
        // Plan to use CIFilter or LUT
        let filter = CIFilter(name: "CIPhotoEffectProcess")
        filter?.setValue(image, forKey: kCIInputImageKey)

        return filter?.outputImage ?? image
    }
}
