//
//  FilmRollRepository.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation
import SwiftData

@Model
class SwiftDataFilmRoll {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var recipeName: String
    var capturedFrame: Int
    var maxFrames: Int
    var isDeveloped: Bool

    init(id: UUID, startDate: Date, recipeName: String, capturedFrame: Int, maxFrames: Int, isDeveloped: Bool) {
        self.id = id
        self.startDate = startDate
        self.recipeName = recipeName
        self.capturedFrame = capturedFrame
        self.maxFrames = maxFrames
        self.isDeveloped = isDeveloped
    }

    func toDomainModel() -> FilmRoll {
        return FilmRoll(id: self.id,
                        startDate: self.startDate,
                        recipeName: self.recipeName,
                        capturedFrame: self.capturedFrame,
                        maxFrames: self.maxFrames,
                        isDeveloped: self.isDeveloped)
    }
}

class FilmRollRepository: FilmRollRepositoryInterface {

    private let modelContext: ModelContext // SwiftData의 context

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // Transfer Domain Entity to swiftData
    func saveRoll(_ roll: FilmRoll) {
        // 1. check if it exist
        let id = roll.id
        let descriptor = FetchDescriptor<SwiftDataFilmRoll>(predicate: #Predicate { $0.id == id })

        if let existingRoll = try? modelContext.fetch(descriptor).first {
            existingRoll.capturedFrame = roll.capturedFrame
            existingRoll.isDeveloped = roll.isDeveloped
        } else {
            let newRoll = SwiftDataFilmRoll(id: roll.id,
                                            startDate: roll.startDate,
                                            recipeName: roll.recipeName,
                                            capturedFrame: roll.capturedFrame,
                                            maxFrames: roll.maxFrames,
                                            isDeveloped: roll.isDeveloped)
            modelContext.insert(newRoll)
        }
    }

    func fetchCurrentRoll() -> FilmRoll? {
        // return recent roll where isDeveloped == false
        var descriptor = FetchDescriptor<SwiftDataFilmRoll>(
            predicate: #Predicate { $0.isDeveloped == false },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit  = 1

        if let currentSwiftDataRoll = try? modelContext.fetch(descriptor).first {
            return currentSwiftDataRoll.toDomainModel()
        }
        return nil
    }

    func appendAssetID(_ assetID: String, to rollID: UUID) {
        let descriptor = FetchDescriptor<SwiftDataFilmRoll>(predicate: #Predicate { $0.id == rollID })
        if let existingRoll = try? modelContext.fetch(descriptor).first {
            try? modelContext.save()
        }
    }

    func fetchCompletedRolls() -> [FilmRoll] {
        // return roll where isDeveloped == true
        let descriptor = FetchDescriptor<SwiftDataFilmRoll>(
            predicate: #Predicate { $0.isDeveloped == true },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        let completedRolls = (try? modelContext.fetch(descriptor)) ?? []
        return completedRolls.map{ $0.toDomainModel() }
    }
    
    func deleteRoll(_ roll: FilmRoll) {
        //delete logic
        let id = roll.id
        let descriptor = FetchDescriptor<SwiftDataFilmRoll>(predicate: #Predicate { $0.id == id })

        if let rollToDelete = try? modelContext.fetch(descriptor).first {
            modelContext.delete(rollToDelete)
        }
    }
    
    func saveImageToLibrary(imageURL: URL, metadata: [String : Any]) async -> Result<String, any Error> {
        //TODO: PHPhotoLibrary - logic for saving album
        return .failure(NSError(domain: "PhotoLibraryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented yet"]))
    }
}
