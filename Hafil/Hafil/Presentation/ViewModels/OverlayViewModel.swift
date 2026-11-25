//
//  OverlayViewModel.swift
//  Hafil
//
//  Created by JihyeKim on 11/19/26.
//

import Foundation
import Observation

@Observable
class OverlayViewModel {
    private let captureUseCase: CaptureShotUseCase

    var currentRoll: FilmRoll?
    var captureState: DiptychCaptureState = .empty
    var isProcessingShutter: Bool = false

    init(captureUseCase: CaptureShotUseCase, activeRoll: FilmRoll? = nil) {
        self.captureUseCase = captureUseCase
        self.currentRoll = activeRoll
    }

    var rollCounterText: String {
        guard let roll = currentRoll else { return "0 / 0" }
        return "\(roll.capturedFrame) / \(roll.maxFrames)"
    }

    var diptychIndicatorText: String {
        switch captureState {
        case .empty:
            return "1 / 2"
        case .halfExposed:
            return "2 / 2"
        case .processing:
            return "..."
        case .completed:
            return "DONE"
        }
    }

    var activeRecipeName: String {
        currentRoll?.recipeName ?? "No Film"
    }

    var isRollFull: Bool {
        guard let roll = currentRoll else { return true }
        return roll.capturedFrame >= roll.maxFrames
    }

    var isHalfExposed: Bool {
        if case .halfExposed(let frameData) = captureState {
            return true
        }
        return false
    }

    // MARK: User Intents
    func handleCapturedFrame(_ newFrame: FrameData) {
        guard let roll = currentRoll, !isRollFull, !isProcessingShutter else { return }

        isProcessingShutter = true

        Task {
            // 1. Execute Domain Use Case
            let nextState = await captureUseCase.execute(currentRoll: roll,
                                                         currentState: captureState,
                                                         newFrame: newFrame)
            // 2. Update UI state in the MainActor
            await MainActor.run(body: {
                self.captureState = nextState
                self.currentRoll?.capturedFrame += 1

                if let updated = self.currentRoll, updated.capturedFrame >= updated.maxFrames {
                    self.currentRoll?.isDeveloped = true
                    self.captureState = .completed
                }

                self.isProcessingShutter = false
            })
        }
    }

    // Initialize when new roll is loaded
    func loadNewRoll(_ roll: FilmRoll) {
        self.currentRoll = roll
        self.captureState = .empty
    }
}
