//
//  FileForensicUtils.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/5/24.
//

import Foundation
import CryptoKit
import Photos
import AVKit

let photoResourceTypes: [PHAssetResourceType] = [.photo, .adjustmentBasePhoto, .alternatePhoto, .fullSizePhoto]
let videoResourceTypes: [PHAssetResourceType] = [.video, .adjustmentBaseVideo, .adjustmentBasePairedVideo, .fullSizeVideo]

func getSHA256(forFile url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    var hasher = SHA256()
    while autoreleasepool(invoking: {
        let nextChunk = handle.readData(ofLength: SHA256.blockByteCount)
        guard !nextChunk.isEmpty else { return false }
        hasher.update(data: nextChunk)
        return true
    }) { }
    let digest = hasher.finalize()
    
    // Here's how to convert to string form
    return digest.map { String(format: "%02hhx", $0) }.joined()
}

func thumbnailCandidacyComparison(_ a: PHAssetResourceType, _ b: PHAssetResourceType) -> Bool {
    let isFilePhoto = photoResourceTypes.firstIndex(of: a)
    let isCurrentPhoto = photoResourceTypes.firstIndex(of: b)
    let isFileVideo = videoResourceTypes.firstIndex(of: a)
    let isCurrentVideo = videoResourceTypes.firstIndex(of: b)
    
    if isFileVideo != nil && isCurrentVideo != nil {
        return isFileVideo! < isCurrentVideo!
    } else {
        return isFilePhoto ?? Int.max < isCurrentPhoto ?? Int.max
    }
}

private let makerApple = "{MakerApple}"

enum MakerAppleExif : Int {
    case BurstUUID = 0x000b
    case LivePhotoContentIdentifier = 0x0011
    
    var stringRepresentation : String {
        String(self.rawValue)
    }
}

enum ExifError : Error {
    case invalidType
    case unknownMediaFormat
}

@inline(__always) func extractImageProperties(url: URL) -> [String: Any]? {
    if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
        return CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
    }
    
    return nil
}

struct ExtractedFilenAssetInfo {
    let localIdentifier: String
    let mediaType: PHAssetMediaType
    let mediaSubtype: PHAssetMediaSubtype
    var creationDate: Date
    var modificationDate: Date
    var location: CLLocation?
    var burstIdentifier: String?
    var burstSelectionTypes: PHAssetBurstSelectionType
    var livePhotoIdentifier: String?
    let sha256: String
    let resourceType: PHAssetResourceType
}

/// Parse ISO 6709 string.
/// e.g. "+34.0595-118.4460+091.541/"
/// SeeAlso: [ISO 6709](https://en.wikipedia.org/wiki/ISO_6709)
// TODO:
func parse(iso6709 text: String?) -> CLLocation? {
    guard
        let results = text?.capture(pattern: "([+-][0-9.]+)([+-][0-9.]+)"),
        let latitude = results[1] as NSString?,
        let longitude = results[2] as NSString?
    else { return nil }
    return CLLocation(latitude: latitude.doubleValue, longitude: longitude.doubleValue)
}

private extension String {
    func capture(pattern: String) -> [String] {
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let result = regex.firstMatch(in: self, range: NSRange(location: 0, length: count))
            else { return [] }
        return (0..<result.numberOfRanges).map { String(self[Range(result.range(at: $0), in: self)!]) }
    }
}
 
///the database should automatically handle duplicate local identifiers, we only need to reference the ID and store the ID for the asset in the filensync database
private func extractLocalIdentifier(url: URL) -> (localIdentifier: String, isFullSizeRender: Bool) {
    let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
    return extractLocalIdentifier(fileName: nameWithoutExtension)
}

func extractLocalIdentifier(fileName: String) -> (localIdentifier: String, isFullSizeRender: Bool) {
    let isFullSize = fileName.lowercased().hasSuffix("fullsizerender")
    // remove the "fullsizerender" suffix
    let localIdentifier = isFullSize ? String(fileName.dropLast(14)) : fileName
    
    return (localIdentifier, isFullSize)
}

