//
//  CameraViewModel.swift
//  Hafil
//
//  Created by JihyeKim on 8/31/26.
//

// centel UI orchestrator
// Exposure Mode, Flash Mode, RollCapacity, FrameDesign, One Recipe -> One Roll, Haptic 

import Foundation
import SwiftUI

enum ExposureMode {
    case continuousAuto
    case auto
    case locked
    case custom
}

enum FlashMode {
    case directLight
    case ambientLight
    case auto
    case off
}

enum FrameDesign {
    case film
    case white
    case black
}

@Observable //view recognize state change
class CameraViewModel {

    // Navigation State
    // Film Carousel will be displayed when it is true
    // False -> show camera viewFinder and shutter button
    var isStartingNewRoll: Bool = true

    // Global Settings
    var currentExposureMode: ExposureMode = .continuousAuto
    var exposureBias: Float = 0.0 //custom (-2.0 ~ +2.0
    var currentFlashMode: FlashMode = .off
    var frameDesign: FrameDesign = .film

    // Roll Count
    var rollCapacity: Int = 72

    var showCameraAccessAlert: Bool = false

    func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
