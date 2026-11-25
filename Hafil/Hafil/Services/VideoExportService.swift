//
//  VideoExportService.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation
import AVFoundation
import CoreImage

class VideoExportService: VideoExportServiceInterface {

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func exportRollAsVideo(frames: [FrameData]) async -> Result<URL, Error> {
            guard !frames.isEmpty else {
                return .failure(NSError(
                    domain: "VideoExportError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "비디오로 내보낼 사진이 없습니다."]
                ))
            }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("FilmRoll_\(UUID().uuidString).mp4")

            let width = 1920
            let height = 1080
            let targetRect = CGRect(x: 0, y: 0, width: width, height: height)

            do {
                // 1. AVAssetWriter 생성 (최종 .mp4 파일 작성기)
                let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

                // 2. 비디오 트랙 인풋 설정 (1080p, H.264)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: width,
                    AVVideoHeightKey: height
                ]
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                writerInput.expectsMediaDataInRealTime = false

                // 3. 픽셀 버퍼 어댑터 연결 (이미지 -> 비디오 프레임 변환 브릿지)
                let bufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: writerInput,
                    sourcePixelBufferAttributes: bufferAttributes
                )

                guard assetWriter.canAdd(writerInput) else {
                    throw NSError(
                        domain: "VideoExportError",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "비디오 인풋을 추가할 수 없습니다."]
                    )
                }

                assetWriter.add(writerInput)

                guard assetWriter.startWriting() else {
                    throw assetWriter.error ?? NSError(
                        domain: "VideoExportError",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "비디오 쓰기를 시작할 수 없습니다."]
                    )
                }

                assetWriter.startSession(atSourceTime: .zero)

                // 4. 사진 한 장당 0.5초씩 노출되도록 타임스탬프를 계산하며 프레임 추가
                let frameDuration = CMTime(value: 300, timescale: 600) // 0.5초
                var presentationTime = CMTime.zero
                let tempDir = FileManager.default.temporaryDirectory

                for frame in frames {
                    // 인코더가 다음 프레임을 받을 준비가 될 때까지 비동기 대기
                    while !writerInput.isReadyForMoreMediaData {
                        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                    }

                    // autoreleasepool로 프레임마다 무거운 이미지 버퍼 즉시 해제
                    let appended: Bool = autoreleasepool {
                        let imageURL = tempDir.appendingPathComponent("\(frame.rawPixelBufferId).jpg")
                        guard let rawImage = CIImage(contentsOf: imageURL),
                              let pool = adaptor.pixelBufferPool else {
                            return false
                        }

                        var pixelBufferOut: CVPixelBuffer?
                        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBufferOut)
                        guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else {
                            return false
                        }

                        // 16:9 검정 캔버스 중앙에 사진 비율을 유지해 맞춤(Aspect Fit)
                        let fittedImage = makeAspectFitImage(rawImage, in: targetRect)
                        ciContext.render(fittedImage, to: pixelBuffer)

                        return adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    }

                    if appended {
                        presentationTime = CMTimeAdd(presentationTime, frameDuration)
                    }
                }

                // 5. 쓰기 종료 및 파일 확정
                writerInput.markAsFinished()
                await assetWriter.finishWriting()

                if assetWriter.status == .completed {
                    return .success(outputURL)
                } else {
                    throw assetWriter.error ?? NSError(
                        domain: "VideoExportError",
                        code: 4,
                        userInfo: [NSLocalizedDescriptionKey: "비디오 파일 완성이 실패했습니다."]
                    )
                }

            } catch {
                return .failure(error)
            }
        }

    private func makeAspectFitImage(_ image: CIImage, in targetRect: CGRect) -> CIImage {
        let background = CIImage(color: .black).cropped(to: targetRect)

        let scaleX = targetRect.width / image.extent.width
        let scaleY = targetRect.height / image.extent.height
        let scale = min(scaleX, scaleY)

        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let offsetX = (targetRect.width - scaled.extent.width) / 2 - scaled.extent.origin.x
        let offsetY = (targetRect.height - scaled.extent.height) / 2 - scaled.extent.origin.y
        let centered = scaled.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

        return centered.composited(over: background)
    }
}
