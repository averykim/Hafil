//
//  Entities.swift
//  Hafil
//
//  Created by JihyeKim on 10/21/26.
//

import Foundation

struct FilmRoll: Equatable {
    let id: UUID
    let startDate: Date
    let recipeName: String
    var capturedFrame: Int
    let maxFrames: Int
    var isDeveloped: Bool
    var assetIDs: [String] = [] //Saved PHAsset localIdentifier list
}

struct FrameData: Equatable {
    let rawPixelBufferId: String
}
