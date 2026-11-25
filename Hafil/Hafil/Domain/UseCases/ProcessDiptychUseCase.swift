//
//  ProcessDiptychUseCase.swift
//  Hafil
//
//  Created by JihyeKim on 10/22/26.
//

import Foundation

class ProcessDiptychUseCase {
    private let repository: FilmRollRepositoryInterface
    private let engine: FilmProcessingEngineInterface
    private let photoLibrary: PhotoLibraryServiceInterface

    init(repository: FilmRollRepositoryInterface, engine: FilmProcessingEngineInterface, photoLibrary: PhotoLibraryServiceInterface) {
        self.repository = repository
        self.engine = engine
        self.photoLibrary = photoLibrary
    }

    func execute(frameA: FrameData, frameB: FrameData, recipeName: String) async -> Result<String, Error> {
        let stitchResult = await engine.stitchAndApplyRecipe(frameA: frameA, frameB: frameB, recipeName: recipeName)

        switch stitchResult {
        case .success(let imageURL):
            let metadata: [String: Any] = [
                "LensModel": "Half-Frame 28mm f/2.8",
                "Software": "HalfFilmApp",
                "RecipeName": recipeName
            ]
            let saveResult = await photoLibrary.saveImageToLibrary(imageURL: imageURL, metadata: metadata)
            
            // Result and original file organize
            let tempDir = FileManager.default.temporaryDirectory
            try? FileManager.default.removeItem(at: imageURL)
            try? FileManager.default.removeItem(at: tempDir.appendingPathComponent("\(frameA.rawPixelBufferId).jpg"))
            try? FileManager.default.removeItem(at: tempDir.appendingPathComponent("\(frameB.rawPixelBufferId).jpg"))

            return saveResult

        case .failure(let error):
            return .failure(error)
        }
    }
}
