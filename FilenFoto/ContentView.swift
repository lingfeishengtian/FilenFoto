//
//  ContentView.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
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
    func view(for providerRoute: SwiftUIProviderRoute, with image: UIImage) -> any View {
        switch providerRoute {
        case .topBar:
            Text("Photo Detail View")
        case .bottomBar:
            Text("Test")
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

struct ContentView: View {
    var body: some View {
        VStack {
            PhotosViewer(
                photoDataSource: PhotoDataSource(), swiftUIProvider: PhotoViewProvider()
            )
        }.edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
