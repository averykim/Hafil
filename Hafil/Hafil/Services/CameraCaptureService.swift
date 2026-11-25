//
//  CameraCaptureService.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//
import Foundation
import AVFoundation

class CameraCaptureService: NSObject {
    let session = AVCaptureSession()

    private let photoOutput = AVCapturePhotoOutput()
    // Background Queue for avoid camera setting block UI
    private let sessionQueue = DispatchQueue(label: "com.halffilmapp.cameraQueue")

    // Camera position
    private var currentPosition: AVCaptureDevice.Position = .back
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var isConfigured: Bool = false

    override init() {
        super.init()
    }

    private func configureSession() {
        guard !isConfigured else { return }

        session.beginConfiguration()

        session.sessionPreset = .photo
        setupCameraInput(currentPosition)

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }

        session.commitConfiguration()

        if videoDeviceInput != nil {
            isConfigured = true
        }
    }

    private func setupCameraInput(_ position: AVCaptureDevice.Position) {
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let newInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }

        if session.canAddInput(newInput) {
            session.addInput(newInput)
            videoDeviceInput = newInput
            currentPosition = position
        }
    }

    func toggleCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.session.beginConfiguration()

            let newPosition: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
            self.setupCameraInput(newPosition)

            self.session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
            if self.isConfigured && !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // ViewModel call this method when shutter is pressed
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        sessionQueue.async { [weak self] in
            guard let self = self, self.isConfigured else { return }
            let settings = AVCapturePhotoSettings()
            settings.isHighResolutionPhotoEnabled = true
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
}
