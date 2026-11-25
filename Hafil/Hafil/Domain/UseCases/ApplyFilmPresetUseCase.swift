//
//  ApplyFilmPresetUseCase.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation

class ApplyFilmPresetUseCase {
    private let repository: FilmRollRepositoryInterface

    init(repository: FilmRollRepositoryInterface) {
        self.repository = repository
    }

    func execute(recipeName: String, maxFrames: Int) -> FilmRoll {
        let newRoll = FilmRoll(
            id: UUID(),
            startDate: Date(),
            recipeName: recipeName,
            capturedFrame: 0,
            maxFrames: maxFrames,
            isDeveloped: false
        )
        repository.saveRoll(newRoll)
        return newRoll
    }
}
