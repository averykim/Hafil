//
//  FilmProcessingInterface.swift
//  Hafil
//
//  Created by JihyeKim on 10/21/26.
//

import Foundation

protocol FilmProcessingEngineInterface {
    // 도메인(ProcessDiptychUseCase)이 이 함수를 호출합니다.
        // 역할:
        // 1. frameA와 frameB의 번호표(ID)를 보고 디스크에서 원본 사진을 꺼내옴.
        // 2. recipeName(예: "Portra 400")에 맞는 3D LUT 컬러 변환과 Metal 그레인을 적용함.
        // 3. 두 장을 나란히 디프티크로 합성함.
        // 4. 합성된 최종 이미지를 임시 파일로 저장한 뒤, 그 파일의 주소(URL)를 반환함.
    func stitchAndApplyRecipe(frameA: FrameData, frameB: FrameData, recipeName: String) async -> Result<URL, Error>
}
