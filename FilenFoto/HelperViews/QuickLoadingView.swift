//
//  QuickLoadingView.swift
//  FilenFoto
//
//  Created by Hunter Han on 10/14/24.
//

import SwiftUI

struct QuickLoadingView<Content : View> : View {
    let content: Content
    let isLoading: Bool
    
    init(isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isLoading = isLoading
    }
    
    var body: some View {
        ZStack {
            content
            // Overlay with ProgressView
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.8)))
            }
        }
    }
}
