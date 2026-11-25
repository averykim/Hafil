//
//  ExportVideoUseCase.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation

class ExportVideoUseCase {
    private let videoService: VideoExportServiceInterface

    init(videoService: VideoExportServiceInterface) {
        self.videoService = videoService
    }

    func execute(roll: FilmRoll) async -> Result<URL, Error> {
        guard roll.isDeveloped else {
            return .failure(NSError(domain: "ExportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Roll must be developed before exporting."]))
        }

        let frames: [FrameData] = []
        return await videoService.exportRollAsVideo(frames: frames)
    }
}
