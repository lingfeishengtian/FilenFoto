//
//  FFAssetManagerTester.swift
//  FilenFotoTests
//
//  Created by Hunter Han on 9/16/25.
//

import Foundation
import Photos
import Testing

@testable import FilenFoto

struct FFAssetManagerTester {
    let context = FFCoreDataManager.shared.newChildContext()
    
    var testAsset: PHAsset {
        // TODO: Request permissions first
        PHAsset.fetchAssets(with: nil).object(at: 0)
    }

    var testLivePhotoAsset: PHAsset {
        var finAsset: PHAsset?

        PHAsset.fetchAssets(with: nil).enumerateObjects { (asset, _, _) in
            if asset.mediaSubtypes.contains(.photoLive) {
                finAsset = asset
            }
        }

        if finAsset == nil {
            fatalError("Please add a live photo to the library to test")
        }

        return finAsset!
    }
    
    func ensureEnvironmentIsSetUpForTesting() {
        #expect(PhotoContext.shared.filenClient != nil)
        #expect(PhotoContext.shared.rootPhotoDirectory != nil)
    }

    @Test func testBasicAsset() async throws {
        ensureEnvironmentIsSetUpForTesting()
        let insertedAsset = try! await fetchAssetsFromLibrary(testAsset: testAsset)
        await uploadAssetsAndValidate(testAsset: testAsset, insertedFotoAsset: insertedAsset)
    }
    
    @Test func testLivePhotoAsset() async throws {
        // Infinite wait
        while true {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        
        ensureEnvironmentIsSetUpForTesting()
        let insertedAsset = try! await fetchAssetsFromLibrary(testAsset: testLivePhotoAsset)
        await uploadAssetsAndValidate(testAsset: testLivePhotoAsset, insertedFotoAsset: insertedAsset)
        await FFCoreDataManager.shared.saveContextIfNeeded()
    }
    
    @Test func testWorkingSet() async throws {
        let insertedFotoAsset = await FFCoreDataManager.shared.insert(for: testAsset)
        await FFCoreDataManager.shared.saveContextIfNeeded()

        let task = Task {
            let workingAsset = WorkingSetFotoAsset(asset: insertedFotoAsset)
            
            try await workingAsset.retrieveResources(withSupportingPHAsset: testLivePhotoAsset)
            
            
            // Validate all filenUuids
            let doesAssetDirExistInRootPhotoDir = try await doesUUIDExistInFilen(fileUuid: insertedFotoAsset.filenResourceFolderUuid!, parentUuid: try! PhotoContext.shared.unwrappedRootFolderDirectory())
            #expect(doesAssetDirExistInRootPhotoDir)
            
            let remoteResources = insertedFotoAsset.remoteResourcesArray
            for remoteResource in remoteResources {
                let doesRemoteResourceExistInAssetDir = try await doesUUIDExistInFilen(fileUuid: remoteResource.filenUuid!, parentUuid: insertedFotoAsset.filenResourceFolderUuid!)
                #expect(doesRemoteResourceExistInAssetDir)
            }
        }
        
        // Wait 1 second then cancel task
        try await Task.sleep(nanoseconds: 5_000_000_000)
//        await task.result
        
//        // Validate that working directory doesn't exist (because we uploaded all assets) and deinited workingAsset
//        #expect(!FileManager.default.fileExists(atPath: workingAsset.workingSetRootFolder.path))
    }
    
    func doesUUIDExistInFilen(fileUuid: UUID, parentUuid: UUID) async throws -> Bool {
        let filenClient = try PhotoContext.shared.unwrappedFilenClient()
        let filesInParent = try await filenClient.listDir(dirUuid: parentUuid.uuidString)
        
        for dir in filesInParent.directories {
            if dir.uuid.lowercased() == fileUuid.uuidString.lowercased() {
                return true
            }
        }
        
        for file in filesInParent.files {
            if file.uuid.lowercased() == fileUuid.uuidString.lowercased() {
                return true
            }
        }
        
        return false
    }
    
    @Test func grabLivePhotoAssetFromCoreData() async throws {
        let fetchedAssets = try! context.fetch(FotoAsset.fetchRequest())
        for asset in fetchedAssets {
            if asset.mediaSubtypes.contains(.photoLive) {
                print(asset.filenResourceFolderUuid)
                
                for remoteResource in asset.remoteResourcesArray {
                    print((remoteResource as! RemoteResource).filenUuid)
                }
            }
        }
    }

    func fetchAssetsFromLibrary(testAsset: PHAsset) async throws -> FotoAsset {
        let assetsManager = FFResourceManager()

        let insertedFotoAsset = await FFCoreDataManager.shared.insert(for: testAsset)
        let workingDirectory = workingDirectory(for: insertedFotoAsset)

        // Create working directory if it doesn't exist
        try? FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)

        do {
            try await assetsManager.fetchAssets(for: insertedFotoAsset, from: testAsset, writeTo: workingDirectory)
        } catch {
            #expect(Bool(false), "\(error)")
        }

        let resources = PHAssetResource.assetResources(for: testAsset)
        let numberOfResourcesInFinalDirectory = try FileManager.default.contentsOfDirectory(atPath: workingDirectory.path).count
        #expect(numberOfResourcesInFinalDirectory == resources.count)

        let remoteResources = insertedFotoAsset.remoteResourcesArray
        #expect(remoteResources.count == resources.count)
        for remoteResource in remoteResources {
            let fileThatShouldExist = workingDirectory.appending(path: remoteResource.uuid!.uuidString)
            #expect(FileManager.default.fileExists(atPath: fileThatShouldExist.path))

            // TODO: Validate hash
        }
        
        return insertedFotoAsset
    }
    
    func uploadAssetsAndValidate(testAsset: PHAsset, insertedFotoAsset: FotoAsset) async {
        let assetManager = FFResourceManager()
        let workingDirectory = workingDirectory(for: insertedFotoAsset)
        
        do {
            try await assetManager.syncResources(in: workingDirectory, for: insertedFotoAsset)
        } catch {
            #expect(Bool(false), "\(error)")
        }
        
        // TODO: At this point, the original assets have been moved into cache, so we should validate the state of the cache
        
        let remoteResources = insertedFotoAsset.remoteResourcesArray
        for remoteResource in remoteResources {
            let downloadLocation = temporaryDownloadLocation(for: remoteResource)
            
            do {
                try await PhotoContext.shared.filenClient!.downloadFileToPath(fileUuid: remoteResource.filenUuid!.uuidString, path: downloadLocation.path())
                let hashOfWorkingDirectoryFile = remoteResource.fileHashBinary!
                let hashOfDownloadedFile = Data(try FileManager.getSHA256(forFile: downloadLocation))
                
                #expect(hashOfDownloadedFile == hashOfWorkingDirectoryFile)
            } catch {
                #expect(Bool(false), "\(error)")
            }
        }
        
        // TODO: Delete files that were uploaded
    }
    
    func workingDirectory(for fotoAsset: FotoAsset) -> URL {
        TestResourceManager.shared.tempDir.appending(path: "FFAssetManagerTest").appending(component: fotoAsset.uuid!.uuidString)
    }
    
    func temporaryDownloadLocation(for remoteResource: RemoteResource) -> URL {
        TestResourceManager.shared.tempDir.appending(path: remoteResource.uuid!.uuidString)
    }
}
