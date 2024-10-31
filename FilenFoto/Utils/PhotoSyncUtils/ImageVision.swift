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
    static private let logger = Logger(subsystem: "com.hunterhan.FilenFoto", category: "ImageVision")
    static private let imageDispatchQueue = DispatchQueue(label: "com.hunterhan.FilenFoto.imageVisionDispatchQueue", qos: .background)

    static func classifyAndTextRecognize(image imageURL: URL, completionHandler: @escaping (([VNClassificationObservation], [VNRecognizedTextObservation])?, Error?) -> Void) {
        let image = CGImageSourceCreateWithURL(imageURL as CFURL, nil)
        let cgImage = CGImageSourceCreateImageAtIndex(image!, 0, nil)
        
        print("Vision request for \(imageURL)")
        
        classifyAndTextRecognize(image: cgImage!) { results, error in
            if error != nil {
                completionHandler(nil, error)
            } else {
                completionHandler(results, nil)
            }
        }
    }
    
    fileprivate let dispatchGroup = DispatchGroup()
    static func classifyAndTextRecognize(image cgImage: CGImage, completionHandler: @escaping (([VNClassificationObservation], [VNRecognizedTextObservation])?, Error?) -> Void) {
            print("Start to make vision handling")
            
            var imageRequest: VNClassifyImageRequest = {
                let req = VNClassifyImageRequest(completionHandler: { (retReq, err) in
                    if retReq.results == nil {
                        return
                    }
                    print("Found \(retReq.results!.count) results")
                })
                
                return req
            }()
            
            var textRequest: VNRecognizeTextRequest = {
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
            }()
            
#if targetEnvironment(simulator)
            imageRequest.usesCPUOnly = true
            textRequest.usesCPUOnly = true
#endif
            
        Task {
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            var imageClassifications: [VNClassificationObservation] = []
            var recognizedTextClassifications: [VNRecognizedTextObservation] = []
            
            do {
                try imageRequestHandler.perform([imageRequest, textRequest])
            } catch {
                print("FAILURE VISION \(error)")
                completionHandler(nil, error)
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
            
            completionHandler((imageClassifications, recognizedTextClassifications), nil)
        }
    }
    
    static func classifyAndTextRecognize(video videoURL: URL, completionHandler: @escaping (VideoClassificationResults?, Error?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        
        print("Classifying Video")
        
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            classifyAndTextRecognize(image: img) { results, error in
                if error != nil {
                    completionHandler(nil, error)
                } else {
                    completionHandler(VideoClassificationResults(photoRecog: results!, generatedCGImage: img), nil)
                }
            }
        } catch {
            print(error.localizedDescription)
            completionHandler(nil, error)
        }
    }
}

struct VideoClassificationResults {
    let photoRecog: ([VNClassificationObservation], [VNRecognizedTextObservation])
    let generatedCGImage: CGImage
}
