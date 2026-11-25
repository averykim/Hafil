//
//  FilmRecipeCarouselViewModel.swift
//  Hafil
//
//  Created by JihyeKim on 11/19/26.
//
import Foundation
import Observation

// Carousel Card UI model
struct FilmRecipeOption: Identifiable, Equatable {
    let id: String
    let displayName: String
    let iso: Int
    let description: String
}

// Roll count option
enum RollCapacityOption: Int, CaseIterable, Identifiable {
    case short = 12 // 6 diptych
    case medium = 24 // 12 diptych
    case full = 72 // 36 diptych

    var id: Int { rawValue }
    var diptychCount: Int { rawValue/2 }
    var label: String {
        "\(rawValue) cuts (\(diptychCount) frames)"
    }
}

@Observable
class FilmRecipeCarouselViewModel {
    private let applyFilmPresetUseCase: ApplyFilmPresetUseCase

    let availableRecipes: [FilmRecipeOption] = [
        FilmRecipeOption(id: "Portra 400", displayName: "Portra 400", iso: 400, description: "Warm tone and soft constrast"),
    ]

    var selectedRecipe: FilmRecipeOption
    var selectedCapacity: RollCapacityOption = .full

    init(applyFilmPresetUseCase: ApplyFilmPresetUseCase) {
        self.applyFilmPresetUseCase = applyFilmPresetUseCase
        self.selectedRecipe = availableRecipes[0]
    }

    func selectedRecipe(_ recipe: FilmRecipeOption){
        selectedRecipe = recipe
    }

    func selectedCapacity(_ capacity: RollCapacityOption) {
        selectedCapacity = capacity
    }

    func loadFilmRoll() -> FilmRoll {
        return applyFilmPresetUseCase.execute(recipeName: selectedRecipe.id, maxFrames: selectedCapacity.rawValue)
    }
 }
