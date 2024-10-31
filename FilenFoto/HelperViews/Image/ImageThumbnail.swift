//
//  ImageThumbnail.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/28/24.
//

import SwiftUI

struct ImageThumbnail : View {
//    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    let dbAsset: DBPhotoAsset
    @State var didAppear: Bool = false
    
    var body: some View {
        Color.clear.background{
            if didAppear {
                Image(uiImage: UIImage(contentsOfFile: dbAsset.thumbnailURL.path) ?? UIImage())
                    .resizable()
                    .scaledToFill()
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                didAppear = true
                print("Appear")
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                didAppear = false
                print("Dissapear")
            }
        }
        .contentShape(Rectangle())
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .overlay (alignment: .topLeading) {
            if dbAsset.isBurst {
                Image(systemName: "laser.burst")
            }
        }
    }
}
