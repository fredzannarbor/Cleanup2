import Foundation
import UIKit

class PhotoStorageService {
    static let shared = PhotoStorageService()

    private let photosDir: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        photosDir = docs.appendingPathComponent("Photos")
        try? FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
    }

    /// Save a UIImage as JPEG, returns the relative path (Photos/filename.jpg)
    func savePhoto(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }

        // Enforce 1MB max
        let finalData: Data
        if data.count > 1_000_000 {
            // Reduce quality further
            finalData = image.jpegData(compressionQuality: 0.4) ?? data
        } else {
            finalData = data
        }

        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosDir.appendingPathComponent(filename)

        do {
            try finalData.write(to: fileURL)
            return "Photos/\(filename)"
        } catch {
            print("PhotoStorageService: Failed to save photo: \(error)")
            return nil
        }
    }

    /// Load a UIImage from a relative path
    func loadPhoto(relativePath: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Delete a photo at a relative path
    func deletePhoto(relativePath: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: url)
    }
}
