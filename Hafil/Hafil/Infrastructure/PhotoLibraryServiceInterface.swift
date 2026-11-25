//
//  PhotoLibraryServiceInterface.swift
//  Hafil
//
//  Created by JihyeKim on 11/24/26.
//

import Foundation

protocol PhotoLibraryServiceInterface {
    func requestAuthorization() async -> Bool
    func saveImageToLibrary(imageURL: URL, metadata: [String: Any]) async -> Result<String, Error>
    func fetchImage(for assetId: String) async -> Result<Data, Error>
}
