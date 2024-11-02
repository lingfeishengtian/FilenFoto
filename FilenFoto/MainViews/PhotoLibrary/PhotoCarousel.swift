//
//  PhotoCarousel.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/1/24.
//

import SwiftUI
import CoreLocation

struct PhotoCarousel: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    //    @State private var selectedItem: Int = 0  // Index of the selected item
    let itemsToShow = 10
    let spacing: CGFloat = 5
    let selectedPadding: CGFloat = 10
    let scaleEffectSelected: CGFloat = 1.8
    private var finishScrollTo: Bool = false
    
    let geometry = (size: CGSize(width: 400, height: 1000), test: 0)
    let startDbPhotoAsset: DBPhotoAsset
    
    init(startDbPhotoAsset: DBPhotoAsset) {
        self.startDbPhotoAsset = startDbPhotoAsset
    }
    
    func calculateSizeOfSingle(_ size: CGSize) -> CGFloat {
        (size.width - spacing * CGFloat(itemsToShow)) / CGFloat(itemsToShow)
    }
    
    @State var scrollPosition: ScrollPosition = .init()
    
    var body: some View {
        let _ = print(scrollPosition)
        //        GeometryReader { geometry in
        ScrollViewReader { scrollViewProxy in
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .center, spacing: spacing) {
                        ForEach(0..<photoEnvironment.countOfPhotos, id: \.self) { index in
                            let dbPhotoAsset = PhotoDatabase.shared.getDBPhotoSync(
                                atOffset: index
                            )!
                            Color.clear.background(
                                Image(
                                    uiImage: UIImage(contentsOfFile: dbPhotoAsset.thumbnailURL.path) ?? UIImage()
                                )
                                .resizable()
                                .scaledToFill()
                                .clipped()
                            )
                            .id(index)
                            .frame(width: calculateSizeOfSingle(geometry.size))
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .scaleEffect(photoEnvironment.getCurrentPhotoAssetIndex() == index ? scaleEffectSelected : 1.0)
                            .padding(.horizontal, photoEnvironment.getCurrentPhotoAssetIndex() == index ? selectedPadding : 0)
                            .animation(.spring, value: photoEnvironment.selectedDbPhotoAsset)
                            .onTapGesture {
                                withAnimation {
                                    photoEnvironment.setCurrentSelectedDbPhotoAsset(dbPhotoAsset, index: index)
//                                    scrollViewProxy.scrollTo(item.localIdentifier, anchor: .center)
                                }
                            }
                            //                                    .scrollTransition(
                            //                                        axis: .horizontal,
                            //                                        transition: { content, phase in
                            //                                            content
                            //                                                .opacity(phase == .topLeading || phase == .bottomTrailing ? 0.4 : 1.0)
                            //                                        }
                            //                                    )
                        }
                    }.scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .safeAreaPadding(
                    .horizontal,
                    geometry.size.width / 2 - calculateSizeOfSingle(geometry.size) / 2
                    - spacing
                )
                .padding(.horizontal, spacing)
                .scrollTargetBehavior(.snap(step: calculateSizeOfSingle(geometry.size) + spacing))
                .onAppear {
                    scrollPosition.scrollTo(x: CGFloat(photoEnvironment.getCurrentPhotoAssetIndex() ?? 0) * calculateSizeOfSingle(geometry.size))
                    //                        scrollViewProxy.scrollTo(photoEnvironment.selectedDbPhotoAsset, anchor: .center)
                }
                .scrollPosition($scrollPosition)
//                .scrollPosition(.init(get: {
//                    .init(x: )
//                }, set: { value, transaction in
//                    print(value)
//                    print(value.edge)
//                    print(value.point)
//                    print(value.viewID(type: Int.self))
//                    //                        let index = Int(value / (calculateSizeOfSingle(geometry.size) + spacing))
//                    //                        photoEnvironment.setCurrentSelectedDbPhotoAsset(PhotoDatabase.shared.getDBPhotoSync(atOffset: index)!, index: index)
//                }))
//                .scrollPosition(
//                    id: .init(
//                        get: {
//                            photoEnvironment.getCurrentPhotoAssetIndex() ?? 0
//                        },
//                        set: { value, transaction in
//                            if let value {
//                                photoEnvironment.setCurrentSelectedDbPhotoAsset(PhotoDatabase.shared.getDBPhotoSync(atOffset: value)!, index: value)
////                                print("Set \()")
//                            }
//                        }
//                    )
//                )
                //                    Text("Selected item: \(selectedItem)")
            }
        }
        //        }
    }
}

//#Preview {
//    @Previewable @Namespace var animation
//    var photoEnvironment: PhotoEnvironment = PhotoEnvironment()
//    for i in 0..<100 {
//        let dbPhotoAsset: DBPhotoAsset = .init(
//            id: -1, localIdentifier: String(i), mediaType: .image, mediaSubtype: .photoHDR,
//            creationDate: Date.now - 1_000_000, modificationDate: Date.now,
//            location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
//            thumbnailFileName: "meow.jpg")
//        photoEnvironment.lazyArray.insert(
//            dbPhotoAsset
//        )
//    }
//    print(photoEnvironment.lazyArray.sortedArray)
//    VStack {
//        Text("Hello")
//        PhotoCarousel(startDbPhotoAsset: photoEnvironment.lazyArray.sortedArray.first)
//            .environmentObject(photoEnvironment)
//    }
//}

// MARK: - Scroll Behavior

/// A structure that defines a snapping behavior for scroll targets, conforming to `ScrollTargetBehavior`.
struct SnapScrollTargetBehavior: ScrollTargetBehavior {
    /// The step value to which the scroll target should snap.
    let step: Double
    
    /// Computes the closest multiple of `b` to the given value `a`.
    /// - Parameters:
    ///   - a: The value to snap.
    ///   - b: The step to which `a` should snap.
    /// - Returns: The closest multiple of `b` to `a`.
    private func closestMultiple(
        a: Double,
        b: Double
    ) -> Double {
        let lowerMultiple = floor((a / b)) * b
        let upperMultiple = floor(lowerMultiple + b)
        
        return if abs(a - lowerMultiple) <= abs(a - upperMultiple) {
            lowerMultiple
        } else {
            upperMultiple
        }
    }
    
    func updateTarget(
        _ target: inout ScrollTarget,
        context: TargetContext
    ) {
        let x1 = target.rect.origin.x
        let x2 = closestMultiple(a: x1, b: step)
        
        target.rect.origin.x = x2
    }
}

extension ScrollTargetBehavior where Self == SnapScrollTargetBehavior {
    /// Creates a `SnapScrollTargetBehavior` with the specified step.
    /// - Parameter step: The step value to which the scroll target should snap.
    /// - Returns: A `SnapScrollTargetBehavior` instance with the given step value.
    static func snap(step: Double) -> SnapScrollTargetBehavior { .init(step: step) }
}
