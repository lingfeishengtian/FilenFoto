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
        if fullImageState.showDetail {
            withAnimation {
                fullImageState.showDetail = false
            }
        } else {
//            fullImageState.offset.height = fullImageState.dismissThreshold
            withAnimation(.easeInOut(duration: 0.2)) {
                photoEnvironment.clearSelectedDbPhotoAsset()
            }
        }
    }
    
    func swipeUpOnImage () {
        withAnimation {
            fullImageState.showDetail = true
        }
    }
    
    init(animation: Namespace.ID, currentIndex: Int, globalScale: Binding<CGFloat>, localOffset: Binding<CGSize>) {
        let startIndex = max(currentIndex - maxPageSize / 2, 0)
        
        self.animation = animation
        self._page = StateObject(wrappedValue: .withIndex(currentIndex - startIndex))
        self._globalScale = globalScale
        self._localOffset = localOffset
    }
    
    @StateObject var page: Page
    @State private var location: CGPoint = .zero
    @Binding var localOffset: CGSize
    @State var localScale: CGFloat = 1.0
    @Binding var globalScale: CGFloat
    
    let maxPageSize = 3
    
    // TODO: Make this a separate class or struct
    var currentElementsIndexSlice: [IndexedDBPhotoAsset] {
        let startIndex = max((photoEnvironment.getCurrentPhotoAssetIndex() ?? photoEnvironment.preservedDbPhotoAssetIndex) - maxPageSize / 2, 0)
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
        let startIndex = max((photoEnvironment.getCurrentPhotoAssetIndex() ?? photoEnvironment.preservedDbPhotoAssetIndex) - maxPageSize / 2, 0)
        
        return startIndex + localIndex
    }
    
    var isScrolling: Bool {
        fullImageState.isPinching || localOffset != .zero || startedVerticalDrag
    }
    
    enum DragState {
        case inactive
        case dragHorizontal
        case isPinching
        case beginSwipeUp
        case beginSwipeDown
        case beginSwipeDetailsScreen(originalOffset: CGSize)
    }
    
    @State var startedVerticalDrag: Bool = false
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
                if index == photoEnvironment.getCurrentPhotoAssetIndex() ?? photoEnvironment.preservedDbPhotoAssetIndex {
                    FilenAsyncImage(dbAsset: dbAsset, onSwipeUp: swipeUpOnImage, onSwipeDown: swipeDownOnImage)
//                    Image(uiImage: UIImage(contentsOfFile: dbAsset.thumbnailURL.path) ?? UIImage())
                        .matchedGeometryEffect(
                            id: "thumbnailImageTransition"
                            + String(dbAsset.id),
                            in: animation
                        )
                        .offset(localOffset)
                        .scaleEffect(localScale)
                        .modifier(InlineSheetProgressModifier(progress: (-localOffset.height) / reader.size.height) {
                            PhotoDetails(currentDbPhotoAsset: dbAsset, animation: animation)
                        })
                        .gesture(
                            DragGesture()
                                .updating($dragState) { value, state, transaction in
                                    switch state {
                                    case .inactive:
                                        if fullImageState.isPinching {
                                            state = .isPinching
                                        } else if abs(value.translation.height) > abs(value.translation.width) {
                                            if fullImageState.showDetail {
                                                state = .beginSwipeDetailsScreen(originalOffset: localOffset)
                                            } else if value.translation.height > 0 {
                                                state = .beginSwipeDown
                                                
                                                withAnimation {
                                                    globalScale = 2.0
                                                }
                                            } else {
                                                state = .beginSwipeUp
                                            }
                                            
                                            startedVerticalDrag = true
                                        } else {
                                            state = .dragHorizontal
                                        }
                                    case .beginSwipeUp:
                                        withAnimation {
                                            localOffset = .init(width: 0, height: value.translation.height)
                                        }
                                    case .beginSwipeDown:
                                        localOffset = value.translation
                                        localScale = 1.0 - min(max(localOffset.height / 800, 0), 1)
                                    case .beginSwipeDetailsScreen(let originalOffset):
                                        localOffset = .init(width: originalOffset.width, height: originalOffset.height + value.translation.height)
                                    case .dragHorizontal, .isPinching:
                                        break
                                    }
                                }
                                .onEnded { value in
                                    if !startedVerticalDrag {
                                        return
                                    }
                                    
                                    if value.translation.height > 100 {
                                        if fullImageState.showDetail {
                                            withAnimation {
                                                fullImageState.showDetail = false
                                                localOffset = .zero
                                                globalScale = 1.0
                                            }
                                        } else {
                                            swipeDownOnImage()
                                        }
                                    } else if value.translation.height < -100 {
                                        swipeUpOnImage()
                                    } else {
                                        if !fullImageState.showDetail {
                                            withAnimation {
                                                localScale = 1.0
                                                globalScale = 1.0
                                                localOffset = .zero
                                            }
                                        }
                                    }
                                    
                                    startedVerticalDrag = false
                                }
                        )
//                    .frame(width: reader.size.width, height: reader.size.height)
                } else {
                    ZoomableImage(
                        isPinching: $fullImageState.isPinching,
                        imageURL: dbAsset.thumbnailURL)
                    .offset(localOffset)
                    .scaleEffect(localScale)
                    .modifier(InlineSheetProgressModifier(progress: (-localOffset.height) / reader.size.height) {
                        PhotoDetails(currentDbPhotoAsset: dbAsset, animation: animation)
                    })
//                    .frame(width: reader.size.width, height: reader.size.height)
                }
            }
            .onPageChanged({ (newLocalIndex) in
                let newIndex = convertToCurrentIndex(localIndex: newLocalIndex)
                photoEnvironment.setCurrentSelectedDbPhotoAsset(PhotoDatabase.shared.getDBPhotoSync(
                    atOffset: newIndex
                )!, index: newIndex, animate: false)
                Task {
                    await fullImageState.getView(selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset!)
                }
            })
            .sensitivity(.low)
            .preferredItemSize(.init(width: reader.size.width, height: reader.size.height))
            .interactive(scale: 0.8)
            .allowsDragging(!isScrolling || fullImageState.showDetail)
            .pagingPriority(.simultaneous)
            .onChange(of: photoEnvironment.getCurrentPhotoAssetIndex()) {
                if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset, let ind = photoEnvironment.getCurrentPhotoAssetIndex() {
                    self.page.update(.new(index: convertToLocalIndex(currentIndex: ind)))
                }
            }
            .ignoresSafeArea(.all)
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
