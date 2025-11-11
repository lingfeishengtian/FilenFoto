//
//  PhotoGallery.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import CoreData
import SwiftUI

struct PhotoDataSource: PhotoDataSourceProtocol {
    let managedObjectContext: NSManagedObjectContext

    func fetchRequestController() -> NSFetchedResultsController<FotoAsset> {
        let fetchRequest = FotoAsset.fetchRequest()
        fetchRequest.sortDescriptors = [
            .init(keyPath: \FotoAsset.dateCreated, ascending: false)
        ]

        let controller = NSFetchedResultsController(
            fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }

    func thumbnail(for photoId: FotoAsset) -> UIImage? {
        ThumbnailProvider.shared.thumbnail(for: photoId)
    }

    func photo(for photoId: FotoAsset) -> FFDisplayableImage? {
        let workingSetFotoAsset = FFWorkingSet.default.requestWorkingSet(for: photoId)
        let displayableImage = FFImage(workingAsset: workingSetFotoAsset, thumbnail: thumbnail(for: photoId))
        return displayableImage
    }
}

struct PhotoViewProvider: SwiftUIProviderProtocol {
    func topBar(with image: WorkingSetFotoAsset) -> any View {
        Text(image.asset.debugDescription)
    }

    func bottomBar(with image: WorkingSetFotoAsset) -> any View {
        Button("Test Filen") {
        }
    }

    func detailedView(for image: WorkingSetFotoAsset) -> any View {
        VStack {
            Text("Photo Detail View")
                .font(.headline)
                .padding()
        }
    }

    func noImagesAvailableView() -> any View {
        VStack {
            Image(systemName: "photo.trianglebadge.exclamationmark")
                .font(.title)
                .padding()
                .symbolRenderingMode(.multicolor)
                .symbolEffect(.breathe)
            Text("Your library is empty")
                .bold()
        }
    }
}

let testPath = FileManager.default.documentsDirectory.appendingPathComponent("Test")

struct PhotoGallery: View {
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var photoContext: PhotoContext
    @StateObject private var syncController: PhotoSyncController = .shared

    var body: some View {
        TabView {
            Tab("Gallery", systemImage: "photo.on.rectangle.angled") {
                ZStack {
                    PhotosViewer(
                        photoDataSource: PhotoDataSource(managedObjectContext: viewContext),
                        swiftUIProvider: PhotoViewProvider()
                    )

                    VStack {
                        HStack {
                            Text("Library")
                                .font(.largeTitle)
                                .bold()
                            Spacer()
                            ProgressView(value: syncController.progress.fractionCompleted) {
                                Text("Syncing Photos...")
                            }.padding()
                        }.padding()
                        
                        Spacer()
                    }
                }
                .ignoresSafeArea(edges: .bottom)
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
        }
    }
}

#Preview {
    PhotoGallery()
        .environmentObject(PhotoContext.shared)
        .environment(\.managedObjectContext, FFCoreDataManager.shared.mainContext)
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
    let clone =
        NSEntityDescription.insertNewObject(
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
