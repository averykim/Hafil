//
//  ViewfinderView.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

// Live feed + framing mask
import SwiftUI
import AVFoundation

struct ViewfinderView: View {

    var viewModel: ViewfinderViewModel
    let frameDesign: FrameDesign
    let isHalfExposed: Bool // false: left, true: right

    var body: some View {
        ZStack {
            // 1. background
            backgroundColor.ignoresSafeArea()

            if viewModel.isAuthorized {
                GeometryReader { geometry in
                    let frameWidth = min(geometry.size.width - 32, (geometry.size.height * 0.68) * (3.0 / 4.0))
                    let frameHeight = frameWidth * (4.0 / 3.0)

                    ZStack {
                        CameraPreviewBridge(session: viewModel.captureSession)
                            .frame(width: frameWidth, height: frameHeight)
                            .clipped()
                            .overlay(HalfFrameMaskOverlay(frameDesign: frameDesign, isHalfExposed: isHalfExposed)
                            )
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 36))
                        .foregroundStyle(.gray)

                    Text(viewModel.errorMessage ?? "Preparing Camera...")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }.allowsTightening(false)
    }

    private var backgroundColor: Color {
        switch frameDesign {
        case .film:
            return Color.black
        case .white:
            return Color(white:0.95)
        case .black:
            return Color(white: 0.08)
        }
    }
}


// Custom Half-Frame Mask and Border
private struct HalfFrameMaskOverlay: View {
    let frameDesign: FrameDesign
    let isHalfExposed: Bool

    var body: some View {
        ZStack {
            Rectangle().stroke(borderColor, lineWidth: borderWidth)

            VStack {
                Rectangle()
                    .fill(.white.opacity(0.35))
                    .frame(width: 1, height: 14)
            }
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.35))
                    .frame(width: 14, height: 1)
            }

            VStack {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(!isHalfExposed ? Color.orange : Color.white.opacity(0.3))
                        .frame(width: 14, height: 3)
                    Rectangle()
                        .fill(!isHalfExposed ? Color.orange : Color.white.opacity(0.3))
                        .frame(width: 14, height: 3)
                }.padding(.top, 10)

                Spacer()
            }
        }
    }

    private var borderColor: Color {
        switch frameDesign {
        case .film:
            return .white.opacity(0.25)
        case .white:
            return .white
        case .black:
            return .black
        }
    }

    private var borderWidth: CGFloat {
        switch frameDesign {
        case .film:
            return 1.5
        case .white, .black:
            return 6
        }
    }
}


//UIKit Bridge for AVCaptureVideoPreviewLayer
private struct CameraPreviewBridge: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> VideoPreviewUIView {
        let view = VideoPreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: VideoPreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session !== session {
            uiView.videoPreviewLayer.session = session
        }
    }
}

private final class VideoPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}
