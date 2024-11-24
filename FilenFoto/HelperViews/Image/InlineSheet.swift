//
//  InlineSheet.swift
//  FilenFoto
//
//  Created by Hunter Han on 11/18/24.
//

import SwiftUI

private struct DynamicParameters: Equatable {
    var translation: Double = 0
    var delta: Double = 0
}

struct InlineSheetProgressModifier<C: View>: ViewModifier {
    let progress: Double
    let content: () -> C
    let shouldShow: Bool
    
    init(progress: Double, shouldShow: Bool = false, content: @escaping () -> C) {
        self.progress = progress
        self.content = content
        self.shouldShow = shouldShow
    }
    
    func calculateSheetOffset(screenReader: GeometryProxy, reader: GeometryProxy) -> CGFloat {
        if shouldShow {
            let minimumOffset = reader.size.height
            let offsetAffectedByProgress = screenReader.size.height - minimumOffset
            
            print(minimumOffset, offsetAffectedByProgress)
            if offsetAffectedByProgress < 0 {
                return reader.size.height
            } else {
                return min(minimumOffset, (1 - progress) * screenReader.size.height -  offsetAffectedByProgress * (1 - progress))
            }
        } else {
            return screenReader.size.height
        }
    }
    
    func body(content: Content) -> some View {
        let _ = print("Progress: \(progress)")
        GeometryReader { screenReader in
            content
                .scaleEffect(1 + progress / 1.5)
                .overlay {
                    GeometryReader { reader in
                        Color.primary.overlay {
                            VStack {
                                self.content()
                            }
                        }
                        .frame(width: reader.size.width, height: reader.size.height)
                        .offset(y: calculateSheetOffset(screenReader: screenReader, reader: reader))
                    }
                }
        }.ignoresSafeArea(.all)
    }
}


enum DragState {
    case inactive
    case beginSwipeUp
    case beginSwipeDown
}

private struct InlineSheetModifier<C: View>: ViewModifier {
    private let contentBuilder: () -> C
    @Binding var isPresented: Bool
    @State private var progress: Double = 0
    @GestureState private var dynamics: DynamicParameters = .init()
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> C) {
        self.contentBuilder = content
        _isPresented = isPresented
    }
    
    func body(content: Content) -> some View {
        content
            .modifier(InlineSheetProgressModifier(progress: progress, shouldShow: progress > 0, content: contentBuilder))
            .onChange(of: isPresented) { value in
                withAnimation(.easeInOut) {
                    progress = value ? 1 : 0
                }
            }
            .onChange(of: dynamics) {
                if $0.delta == 0 {
                    return
                }
                
                let candidate = progress - $0.delta / UIScreen.main.bounds.height
                if candidate > 0, candidate < 1 {
                    var transaction = Transaction()
                    transaction.isContinuous = true
                    transaction.animation = .interpolatingSpring(stiffness: 30, damping: 20)
                    withTransaction(transaction) {
                        progress = candidate
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dynamics) { value, state, _ in
                        state.delta = value.translation.height
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            print("Edned prog: \(progress)")
                            if progress < 0.7 {
                                isPresented = false
                                progress = 0
                            }
                            else {
                                isPresented = true
                                progress = 1
                            }
                        }
                    }
            )
    }
}

extension View {
    func inlineSheet<V: View>(isPresented: Binding<Bool>,
                              @ViewBuilder content: @escaping () -> V) -> some View
    {
        modifier(InlineSheetModifier(isPresented: isPresented, content: content))
    }
}

#Preview {
    VStack {
        Image("IMG_3284")
            .resizable()
    }.inlineSheet(isPresented: .constant(true)) {
        Text("Sheet Content")
            .background(Color.red)
        Spacer()
    }
}

