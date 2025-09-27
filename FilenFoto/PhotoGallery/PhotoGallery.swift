//
//  PhotoGallery.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI
import CoreData

func imageGenerator(named name: String) -> [UIImage] {
    var images: [UIImage] = []

    for _ in 1...10000 {
        // Generate random size (e.g., between 50x50 and 200x200)
        let width = CGFloat.random(in: 50...200)
        let height = CGFloat.random(in: 50...200)
        let size = CGSize(width: width, height: height)

        // Begin image context with random size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()

        // Generate a random color
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1.0)

        // Fill the context with the random color
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))

        // Extract image and add to the array
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            images.append(image)
        }

        UIGraphicsEndImageContext()
    }

    return images
}

struct PhotoDataSource: PhotoDataSourceProtocol {
    let photos: FetchedResults<FotoAsset>
    
    func numberOfPhotos() -> Int {
        photos.count
    }

    func photoAt(index: Int) -> UIImage? {
        guard index >= 0 && index < photos.count else { return nil }
//        return photos[index]
        let currentAsset = photos[index]
        return ThumbnailProvider.shared.thumbnail(for: currentAsset)
//        if let cgimage = cgImageFromI420File(url: FileManager.workingSetDirectory.appending(path: "output_test.yuv"), width: 200, height: 133) {
//            return UIImage(cgImage: cgimage)
//        }
//        
//        return nil
//        return UIImage(contentsOfFile: FileManager.workingSetDirectory.appending(path: "TestImage.jpeg").path())
    }
}

struct PhotoViewProvider: SwiftUIProviderProtocol {
    func topBar(with image: UIImage) -> any View {
        Text(image.debugDescription)
    }
    
    func bottomBar(with image: UIImage) -> any View {
        Button("Test Filen") {
        }
    }
    
    func detailedView(for image: UIImage) -> any View {
        VStack {
            Text("Photo Detail View")
                .font(.headline)
                .padding()
            Text("Size: \(Int(image.size.width)) x \(Int(image.size.height))")
                .font(.subheadline)
        }
    }
}


struct PhotoGallery: View {
    @FetchRequest(
        sortDescriptors: [.init(keyPath: \FotoAsset.dateCreated, ascending: false)]
    ) var photos: FetchedResults<FotoAsset>
    
    var body: some View {
        TabView {
            Tab("Gallery", systemImage: "photo.on.rectangle.angled") {
                ZStack {
                    PhotosViewer(
                        photoDataSource: PhotoDataSource(photos: photos),
                        swiftUIProvider: PhotoViewProvider()
                    )
                    
                    VStack {
                        HStack {
                            Text("Library")
                                .font(.largeTitle)
                                .bold()
                                .padding()
                            Spacer()
                            
                        }
                        Spacer()
                        Button("Test") {
                            Task {
                                let backgroundContext = FFCoreDataManager.shared.newChildContext()
                                // Insert 100,000 photos repeating the existing photos in the database and copy the resources too
                                for i in 0..<100_000 {
                                    let currentAsset = photos[i % photos.count]
                                    var cache: [NSManagedObjectID: NSManagedObject] = [:]
                                    let clone = deepClone(currentAsset, into: backgroundContext, cache: &cache)
                                    print("adding \(clone.localUuid)")
                                    try! backgroundContext.save()
                                    await FFCoreDataManager.shared.saveContextIfNeeded()
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    do {
                        try PhotoSyncController.shared.beginSync()
                    } catch FilenFotoError.noCameraPermissions {
                        PhotoSyncController.shared.requestPermission { succeeded in
                            if succeeded {
                                print("Permission granted.")
                            }
                        }
                    } catch {
                        print("Unexpected error: \(error).")
                    }
                }
            }
            
            Tab("Settings", systemImage: "gearshape") {
                Text("Settings View")
            }
        }.edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    PhotoGallery()
}

func deepClone<T: NSManagedObject>(
    _ object: T,
    into context: NSManagedObjectContext,
    cache: inout [NSManagedObjectID: NSManagedObject]
) -> T {
    if let cached = cache[object.objectID] as? T {
        return cached
    }

    // Create clone in target context
    let entityName = object.entity.name!
    let clone = NSEntityDescription.insertNewObject(
        forEntityName: entityName,
        into: context
    ) as! T

    // Copy attributes only
    for (key, _) in object.entity.attributesByName {
        clone.setValue(object.value(forKey: key), forKey: key)
    }

    // Cache before processing relationships to avoid cycles
    cache[object.objectID] = clone

    // Copy relationships
    for (key, rel) in object.entity.relationshipsByName {
        if rel.isToMany {
            let relatedSet = object.value(forKey: key) as? Set<NSManagedObject> ?? []
            var clonedSet = Set<NSManagedObject>()
            for related in relatedSet {
                let relatedClone = deepClone(related, into: context, cache: &cache)
                clonedSet.insert(relatedClone)
            }
            clone.setValue(clonedSet, forKey: key)
        } else if let related = object.value(forKey: key) as? NSManagedObject {
            let relatedClone = deepClone(related, into: context, cache: &cache)
            clone.setValue(relatedClone, forKey: key)
        }
    }

    return clone
}
