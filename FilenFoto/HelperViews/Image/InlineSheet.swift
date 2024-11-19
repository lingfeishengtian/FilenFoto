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
    
    func body(content: Content) -> some View {
        let _ = print("Progress: \(progress)")
        GeometryReader { reader in
            ZStack {
                content
                    .scaleEffect(1 + progress / 2)
                    .clipped()
                    .contentShape(Rectangle())
                    .frame(width: reader.size.width, height: reader.size.height)
                    .ignoresSafeArea(.all)
                Color.primary.overlay {
                    VStack {
                        self.content()
                    }
                }
                .frame(width: reader.size.width, height: reader.size.height)
                .offset(y: (1 - progress) * reader.size.height)
            }
        }
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
            .modifier(InlineSheetProgressModifier(progress: progress, content: contentBuilder))
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

