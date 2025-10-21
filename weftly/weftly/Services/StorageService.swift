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
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        // Compress image
        guard let imageData = compressImage(image) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    func uploadProfilePicture(_ image: UIImage, userId: String) async throws -> String {
        let path = "profile_pictures/\(userId)/\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path)
    }
    
    func uploadMessageImage(_ image: UIImage, conversationId: String) async throws -> String {
        let path = "message_images/\(conversationId)/\(UUID().uuidString).jpg"
        return try await uploadImage(image, path: path)
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
}

