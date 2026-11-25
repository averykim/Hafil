//
//  ViewfinderViewModel.swift
//  Hafil
//
//  Created by JihyeKim on 11/19/26.
//

import Foundation
import AVFoundation
import Observation

@Observable
class ViewfinderViewModel {
    private let cameraService: CameraCaptureService

    //Viewfinder View Status
    var isAuthorized: Bool = false
    var isSessionRunning: Bool = false
    var errorMessage: String? = nil

    var captureSession: AVCaptureSession {
        return cameraService.session
    }

    init(cameraService: CameraCaptureService) {
        self.cameraService = cameraService
    }

    func setupAndStartCamera() {
        Task {
            await checkPermission()

            if isAuthorized {
                cameraService.startSession()
                await MainActor.run {
                    self.isSessionRunning = true
                }
            }
        }
    }

    private func checkPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            await MainActor.run { self.isAuthorized = true }
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run(body: {
                self.isAuthorized = granted
                if !granted {
                    self.errorMessage = "Camera permission is reqired for shooting."
                }
            })
        default:
            await MainActor.run(body: {
                self.isAuthorized = false
                self.errorMessage = "Please allow camera access in the Settings"
            })
        }
    }
}
