//
//  HafilApp.swift
//  Hafil
//
//  Created by JihyeKim on 8/11/26.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct HafilApp: App {

    @State private var container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            CameraView(
                cameraVM: container.cameraVM,
                viewFinderVM: container.viewfinderVM,
                overlayVM: container.overlayVM,
                carouselVM: container.carouselVM,
                filmRollVM: container.filmRollVM,
                onCapturePhoto: {
                    await container.capturePhoto()
                }
            )}
        .modelContainer(container.modelContainer)
    }
}

// MARK: - Dependency Container
@MainActor
@Observable
final class AppDependencyContainer {
    let modelContainer: ModelContainer

    // Service & Capture Bridge
    private let cameraService: CameraCaptureService
    private let photoCaptureBridge: PhotoCaptureBridge

    // Presentation ViewModels
    let cameraVM: CameraViewModel
    let viewfinderVM: ViewfinderViewModel
    let overlayVM: OverlayViewModel
    let carouselVM: FilmRecipeCarouselViewModel
    let filmRollVM: FilmRollViewModel

    init() {
        // 1. Create SwiftData container
        do {
            self.modelContainer = try ModelContainer(for: SwiftDataFilmRoll.self)
        } catch {
            fatalError("Fail to create SwiftData ModelContainer: \(error)")
        }

        // 2. Infrastructure & Service
        let repository = FilmRollRepository(modelContext: modelContainer.mainContext)
        let photoLibraryService = PhotoLibraryService()
        let processingActor = FilmProcessingActor()
        let videoService = VideoExportService()
        let cameraService = CameraCaptureService()

        self.cameraService = cameraService
        self.photoCaptureBridge = PhotoCaptureBridge()

        // 3. Domain UseCases (DI)
        let processDiptychUseCase = ProcessDiptychUseCase(
            repository: repository,
            engine: processingActor,
            photoLibrary: photoLibraryService
        )
        let captureShotUseCase = CaptureShotUseCase(
            repository: repository,
            processDiptychUseCase: processDiptychUseCase
        )
        let applyPresetUseCase = ApplyFilmPresetUseCase(repository: repository)
        let exportVideoUseCase = ExportVideoUseCase(videoService: videoService)

        // 4. Restore processing roll in disk
        let activeRoll = repository.fetchCurrentRoll()

        // 5. Presentation ViewModels
        self.cameraVM = CameraViewModel()
        self.viewfinderVM = ViewfinderViewModel(cameraService: cameraService)
        self.overlayVM = OverlayViewModel(captureUseCase: captureShotUseCase, activeRoll: activeRoll)
        self.carouselVM = FilmRecipeCarouselViewModel(applyFilmPresetUseCase: applyPresetUseCase)
        self.filmRollVM = FilmRollViewModel(repository: repository, exportVideoUseCase: exportVideoUseCase)
    }

    // CameraView
    func capturePhoto() async -> FrameData? {
        return await photoCaptureBridge.capture(using: cameraService)
    }
}


// MARK: - AVCapturePhotoCaptureDelegate -> async / await bridge
private final class PhotoCaptureBridge: NSObject, AVCapturePhotoCaptureDelegate {

    private var continuation: CheckedContinuation<FrameData?, Never>?

    func capture(using service: CameraCaptureService) async -> FrameData? {
        guard continuation == nil else { return nil }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            service.capturePhoto(delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let activeContinuation = continuation
        continuation = nil

        guard error == nil, let imageData = photo.fileDataRepresentation() else {
            activeContinuation?.resume(returning: nil)
            return
        }

        // save path for FilmProcessingActor and same file name ("\(<id>).jpg") in temp disk
        let bufferId = UUID().uuidString
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(bufferId).jpg")

        do {
            try imageData.write(to: fileURL)
            activeContinuation?.resume(returning: FrameData(rawPixelBufferId: bufferId))
        } catch {
            activeContinuation?.resume(returning: nil)
        }
    }
}
