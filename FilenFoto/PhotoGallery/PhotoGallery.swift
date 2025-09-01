//
//  PhotoGallery.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/31/25.
//

import SwiftUI

func imageGenerator(named name: String) -> [UIImage] {
    var images: [UIImage] = []

    for _ in 1...100 {
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

class PhotoDataSource: PhotoDataSourceProtocol {
    var photos: [UIImage] = []

    init() {
        photos = imageGenerator(named: "SampleImage")
    }

    func numberOfPhotos() -> Int {

        photos.count
    }

    func photoAt(index: Int) -> UIImage? {
        guard index >= 0 && index < photos.count else { return nil }
        return photos[index]
    }
}

struct PhotoViewProvider: SwiftUIProviderProtocol {
    func overlay(for providerRoute: SwiftUIOverlayRoute) -> any View {
        switch providerRoute {
        case .galleryView:
            VStack {
                Text("Photo Gallery")
                    .font(.largeTitle)
                    .padding()
                Spacer()
                Button("Close Gallery") {
                    print("hello")
                }
            }.background(Color.black.opacity(0.5))
        }
    }
    
    func view(for providerRoute: SwiftUIProviderRoute, with image: UIImage) -> any View {
        switch providerRoute {
        case .topBar:
            Text(image.debugDescription)
        case .bottomBar:
            Button("Test Filen") {
            }
        case .detailedImage:
            VStack {
                Text("Photo Detail View")
                    .font(.headline)
                    .padding()
                Text("Size: \(Int(image.size.width)) x \(Int(image.size.height))")
                    .font(.subheadline)
            }
        }
    }
}


struct PhotoGallery: View {
    var body: some View {
        TabView {
            Tab("Gallery", systemImage: "photo.on.rectangle.angled") {
                PhotosViewer(
                    photoDataSource: PhotoDataSource(), swiftUIProvider: PhotoViewProvider()
                ).edgesIgnoringSafeArea(.all)
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
