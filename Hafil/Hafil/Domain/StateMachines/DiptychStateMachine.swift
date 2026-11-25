//
//  DiptychStateMachine.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation

enum DiptychCaptureState: Equatable {
    case empty
    case halfExposed(FrameData)
    case processing
    case completed
}
