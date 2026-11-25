//
//  PhotoLibraryService.swift
//  Hafil
//
//  Created by JihyeKim on 10/20/26.
//

import Foundation
import Photos
import ImageIO
import UniformTypeIdentifiers

class PhotoLibraryService: PhotoLibraryServiceInterface {
    func requestAuthorization() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if current == .authorized || current == .limited {
            return true
        }
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
    
    func saveImageToLibrary(imageURL: URL, metadata: [String : Any]) async -> Result<String, any Error> {
        let authorized = await requestAuthorization()
        guard authorized else {
            return .failure(NSError(domain: "PhotoLibraryError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Photo library access is denied."]))
        }

        let finalURL = writeMetadata(metadata, to: imageURL) ?? imageURL
        var assetPlaceholder: PHObjectPlaceholder?

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.creationRequestForAssetFromImage(atFileURL: finalURL)
                assetPlaceholder = request?.placeholderForCreatedAsset
            }

            // 메타데이터 기록용 임시 복사본 정리
            if finalURL != imageURL {
                try? FileManager.default.removeItem(at: finalURL)
            }

            guard let localIdentifier = assetPlaceholder?.localIdentifier else {
                return .failure(NSError(
                    domain: "PhotoLibraryError",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "저장된 사진의 식별자를 가져오지 못했습니다."]
                ))
            }

            return .success(localIdentifier)
        } catch {
            if finalURL != imageURL {
                try? FileManager.default.removeItem(at: finalURL)
            }
            return .failure(error)
        }
    }
    
    func fetchImage(for assetId: String) async -> Result<Data, any Error> {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            return .failure(NSError(
                domain: "PhotoLibraryError",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "사진첩에서 해당 이미지를 찾을 수 없습니다."]
            ))
        }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                if let data {
                    continuation.resume(returning: .success(data))
                } else {
                    let error = (info?[PHImageErrorKey] as? Error) ?? NSError(
                        domain: "PhotoLibraryError",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "이미지 데이터를 불러오지 못했습니다."]
                    )
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }

    // MARK: - EXIF / TIFF Metadata Writer
    private func writeMetadata(_ metadata: [String: Any], to sourceURL: URL) -> URL? {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else { return nil }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("exif_\(UUID().uuidString).jpg")

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }

        var properties = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]) ?? [:]
        var exif = (properties[kCGImagePropertyExifDictionary] as? [CFString: Any]) ?? [:]
        var tiff = (properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]) ?? [:]

        if let lensModel = metadata["LensModel"] as? String {
            exif[kCGImagePropertyExifLensModel] = lensModel
        }
        if let userComment = metadata["RecipeName"] as? String {
            exif[kCGImagePropertyExifUserComment] = "Film Recipe: \(userComment)"
        }
        if let software = metadata["Software"] as? String {
            tiff[kCGImagePropertyTIFFSoftware] = software
        }

        properties[kCGImagePropertyExifDictionary] = exif
        properties[kCGImagePropertyTIFFDictionary] = tiff

        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        return CGImageDestinationFinalize(destination) ? outputURL : nil
    }
}
