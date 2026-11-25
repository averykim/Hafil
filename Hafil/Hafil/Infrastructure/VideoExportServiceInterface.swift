//
//  VideoExportServiceInterface.swift
//  Hafil
//
//  Created by JihyeKim on 10/21/26.
//

import Foundation

protocol VideoExportServiceInterface {
    // 도메인(ExportVideoUseCase)이 이 함수를 호출합니다.
    // 역할:
    // 1. 전달받은 프레임들(디프티크 완성본들)을 시간순으로 나열함.
    // 2. AVAssetWriter를 사용하여 비디오 파이프라인(mp4/mov)을 만듦.
    // 3. 사진들을 비디오 트랙에 합침(stitchAllFrames).
    // 4. 완성된 비디오 파일의 주소(URL)를 반환함.
    func exportRollAsVideo(frames: [FrameData]) async -> Result<URL, Error>
}
