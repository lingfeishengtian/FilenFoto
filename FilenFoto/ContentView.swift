//
//  ContentView.swift
//  FilenFoto
//
//  Created by Hunter Han on 8/23/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var photoContext: PhotoContext

    var body: some View {
        ZStack {
            switch (photoContext.filenClient, photoContext.rootPhotoDirectory) {
            case (nil, nil):
                LoginView()
            case (_, nil):
                RootDirSelection()
            case (_, _):
                PhotoGallery()
            }
            
            ErrorMessages()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PhotoContext())
}
