//
//  PhotoGrid.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/29/24.
//

import SwiftUI

struct LazyPhotoGrid : View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @FocusState.Binding var keyboardFocus: Bool
    let scrollViewProxy: ScrollViewProxy
    let animation: Namespace.ID
    
    private func asyncUrlImageViewGenerator(thumbnailURL: URL, cancelledErrorView: some View = Color.red) -> some View {
        AsyncImage(url: thumbnailURL) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else if phase.error != nil {
                if phase.error!.localizedDescription == "cancelled" {
                    cancelledErrorView
                } else {
                    Color.red
                }
            } else {
                ProgressView()
            }
        }
    }
    
    /// Always inline due to the way SwiftUI creates these views
    @inline(__always) private func imageOpacity(_ dbPhotoAsset: DBPhotoAsset) -> Bool {
        photoEnvironment.selectedDbPhotoAsset == dbPhotoAsset && photoEnvironment.shouldShowFullImageView == true
    }
    
    var body: some View {
        LazyVGrid(
            columns: [
                .init(.adaptive(minimum: 100, maximum: .infinity), spacing: 3)
            ], spacing: 3
        ) {
            /// Cannot use extra structs here or it was cause extreme lag
            ForEach(
                photoEnvironment.lazyArray.sortedArray, id: \.localIdentifier
            ) { dbPhotoAsset in
                Color.clear.background(
                    asyncUrlImageViewGenerator(
                        thumbnailURL: dbPhotoAsset.thumbnailURL,
                        cancelledErrorView: asyncUrlImageViewGenerator(
                            thumbnailURL:dbPhotoAsset.thumbnailURL
                        )
                    )
                )
                .contentShape(Rectangle())
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .overlay (alignment: .topLeading) {
                    if dbPhotoAsset.isBurst {
                        Image(systemName: "laser.burst")
                    }
                }
                .opacity(imageOpacity(dbPhotoAsset) ? 0 : 1)
                .onTapGesture {
                    withAnimation {
                        photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
                        photoEnvironment.shouldShowFullImageView = true
                        keyboardFocus = false
                    }
                }
                .matchedGeometryEffect(
                    id: "thumbnailImageTransition"
                    + dbPhotoAsset.localIdentifier + (photoEnvironment.shouldShowFullImageView ? ".fullImage" : ""), in: animation)
                .onAppear {
                    if dbPhotoAsset.localIdentifier == photoEnvironment.lazyArray.sortedArray.last?.localIdentifier {
                        Task {
                            await photoEnvironment.addMoreToLazyArray()
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .onChange(of: photoEnvironment.selectedDbPhotoAsset) {
            if let selected = photoEnvironment.selectedDbPhotoAsset?.localIdentifier {
                scrollViewProxy.scrollTo(selected)
            }
        }
    }
}
