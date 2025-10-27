//
//  StorageService.swift
//  weftly
//
//  Created by Sanjay Karinje on 10/20/25.
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, path: String) async throws -> StorageUploadResult {
        // Compress image
        guard let imageData = compressImage(image) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return StorageUploadResult(url: downloadURL.absoluteString, data: imageData)
        } catch let error as NSError {
            if error.domain == StorageErrorDomain,
               let code = StorageErrorCode(rawValue: error.code),
               code == .objectNotFound || code == .unauthorized {
                throw NSError(domain: "StorageRules", code: error.code, userInfo: [NSLocalizedDescriptionKey: "Image storage failed. Check Firebase Storage rules or enable test mode."])
            }
            throw error
        }
    }
    
    func uploadProfilePicture(_ image: UIImage, userId: String) async throws -> String {
        // CRITICAL: Use FIXED path so URL never changes
        // New uploads overwrite the old photo → Everyone sees latest automatically
        let path = "profile_pictures/\(userId).jpg"
        let result = try await uploadImage(image, path: path)
        return result.url
    }
    
    func uploadMessageImage(_ image: UIImage, conversationId: String) async throws -> String {
        let path = "message_images/\(conversationId)/\(UUID().uuidString).jpg"
        let result = try await uploadImage(image, path: path)
        return result.url
    }
    
    private func compressImage(_ image: UIImage) -> Data? {
        // Resize if needed (max 1920px width)
        let maxWidth: CGFloat = 1920
        var actualImage = image
        
        if image.size.width > maxWidth {
            let scale = maxWidth / image.size.width
            let newHeight = image.size.height * scale
            let newSize = CGSize(width: maxWidth, height: newHeight)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            actualImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        // Compress with 0.7 quality
        return actualImage.jpegData(compressionQuality: 0.7)
    }
    
    struct StorageUploadResult {
        let url: String
        let data: Data
    }
}

