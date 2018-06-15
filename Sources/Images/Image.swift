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
        let aspectTargetSize = getAspectTargetSize(targetSize)
        
        //print("ORIGINAL SIZE: (\(asset.pixelWidth), \(asset.pixelHeight))")
       //print("TARGET SIZE: \(aspectTargetSize)")
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: aspectTargetSize,
            contentMode: .default,
            options: options) { (image, _) in
                completion(image)
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
    
    
    private func getAspectTargetSize(_ targetSize: CGSize? = nil) -> CGSize {
        guard targetSize != nil else {
            //No maximum size given - use asset full size
            return CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        }
        var actualHeight : CGFloat = CGFloat(asset.pixelHeight)
        var actualWidth : CGFloat = CGFloat(asset.pixelWidth)
        let maxHeight : CGFloat = targetSize!.height
        let maxWidth : CGFloat = targetSize!.width
        var imgRatio : CGFloat = actualWidth/actualHeight
        let maxRatio : CGFloat = maxWidth/maxHeight
        if (actualHeight > maxHeight || actualWidth > maxWidth){
            if(imgRatio < maxRatio){
                //adjust width according to maxHeight
                imgRatio = maxHeight / actualHeight
                actualWidth = imgRatio * actualWidth
                actualHeight = maxHeight
            }
            else if(imgRatio > maxRatio){
                //adjust height according to maxWidth
                imgRatio = maxWidth / actualWidth
                actualHeight = imgRatio * actualHeight
                actualWidth = maxWidth
            }
            else{
                actualHeight = maxHeight
                actualWidth = maxWidth
            }
        }
        return CGSize(
            width: actualWidth,
            height: actualHeight
        )
    }
}

// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.asset == rhs.asset
}


