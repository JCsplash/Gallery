import UIKit
import Photos

/// Wrap a PHAsset
public class Image: Equatable {
    
    public let asset: PHAsset
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
    }
}

// MARK: - UIImage

extension Image {
    
    /// Resolve UIImage synchronously
    ///
    /// - targetSize: The target size
    /// - Returns: The resolved UIImage, otherwise nil
    public func resolve(targetSize: CGSize? = nil, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        //Use requestImageData instead of requestImage to avoid memory crash
        PHImageManager.default().requestImageData(for: asset, options: options) { (imageData, str, orientation, hash) in
            completion(UIImage(data: imageData!))
        }
    }
    
    /// Resolve an array of Image
    ///
    /// - Parameters:
    ///   - images: The array of Image
    ///   - targetSize: The target size for all images
    ///   - completion: Called when operations completion
    public static func resolve(images: [Image], targetSize: CGSize? = nil, completion: @escaping ([UIImage?]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var convertedImages = [Int: UIImage]()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            image.resolve(targetSize: targetSize, completion: { resolvedImage in
                if let resolvedImage = resolvedImage {
                    convertedImages[index] = resolvedImage
                }
                
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: .main, execute: {
            let sortedImages = convertedImages
                .sorted(by: { $0.key < $1.key })
                .map({ $0.value })
            completion(sortedImages)
        })
    }
    
}

// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.asset == rhs.asset
}


