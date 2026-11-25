//
//  CameraView.swift
//  Hafil
//
//  Created by JihyeKim on 8/31/26.
//

// ZStack parent container: viewfinder, overlay, film recipe carousel

import SwiftUI

struct CameraView: View {
    @Bindable var cameraVM: CameraViewModel
    var viewFinderVM: ViewfinderViewModel
    var overlayVM: OverlayViewModel
    var carouselVM: FilmRecipeCarouselViewModel
    var filmRollVM: FilmRollViewModel

    //Click shutter -> CameraCaptureService trigger
    let onCapturePhoto: () async -> FrameData?

    @State private var showFilmRollGallery: Bool = false

    var body: some View {
        ZStack {
            // 1. bottom: camera preview + half film mask
            ViewfinderView(viewModel: viewFinderVM, frameDesign: cameraVM.frameDesign, isHalfExposed: overlayVM.isHalfExposed)
                .ignoresSafeArea()

            // 2. middle: shutter button, counter, flash/exposure control
            OverlayView(cameraVM: cameraVM, overlayVM: overlayVM, onShutterTap: handleShutterTap, onOpenGallery: {
                showFilmRollGallery = true
            }, onStartNewRoll: {
                cameraVM.isStartingNewRoll = true
            })

            // 3. Top overlay:
            if cameraVM.isStartingNewRoll {
                Color.black.opacity(0.82)
                    .ignoresSafeArea()
                    .transition(.opacity)

                FilmRecipeCarouselView(viewModel: carouselVM, onLoadFilm: { newRoll in
                    cameraVM.triggerHaptic()
                    cameraVM.rollCapacity = newRoll.maxFrames
                    overlayVM.loadNewRoll(newRoll)

                    withAnimation(.easeInOut(duration: 0.25)) {
                        cameraVM.isStartingNewRoll = false
                    }
                })
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            // Run camera session when app is started
            viewFinderVM.setupAndStartCamera()

            // If there is filming roll
            if overlayVM.currentRoll != nil && !overlayVM.isRollFull {
                cameraVM.isStartingNewRoll = false
            }
        }
        .onChange(of: viewFinderVM.errorMessage) { _, newError in
            if newError != nil {
                cameraVM.showCameraAccessAlert = true
            }
        }
        .sheet(isPresented: $showFilmRollGallery) {
            FilmRollView(viewModel: filmRollVM)
        }
        .alert("Camera access required", isPresented: $cameraVM.showCameraAccessAlert){
            Button("Open settings") {
                if let settingURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewFinderVM.errorMessage ?? "Please allow camera access to take photos.")
        }
    }

    // MARK: - Actions
    private func handleShutterTap() {
        guard !overlayVM.isRollFull, !overlayVM.isProcessingShutter else { return }

        cameraVM.triggerHaptic()

        Task {
            if let capturedFrame = await onCapturePhoto() {
                overlayVM.handleCapturedFrame(capturedFrame)
            }
        }
    }
}
