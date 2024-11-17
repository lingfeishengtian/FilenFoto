//
//  PagedImageView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/23/24.
//

import SwiftUI
import SwiftUIPager

struct IndexedDBPhotoAsset: Equatable, Identifiable {
    let index: Int
    let dbAsset: DBPhotoAsset
    
    var id: Int {
        index
    }
    
    static func == (lhs: IndexedDBPhotoAsset, rhs: IndexedDBPhotoAsset) -> Bool {
        lhs.index == rhs.index
    }
}

// TODO: Make this a class
private var currentElementsIndexTempStorage: [IndexedDBPhotoAsset] = []

struct PagedImageView: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
    
    let animation: Namespace.ID
    
    func swipeDownOnImage () {
        if fullImageState.showDetail || fullImageState.offset.height < 0 {
            withAnimation {
                fullImageState.showDetail = false
            }
        } else {
//            fullImageState.offset.height = fullImageState.dismissThreshold
            withAnimation(.easeInOut(duration: 0.2)) {
                photoEnvironment.shouldShowFullImageView = false
            }
        }
    }
    
    func swipeUpOnImage () {
        DispatchQueue.main.async {
            withAnimation {
                fullImageState.showDetail = true
            }
        }
    }
    
    init(animation: Namespace.ID, currentIndex: Int, globalScale: Binding<CGFloat>) {
        let startIndex = max(currentIndex - maxPageSize / 2, 0)
        
        self.animation = animation
        self._page = StateObject(wrappedValue: .withIndex(currentIndex - startIndex))
        self._globalScale = globalScale
    }
    
    @StateObject var page: Page
    @State private var location: CGPoint = .zero
    @State var localOffset: CGSize = .zero
    @State var localScale: CGFloat = 1.0
    @Binding var globalScale: CGFloat
    
    let maxPageSize = 5
    
    // TODO: Make this a separate class or struct
    var currentElementsIndexSlice: [IndexedDBPhotoAsset] {
        let startIndex = max((photoEnvironment.getCurrentPhotoAssetIndex() ?? 0) - maxPageSize / 2, 0)
        let endIndex = min(startIndex + maxPageSize, photoEnvironment.countOfPhotos)
        
        if currentElementsIndexTempStorage.count != maxPageSize || currentElementsIndexTempStorage.first?.index != startIndex || currentElementsIndexTempStorage.last?.index != endIndex {
            currentElementsIndexTempStorage = []
            
            for i in startIndex..<endIndex {
                currentElementsIndexTempStorage.append(IndexedDBPhotoAsset(index: i, dbAsset: PhotoDatabase.shared.getDBPhotoSync(atOffset: i)!))
            }
        }
        
        return currentElementsIndexTempStorage
    }
    
    func convertToLocalIndex(currentIndex: Int) -> Int {
        let startIndex = max(currentIndex - maxPageSize / 2, 0)
        
        return currentIndex - startIndex
    }
    
    func convertToCurrentIndex(localIndex: Int) -> Int {
        let startIndex = max((photoEnvironment.getCurrentPhotoAssetIndex() ?? 0) - maxPageSize / 2, 0)
        
        return startIndex + localIndex
    }
    
    var isScrolling: Bool {
        fullImageState.scrolling || localOffset != .zero
    }
    
    enum DragState {
        case inactive
        case beginSwipeUp
    }
    
    @GestureState private var dragState: DragState = .inactive

    var body: some View {
        GeometryReader { reader in
            Pager(page: self.page,
//                  data: 0..<photoEnvironment.countOfPhotos,
                  data: currentElementsIndexSlice) { indexedDBPhotoAsset in
//                let dbAsset = PhotoDatabase.shared.getDBPhotoSync(
//                    atOffset: index
//                )!
                let index = indexedDBPhotoAsset.index
                let dbAsset = indexedDBPhotoAsset.dbAsset
                if index == photoEnvironment.getCurrentPhotoAssetIndex() {
                    FilenAsyncImage(dbAsset: photoEnvironment.selectedDbPhotoAsset, onSwipeUp: swipeUpOnImage, onSwipeDown: swipeDownOnImage)
//                    Image(uiImage: UIImage(contentsOfFile: dbAsset.thumbnailURL.path) ?? UIImage())
                        .matchedGeometryEffect(
                            id: "thumbnailImageTransition"
                            + dbAsset.localIdentifier,
                            in: animation
                        )
                        .offset(localOffset)
                        .scaleEffect(localScale)
                        .gesture(
                            DragGesture()
                                .updating($dragState) { value, state, _ in
                                    switch state {
                                    case .inactive:
                                        if abs(value.translation.height) > abs(value.translation.width) {
                                            state = .beginSwipeUp
                                            withAnimation {
                                                globalScale = 2.0
                                            }
                                        }
                                    case .beginSwipeUp:
//                                        withAnimation {
                                            localOffset = value.translation
                                            localScale = 1.0 - min(max(localOffset.height / 800, 0), 1)
//                                        }
                                    }
                                }
                                .onEnded { value in
                                    if localOffset.height > 100 {
                                        swipeDownOnImage()
                                    } else if localOffset.height < -100 {
                                        swipeUpOnImage()
                                    } else {
                                        withAnimation {
                                            localScale = 1.0
                                            globalScale = 1.0
                                            localOffset = .zero
                                        }
                                    }
                                }
                        )
//                    .frame(width: reader.size.width, height: reader.size.height)
                } else {
                    ZoomablePhoto(
//                        scale: $fullImageState.scale,
//                        offset: $fullImageState.offset,
//                        scrolling: $fullImageState.scrolling,
                        onSwipeUp: swipeUpOnImage,
                        onSwipeDown: swipeDownOnImage,
                        image: (UIImage(contentsOfFile: dbAsset.thumbnailURL.path) ?? UIImage()))
//                    .frame(width: reader.size.width, height: reader.size.height)
                }
            }
            .onPageChanged({ (newLocalIndex) in
                let newIndex = convertToCurrentIndex(localIndex: newLocalIndex)
                photoEnvironment.setCurrentSelectedDbPhotoAsset(PhotoDatabase.shared.getDBPhotoSync(
                    atOffset: newIndex
                )!, index: newIndex, animate: false)
//                page.index = convertToLocalIndex(currentIndex: newIndex)
                Task {
                    await fullImageState.getView(selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset!)
                }
            })
            .sensitivity(.low)
            .preferredItemSize(.init(width: reader.size.width, height: reader.size.height))
            .interactive(scale: 0.8)
            .allowsDragging(!isScrolling)
            .pagingPriority(.simultaneous)
//            .onAppear {
//                page.index = convertToLocalIndex(currentIndex: photoEnvironment.getCurrentPhotoAssetIndex() ?? 0)
//            }
        .onChange(of: photoEnvironment.getCurrentPhotoAssetIndex()) {
            if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset, let ind = photoEnvironment.getCurrentPhotoAssetIndex() {
                self.page.update(.new(index: convertToLocalIndex(currentIndex: ind)))
            }
        }
        }
    }
}

extension PagedImageView {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
