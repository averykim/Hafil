//
//  CaptureShotUseCase.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation

class CaptureShotUseCase {
    private let repository: FilmRollRepositoryInterface
    private let processDiptychUseCase: ProcessDiptychUseCase

    init(repository: FilmRollRepositoryInterface, processDiptychUseCase: ProcessDiptychUseCase) {
        self.repository = repository
        self.processDiptychUseCase = processDiptychUseCase
    }

    func execute(currentRoll: FilmRoll, currentState: DiptychCaptureState, newFrame: FrameData) async -> DiptychCaptureState {
        guard currentRoll.capturedFrame < currentRoll.maxFrames else {
            return currentState
        }

        switch currentState {
        case .empty:
            // Shot 1
            var updatedRoll = currentRoll
            updatedRoll.capturedFrame += 1
            if updatedRoll.capturedFrame >= updatedRoll.maxFrames {
                updatedRoll.isDeveloped = true
            }
            await MainActor.run {
                self.repository.saveRoll(updatedRoll)
            }

            return .halfExposed(newFrame)

        case .halfExposed(let frameA):
            // Shot 2
            var updatedRoll = currentRoll
            updatedRoll.capturedFrame += 1
            if updatedRoll.capturedFrame >= updatedRoll.maxFrames {
                updatedRoll.isDeveloped = true
            }
            let rollID = updatedRoll.id
            let recipeName = updatedRoll.recipeName
            await MainActor.run {
                self.repository.saveRoll(updatedRoll)
            }

            // Trigger the processing use case in the background
            Task {
                let result = await self.processDiptychUseCase.execute(frameA: frameA, frameB: newFrame, recipeName: recipeName)
                if case .success(let assetID) = result {
                    await MainActor.run {
                        self.repository.appendAssetID(assetID, to: rollID)
                    }
                }
            }

            return .empty
        default:
            return currentState

        }
    }
}
