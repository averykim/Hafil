//
//  FilmRollViewModel.swift
//  Hafil
//
//  Created by JihyeKim on 11/19/26.
//
import Foundation
import Observation

enum PhotoExportFormat: String, CaseIterable, Identifiable {
    case diptych = "Diptych"
    case singleSplit = "Single"

    var id: String { rawValue }
}


@Observable
class FilmRollViewModel {
    private let repository: FilmRollRepositoryInterface
    private let exportVideoUseCase: ExportVideoUseCase

    // UI State
    var completedRolls: [FilmRoll] = []
    var selectedRoll: FilmRoll?
    var selectedExportFormat: PhotoExportFormat = .diptych

    // Video export State
    var isExportingVideo: Bool = false
    var exportedVideoURL: URL?
    var errorMessage: String?

    init(repository: FilmRollRepositoryInterface, exportVideoUseCase: ExportVideoUseCase) {
        self.repository = repository
        self.exportVideoUseCase = exportVideoUseCase
    }

    func loadCompletedRolls() {
        completedRolls = repository.fetchCompletedRolls()
    }

    func selectRoll(_ roll: FilmRoll) {
        selectedRoll = roll
    }

    func deleteRoll(_ roll: FilmRoll) {
        repository.deleteRoll(roll)
        completedRolls.removeAll {$0.id == roll.id}

        if selectedRoll?.id == roll.id {
            selectedRoll = nil
        }
    }

    // Export selected roll to a video
    func exportVideo(for roll: FilmRoll) {
        guard !isExportingVideo else { return }

        isExportingVideo = true
        errorMessage = nil
        exportedVideoURL = nil

        Task {
            let result = await exportVideoUseCase.execute(roll: roll)

            await MainActor.run {
                self.isExportingVideo = false

                switch result {
                case .success(let videoURL):
                    self.exportedVideoURL = videoURL
                case.failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Initialize when share sheet is closed
    func clearExportState() {
        exportedVideoURL = nil
        errorMessage = nil
    }
}