private let photoDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return formatter
}()

private let videoDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
}()

func imageNameExifExtractor(url: URL) async throws -> ExtractedFilenAssetInfo
{
    let fileExtension = url.pathExtension
    let type = UTType(filenameExtension: fileExtension)
    
    guard let type else {
        throw ExifError.invalidType
    }
    
    let sha256 = try getSHA256(forFile: url)
    
    var burstId: String? = nil
    var contentId: String? = nil
    var creationDate: Date = Date()
    var location: CLLocation? = nil
    
    if type.conforms(to: .image), let dict = extractImageProperties(url: url) {
        if let makerAppleDict = dict[makerApple] as? [String:Any] {
            burstId = makerAppleDict[MakerAppleExif.BurstUUID.stringRepresentation] as? String
            contentId = makerAppleDict[MakerAppleExif.LivePhotoContentIdentifier.stringRepresentation] as? String
        }
        if let tiffDict = dict[kCGImagePropertyTIFFDictionary as String] as? [String:Any] {
            if let date = tiffDict[kCGImagePropertyTIFFDateTime as String] as? String {
                creationDate = photoDateFormatter.date(from: date) ?? Date()
            }
        }
        if let gpsDict = dict[kCGImagePropertyGPSDictionary as String] as? [String:Any] {
            if let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
               let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double {
                location = CLLocation(latitude: latitude, longitude: longitude)
            }
        }
    } else if (type.conforms(to: .movie) || type.conforms(to: .audio)) {
        let asset = AVURLAsset(url: url)
        let metadataFormats = try await asset.load(.availableMetadataFormats)
        
        for format in metadataFormats {
            let metadataItems = try await asset.loadMetadata(for: format)
            
            for metadataItem in metadataItems {
                guard let value = try await metadataItem.load(.value) else {
                    continue
                }
                
                switch metadataItem.identifier {
                case .quickTimeMetadataContentIdentifier:
                    contentId = value as? String
                case .quickTimeMetadataCreationDate:
                    print(value)
                    creationDate = videoDateFormatter.date(from: value as? String ?? "") ?? Date()
                case .quickTimeMetadataLocationISO6709:
                    location = parse(iso6709: value as? String)
                default:
                    break
                }
            }
        }
    } else {
        throw ExifError.unknownMediaFormat
    }
    
    let (localIdentifier, isFullSize) = extractLocalIdentifier(url: url)
    var mediaSubtype: PHAssetMediaSubtype = []
    let mediaType: PHAssetMediaType = type.conforms(to: .image) ? .image : (type.conforms(to: .movie) ? .video : .audio)
    
    if contentId != nil {
        mediaSubtype.insert(.photoLive)
    }
    
    let resourceType: PHAssetResourceType
    switch (mediaType, contentId, isFullSize) {
    case (.image, _, false):
        resourceType = .photo
    case (.image, _, true):
        resourceType = .fullSizePhoto
    case (.video, nil, false):
        resourceType = .video
    case (.video, nil, true):
        resourceType = .fullSizeVideo
    case (.video, _, false):
        resourceType = .pairedVideo
    case (.video, _, true):
        resourceType = .fullSizePairedVideo
    case (.audio, _, _):
        resourceType = .audio
    case (.unknown, _, _):
        resourceType = .adjustmentData
    case (_, _, _):
        resourceType = .photo
    }
        
    /// If this step was reached, it means the file was at least an image, video, or audio
    return ExtractedFilenAssetInfo(
        localIdentifier: localIdentifier,
        mediaType: mediaType,
        mediaSubtype: mediaSubtype,
        creationDate: creationDate,
        modificationDate: creationDate,
        location: location,
        burstIdentifier: burstId,
        burstSelectionTypes: .autoPick,
        livePhotoIdentifier: contentId,
        sha256: sha256,
        resourceType: resourceType
    )
}
