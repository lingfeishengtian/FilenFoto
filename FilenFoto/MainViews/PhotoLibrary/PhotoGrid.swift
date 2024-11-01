//
//  PhotoGrid.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/29/24.
//

import SwiftUI

var shouldAppear: [Int: Bool] = [:]

struct LazyPhotoGrid : View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @FocusState.Binding var keyboardFocus: Bool
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
            ForEach(
                0..<PhotoDatabase.shared.getCountOfPhotos(),
                id: \.self
            ) { index in
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
                        photoEnvironment.setCurrentSelectedDbPhotoAsset(dbPhotoAsset, index: index)
                        photoEnvironment.shouldShowFullImageView = true
                        keyboardFocus = false
                    }
                }
                .matchedGeometryEffect(
                    id: "thumbnailImageTransition"
                    + dbPhotoAsset.localIdentifier + (
                        photoEnvironment.shouldShowFullImageView ? ".fullImage" : ""
                    ),
                    in: animation
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

struct DBImage : View {
    let index: Int
    @State var dbPhotoAsset: DBPhotoAsset? = nil
    
    @State var curTask: Task<Void, Never>? = nil
    
    var body: some View {
        let thumbnailUrl = dbPhotoAsset?.thumbnailURL
        return Color.clear.background(
            (
thumbnailUrl != nil ?
Image(
    uiImage: UIImage(contentsOfFile: thumbnailUrl!.path) ?? UIImage()
) :
    Image(uiImage: UIImage())
            )
            .resizable()
            .scaledToFill()
            .clipped()
        )
        .contentShape(Rectangle())
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .onAppear {
            //            curTask = Task {
            //                print("getting \(index)")
            //                dbPhotoAsset = PhotoDatabase.shared.getDBPhoto(atOffset: index)
            //            }
        }
        .onDisappear {
            print("cancelling \(index)")
            curTask?.cancel()
            curTask = nil
        }
        //        .overlay (alignment: .topLeading) {
        //            if dbPhotoAsset.isBurst {
        //                Image(systemName: "laser.burst")
        //            }
        //        }
        //        .opacity(imageOpacity(dbPhotoAsset) ? 0 : 1)
        //        .onTapGesture {
        //            withAnimation {
        //                photoEnvironment.selectedDbPhotoAsset = dbPhotoAsset
        //                photoEnvironment.shouldShowFullImageView = true
        //                keyboardFocus = false
        //            }
        //        }
        //        .matchedGeometryEffect(
        //            id: "thumbnailImageTransition"
        //            + dbPhotoAsset.localIdentifier + (photoEnvironment.shouldShowFullImageView ? ".fullImage" : ""), in: animation)
        //        .onAppear {
        //            if dbPhotoAsset.localIdentifier == photoEnvironment.lazyArray.sortedArray.last?.localIdentifier {
        //                Task {
        //                    await photoEnvironment.addMoreToLazyArray()
        //                }
        //            }
        //        }
    }
}
