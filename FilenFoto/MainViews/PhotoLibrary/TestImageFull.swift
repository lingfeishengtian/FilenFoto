//
//  TestImageFull.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/16/24.
//

import SwiftUI

struct TestImageFull: View {
    let dbAsset: DBPhotoAsset
    let animation: Namespace.ID
    @Binding var shouldShowFullImageView: Bool
    enum DragState {
        case inactive
        case beginSwipeUp
    }
    
    @GestureState private var dragState: DragState = .inactive
    
    @State var localOffset: CGSize = .zero
    @State var localScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { reader in
            
            Image(uiImage: UIImage(contentsOfFile: dbAsset.thumbnailURL.path) ?? UIImage())
                .resizable()
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
                                }
                            case .beginSwipeUp:
                                localOffset = value.translation
                                localScale = 1.0 - min(max(localOffset.height / 800, 0.5), 1)
                            }
                        }
                        .onEnded { value in
                            if localOffset.height > 100 {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    shouldShowFullImageView = false
                                }
                            } else {
                                withAnimation {
                                    localScale = 1.0
                                    localOffset = .zero
                                }
                            }
                        }
                )
        }
    }
}
