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
    
    func photo(for photoId: FotoAsset) -> UIImage? {
        ThumbnailProvider.shared.thumbnail(for: photoId)
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
    @Environment(\.managedObjectContext) var viewContext

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
                                .padding()
                            Spacer()

                        }
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
