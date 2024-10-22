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
//    var currentArraySlice: ArraySlice<DBPhotoAsset> {
//        if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset {
//            var endIndex = photoEnvironment.lazyArray.binSearch(selectedDbPhotoAsset) + itemsToShow
//            endIndex = endIndex < photoEnvironment.lazyArray.sortedArray.count ? endIndex : photoEnvironment.lazyArray.sortedArray.count - 1
//            var startIndex = photoEnvironment.lazyArray.binSearch(selectedDbPhotoAsset) - itemsToShow
//            startIndex = startIndex >= 0 ? startIndex : 0
//            
//            print("Indexes: \(startIndex) \(endIndex)")
//            return photoEnvironment.lazyArray.sortedArray[startIndex...endIndex]
//        }
//        return photoEnvironment.lazyArray.sortedArray[0...]
//    }
    
    init(startDbPhotoAsset: DBPhotoAsset) {
        self.startDbPhotoAsset = startDbPhotoAsset
    }
    
    func calculateSizeOfSingle(_ size: CGSize) -> CGFloat {
        (size.width - spacing * CGFloat(itemsToShow)) / CGFloat(itemsToShow)
    }
    
    var body: some View {
//        GeometryReader { geometry in
                VStack {
                    ScrollViewReader { scrollViewProxy in
                        Button {
                            scrollViewProxy.scrollTo(photoEnvironment.lazyArray.sortedArray.last?.localIdentifier)
                        } label: {
                            Text("mewo")
                        }
                        ScrollView(.horizontal, showsIndicators: true) {
                            LazyHStack(alignment: .center, spacing: spacing) {
                                ForEach(photoEnvironment.lazyArray.sortedArray, id: \.localIdentifier) { item in
                                    Image(uiImage: UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: item.thumbnailFileName).path) ?? UIImage())
                                        .resizable()
                                        .scaledToFit()
                                        .aspectRatio(1, contentMode: .fit)
                                        .clipped()
//                                    Image(uiImage: UIImage(contentsOfFile: PhotoVisionDatabaseManager.shared.thumbnailsDirectory.appending(path: item.thumbnailFileName).path) ?? UIImage())
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: calculateSizeOfSingle(geometry.size))
//                                    .background(Color.blue)
//                                    .foregroundColor(.white)
//                                    .cornerRadius(10)
//                                    .scaleEffect(photoEnvironment.selectedDbPhotoAsset == item ? scaleEffectSelected : 1.0)
//                                    .padding(.horizontal, photoEnvironment.selectedDbPhotoAsset == item ? selectedPadding : 0)
//                                    .animation(.spring, value: photoEnvironment.selectedDbPhotoAsset)
////                                    .id(item)
                                    .onTapGesture {
                                        withAnimation {
                                            photoEnvironment.selectedDbPhotoAsset = item
                                            scrollViewProxy.scrollTo(item, anchor: .center)
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
                        }
                        //.scrollTargetLayout()
                    }
                        .scrollIndicators(.visible)
//                    .safeAreaPadding(
//                        .horizontal,
//                        geometry.size.width / 2 - calculateSizeOfSingle(geometry.size) / 2
//                        - spacing
//                    )
                    .padding(.horizontal, spacing)
//                    .scrollTargetBehavior(.snap(step: calculateSizeOfSingle(geometry.size) + spacing))
                    .onAppear {
//                        scrollViewProxy.scrollTo(photoEnvironment.selectedDbPhotoAsset!, anchor: .center)
                    }
//                    .scrollPosition(
//                        id: .init(
//                            get: {
//                                photoEnvironment.selectedDbPhotoAsset
//                            },
//                            set: { value, transaction in
//                                if let value {
//                                    photoEnvironment.selectedDbPhotoAsset = value
////                                    print("Set \(photoEnvironment.lazyArray.binSearch(photoEnvironment.selectedDbPhotoAsset!))")
//                                }
//                            }
//                        )
//                    )
//                    Text("Selected item: \(selectedItem)")
                }
            }
//        }
    }
}

struct PreviewPhotoCarousel : PreviewProvider {
    static var previews: some View {
        let photoEnvironment: PhotoEnvironment = PhotoEnvironment()
        for i in 0..<100 {
            let dbPhotoAsset: DBPhotoAsset = .init(
                id: -1, localIdentifier: String(i), mediaType: .image, mediaSubtype: .photoHDR,
                creationDate: Date.now - 1_000_000, modificationDate: Date.now,
                location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
                thumbnailFileName: "meow.jpg")
            photoEnvironment.lazyArray.insert(
                dbPhotoAsset
            )
        }
        print(photoEnvironment.lazyArray.sortedArray)
        photoEnvironment.selectedDbPhotoAsset = photoEnvironment.lazyArray.sortedArray.last!
        return VStack {
            Text("Hello")
            PhotoCarousel(startDbPhotoAsset: photoEnvironment.lazyArray.sortedArray.last!)
                .environmentObject(photoEnvironment)
        }
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
