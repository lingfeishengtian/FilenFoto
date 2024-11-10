//
//  ImageVision.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/28/24.
//

import Foundation
import Vision
import AVFoundation
import os

class ImageVision {
    enum ImageVisionError : Error {
        case failedToClassify(String)
    }
    
    static private let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "ImageVision")
    static private let imageDispatchQueue = DispatchQueue(label: "com.hunterhan.FilenFoto.imageVisionDispatchQueue", qos: .background)
    
    static func createImageRequest() -> VNClassifyImageRequest {
        let req = VNClassifyImageRequest(completionHandler: { (retReq, err) in
            if retReq.results == nil {
                return
            }
            print("Found \(retReq.results!.count) results")
        })
        
        return req
    }
    
    static func createTextRequest() -> VNRecognizeTextRequest {
        let req = VNRecognizeTextRequest(completionHandler: { (retReq, err) in
            if retReq.results == nil {
                return
            }
            print("Found \(retReq.results!.count) results")
        })
        req.automaticallyDetectsLanguage = true
        req.recognitionLevel = .accurate
        print(req.recognitionLanguages)
        req.progressHandler = { req, progress, error in
        }
        return req
    }
    
    static func classifyAndTextRecognize(file url: URL, isImage: Bool, completion: @escaping (Result<ClassificationResults, Error>) -> Void) {
        Task {
            do {
                if isImage {
                    completion(.success(try classifyAndTextRecognize(image: url)))
                } else {
                    completion(.success(try classifyAndTextRecognize(video: url)))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func classifyAndTextRecognize(image imageURL: URL) throws -> ClassificationResults {
        let image = CGImageSourceCreateWithURL(imageURL as CFURL, nil)
        let cgImage = CGImageSourceCreateImageAtIndex(image!, 0, nil)
        
        print("Vision request for \(imageURL)")
        
        let results = try classifyAndTextRecognize(image: cgImage!)
        return ClassificationResults(photoRecog: results, generatedCGImage: cgImage!)
    }
    
    fileprivate let dispatchGroup = DispatchGroup()
    private static func classifyAndTextRecognize(image cgImage: CGImage) throws -> ([VNClassificationObservation], [VNRecognizedTextObservation]) {
        logger.log("Start vision handling")
        let imageRequest = createImageRequest()
        let textRequest = createTextRequest()
        
#if targetEnvironment(simulator)
            imageRequest.usesCPUOnly = true
            textRequest.usesCPUOnly = true
#endif
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        var imageClassifications: [VNClassificationObservation] = []
        var recognizedTextClassifications: [VNRecognizedTextObservation] = []
        
        do {
            try imageRequestHandler.perform([imageRequest, textRequest])
        } catch {
            logger.error("FAILURE VISION \(error)")
            throw ImageVisionError.failedToClassify(error.localizedDescription)
        }
        
        for res in imageRequest.results! {
            if !res.confidence.isZero && !res.confidence.isNaN && res.confidence >= 0.1 {
                imageClassifications.append(res)
            } else {
                break
            }
        }
        for res in textRequest.results! {
            if !res.confidence.isZero && !res.confidence.isNaN && res.confidence >= 0.05 {
                recognizedTextClassifications.append(res)
            } else {
                break
            }
        }
        
        return (imageClassifications, recognizedTextClassifications)
    }
    
    private static func classifyAndTextRecognize(video videoURL: URL) throws -> ClassificationResults {
        let asset = AVAsset(url: videoURL)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        
        print("Classifying Video")
        
        let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        let results = try classifyAndTextRecognize(image: img)
        
        return ClassificationResults(photoRecog: results, generatedCGImage: img)
    }
}

struct ClassificationResults {
    let photoRecog: ([VNClassificationObservation], [VNRecognizedTextObservation])
    let generatedCGImage: CGImage
}
