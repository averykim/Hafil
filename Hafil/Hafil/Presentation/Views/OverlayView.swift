//
//  OverlayView.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//
// shutter button + indicators
import SwiftUI

struct OverlayView: View {

    var cameraVM: CameraViewModel
    var overlayVM: OverlayViewModel

    let onShutterTap: () -> Void
    let onOpenGallery: () -> Void
    let onStartNewRoll: () -> Void

    var body: some View {
        VStack {
            //MARK: - top bar (recipe badge + camera setting toggle)
            topControlBar
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Spacer()

            // MARK: - Roll complete banner
            if overlayVM.isRollFull {
                rollCompletedBanner
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // MARK: - bottom control bar (gallery + shutter + counter)
            bottomControlBar
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Top Control Bar
    private var topControlBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                // Current locked roll recipe name
                Circle()
                    .fill(overlayVM.isRollFull ? Color.gray : Color.orange)
                    .frame(width: 6, height: 6)

                Text(overlayVM.activeRecipeName)
                    .font(.caption.monospaced().bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.6), in: Capsule())

            Spacer()

            //Flash mode (off -> auto -> directLight -> ambientLight)
            controlChip(
                icon: flashIconName,
                label: flashLabel,
                isActive: cameraVM.currentFlashMode != .off
            ){
                cameraVM.triggerHaptic()
                cycleFlashMode()
            }

            //Exposure mode
            controlChip(
                icon: "sun.max",
                label: exposureLabel,
                isActive: cameraVM.currentExposureMode != .continuousAuto
            ){
                cameraVM.triggerHaptic()
                cycleExposureMode()
            }

            //Frame Design (film -> white -> black)
            controlChip(
                icon: "rectangle.inset.filled",
                label: frameDesignLabel,
                isActive: false
            ){
                cameraVM.triggerHaptic()
                cycleFrameDesign()
            }
        }
    } //topControlBar

    // MARK: - Roll Completed Banner
    private var rollCompletedBanner: some View {
        Button(action: {
            cameraVM.triggerHaptic()
            onStartNewRoll()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "film.stack")
                Text("Film finished · Load a new roll").font(.footnote.bold())
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.orange, in: Capsule())
        }
    }//Banner

    // MARK: - Bottom Control Bar
    private var bottomControlBar: some View {
        HStack {
            Button(action: {
                cameraVM.triggerHaptic()
                onOpenGallery()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "film").font(.title3)
                    Text("ROLLS").font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.white)
                .frame(width: 60, height: 56)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
            }

            Spacer()

            // Center: shutter button
            Button(action: onShutterTap) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 74, height: 74)

                    Circle()
                        .fill(shutterFillColor)
                        .frame(width: 62, height: 62)
                        .scaleEffect(overlayVM.isProcessingShutter ? 0.9 : 1.0)
                        .animation(.easeOut(duration: 0.12), value: overlayVM.isProcessingShutter)
                }
            }
            .disabled(overlayVM.isRollFull || overlayVM.isProcessingShutter)
            .opacity(overlayVM.isRollFull ? 0.35 : 1.0)

            Spacer()

            // Right: Diptych label ("1 / 2") + whole roll counter ("36 / 72 ")
            VStack(alignment: .trailing, spacing: 4) {
                Text(overlayVM.diptychIndicatorText)
                    .font(.caption.monospaced().bold())
                    .foregroundStyle(overlayVM.isHalfExposed ? .orange : .white)

                Text(overlayVM.rollCounterText)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(width: 64, height: 56)
            .padding(.horizontal, 8)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
        }
    }//controlBar

    // MARK: - Reuable Control Chip
    private func controlChip(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(label).font(.caption2.monospaced().bold())
            }
            .foregroundStyle(isActive ? .black : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isActive ? Color.orange : Color.black
                .opacity(0.6), in: Capsule())
        }
    } //control chip

    // MARK: - Display Helpers & Mode cycling
    private var shutterFillColor: Color {
        if overlayVM.isRollFull {
            return .gray
        }
        return overlayVM.isHalfExposed ? .orange :  .white
    }

    private var flashIconName: String {
        switch cameraVM.currentFlashMode {
        case .directLight:
            return "bolt.fill"
        case .ambientLight:
            return "sparkes"
        case .auto:
            return "bolt.badge.a"
        case .off:
            return "bolt.slash"
        }
    }

    private var flashLabel: String {
        switch cameraVM.currentFlashMode {
        case .directLight:
            return "DIR"
        case .ambientLight:
            return "AMB"
        case .auto:
            return "AUTO"
        case .off:
            return "OFF"
        }
    }

    private var exposureLabel: String {
        switch cameraVM.currentExposureMode {
        case .continuousAuto:
            return "C-AE"
        case .auto:
            return "AE"
        case .locked:
            return "LOCK"
        case .custom:
            return "MAN"
        }
    }

    private var frameDesignLabel: String {
        switch cameraVM.frameDesign {
        case .film:
            return "FILM"
        case .white:
            return "WHT"
        case .black:
            return "BLK"
        }
    }

    private func cycleFlashMode() {
        switch cameraVM.currentFlashMode {
        case .directLight:
            cameraVM.currentFlashMode = .directLight
        case .ambientLight:
            cameraVM.currentFlashMode = .ambientLight
        case .auto:
            cameraVM.currentFlashMode = .auto
        case .off:
            cameraVM.currentFlashMode = .off
        }
    }

    private func cycleExposureMode() {
        switch cameraVM.currentExposureMode {
        case .continuousAuto:
            cameraVM.currentExposureMode = .continuousAuto
        case .auto:
            cameraVM.currentExposureMode = .auto
        case .locked:
            cameraVM.currentExposureMode = .locked
        case .custom:
            cameraVM.currentExposureMode = .custom
        }
    }

    private func cycleFrameDesign() {
        switch cameraVM.frameDesign {
        case .film:
            cameraVM.frameDesign = .white
        case .white:
            cameraVM.frameDesign = .black
        case .black:
            cameraVM.frameDesign = .film
        }
    }

}
