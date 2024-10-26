//
//  ImageCompressor.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/16/24.
//

import UIKit
import UniformTypeIdentifiers
import SwiftUI

enum ImageFormat {
    case png
    case jpg
    case heic
}

enum CompressionLevels: String, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case extreme = "Extreme"
    
    var id: String { self.rawValue }
}

fileprivate func resizeLevel(for compressionLevel: CompressionLevels) -> CGSize? {
    switch compressionLevel {
    case .none:
        return CGSizeMake(500, 500)
    case .low:
        return CGSizeMake(500, 500)
    case .medium:
        return CGSizeMake(400, 400)
    case .high:
        return CGSizeMake(350, 350)
    case .extreme:
        return CGSizeMake(200, 200)
    }
}

fileprivate func compressionQuality(for compressionLevel: CompressionLevels) -> CGFloat? {
    switch compressionLevel {
    case .none:
        return nil
    case .low:
        return 1.0
    case .medium:
        return 0.75
    case .high:
        return 0.5
    case .extreme:
        return 0.0
    }
}

class ImageCompressor {
    @AppStorage("compressionLevel") static var compressionLevel: CompressionLevels?
    
    private static func getImageFormat(from url: URL) -> ImageFormat? {
        guard let data = try? Data(contentsOf: url), let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let uti = CGImageSourceGetType(imageSource) as String?
        
        switch uti {
        case UTType.png.identifier:
            return .png
        case UTType.jpeg.identifier:
            return .jpg
        case UTType.heic.identifier:
            return .heic
        default:
            return nil
        }
    }
    
    fileprivate static let imageCompressQueue = DispatchQueue(label: "com.filenfoto.imageCompressionQueue")
    
    private static func compressImage(_ provImage: UIImage, format: ImageFormat) -> Data? {
        return imageCompressQueue.sync {
            var image = provImage
            
            guard let compressionQuality = compressionQuality(for: compressionLevel ?? .high) else {
                return nil
            }
            
            if let compressionResize = resizeLevel(for: compressionLevel ?? .high) {
                image = image.resizeImage(image: provImage, targetSize: compressionResize)
            }
            
            switch format {
            case .png, .jpg:
                return image.jpegData(compressionQuality: compressionQuality)
            case .heic:
                if #available(iOS 11.0, *) {
                    let options: NSDictionary = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
                    let data = NSMutableData()
                    guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, UTType.heic.identifier as CFString, 1, nil) else {
                        return nil
                    }
                    CGImageDestinationAddImage(destination, image.cgImage!, options)
                    CGImageDestinationFinalize(destination)
                    return data as Data
                } else {
                    return image.jpegData(compressionQuality: compressionQuality) // fallback to JPEG if HEIC isn't available
                }
            }
        }
    }
    
    private static func getDestinationURL(for originalURL: URL) -> URL {
        let destinationDirectory = FileManager.default.temporaryDirectory
        let fileName = originalURL.deletingPathExtension().lastPathComponent + "_compressed"
        let destinationURL = destinationDirectory.appendingPathComponent(fileName).appendingPathExtension("jpg") // Output format as .jpg
        return destinationURL
    }
    
    @available(iOS 15.0, *)
    static func compressImage(from url: URL, outputDestination: URL) async throws {
        // Load image from URL
        let data = try Data(contentsOf: url)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "ImageErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to load image."])
        }
        
        // Detect the image format
        guard let format = ImageCompressor.getImageFormat(from: url) else {
            throw NSError(domain: "ImageErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported image format."])
        }
        
        // Compress the image
        if let compressedData = ImageCompressor.compressImage(image, format: format) {
            // Write the compressed image to the destination
            try compressedData.write(to: outputDestination)
        } else {
            try image.jpegData(compressionQuality: 1.0)?.write(to: outputDestination)
        }
        
    }
    
    @available(iOS 15.0, *)
    static func compressImage(from cgImage: CGImage, outputDestination: URL) async throws {
        let image = UIImage(cgImage: cgImage)
        
        // Compress the image
        if let compressedData = ImageCompressor.compressImage(image, format: .jpg) {
            // Write the compressed image to the destination
            try compressedData.write(to: outputDestination)
        } else {
            try image.jpegData(compressionQuality: 1.0)?.write(to: outputDestination)
        }
    }
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let newSize = CGSize(width: size.width * percentage, height: size.height * percentage)

        return self.preparingThumbnail(of: newSize)
    }

    func compress(to kb: Int, allowedMargin: CGFloat = 0.2) -> Data? {
        let bytes = kb * 1024
        let threshold = Int(CGFloat(bytes) * (1 + allowedMargin))
        var compression: CGFloat = 1.0
        let step: CGFloat = 0.05
        var holderImage = self
        while let data = holderImage.pngData() {
            let ratio = data.count / bytes
            if data.count < threshold {
                return data
            } else {
                let multiplier = CGFloat((ratio / 5) + 1)
                compression -= (step * multiplier)

                guard let newImage = self.resized(withPercentage: compression) else { break }
                holderImage = newImage
            }
        }

        return nil
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
