//
//  FilmRollRepositoryInterface.swift
//  Hafil
//
//  Created by JihyeKim on 10/21/26.
//

import Foundation

protocol FilmRollRepositoryInterface  {
    // save roll -> use swiftData
    func saveRoll(_ roll: FilmRoll)
    func fetchCurrentRoll() -> FilmRoll?
    func fetchCompletedRolls() ->[FilmRoll]
    func deleteRoll(_ roll: FilmRoll)
    func appendAssetID(_ assetID: String, to rollID: UUID)
}
