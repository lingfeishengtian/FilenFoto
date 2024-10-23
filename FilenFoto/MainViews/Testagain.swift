//import SwiftUI
//
//struct ImageViewer: View {
//    @State private var showDetails: Bool = false
//    @State private var sheetHeight: CGFloat = 300
//    @State private var scale: CGFloat = 1.0
//    @State private var offset: CGSize = .zero
//    
//    var body: some View {
//        ScrollView {
//            VStack {
//                GeometryReader { geometry in
//                    VStack {
//                        ZoomablePhoto(scale: $scale, offset: $offset, onSwipeUp: {}, onSwipeDown: {}, image: .constant(UIImage(named: "IMG_3284")!))
//                            .scaledToFill()
//                            .scaleEffect(scale, anchor: .bottom)
//                            .offset(y: offset.height - (sheetHeight - 300))
//                            .scrollTransition { content, phase in
//                                content.scaleEffect(phase.isIdentity ? 1 : 1.2, anchor: .bottom)
//                            }
//                        
//                        Text("Header Info")
//                            .font(.largeTitle)
//                            .padding()
//                            .background(Color.white)
//                            .cornerRadius(10)
//                            .shadow(radius: 5)
//                            .opacity(Double(-geometry.frame(in: .global).minY / 100))
//                    }
//                    .onChange(of: geometry.frame(in: .global).minY) { newValue in
//                        if newValue < 0 {
//                            sheetHeight = 300 + abs(newValue)
//                            showDetails = true
//                        } else {
//                            sheetHeight = 300
//                            showDetails = false
//                        }
//                    }
//                }
//                .frame(height: 300)
//                
//                Button(action: {
//                    showDetails.toggle()
//                }) {
//                    Text("Show Details")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                }
//                .padding()
//            }
//            .scrollTargetLayout()
//        }
//        .scrollTargetBehavior(ImageHalfwayScrollTargetBehavior())
//        .ignoresSafeArea(.all)
//        .sheet(isPresented: .constant(true)) {
//            DetailView(sheetHeight: $sheetHeight)
//                .presentationDetents([.height(sheetHeight)])
//                .presentationBackgroundInteraction(.enabled(upThrough: .height(sheetHeight)))
//        }
//    }
//}
//
//struct DetailView: View {
//    @Binding var sheetHeight: CGFloat
//    @State private var dragOffset: CGFloat = 0
//    
//    var body: some View {
//        GeometryReader { geometry in
//            VStack(alignment: .leading, spacing: 10) {
//                Text("More Information")
//                    .font(.title)
//                    .padding(.top)
//                
//                Text("Here is some more information about the image. You can add any details you want here.")
//                    .padding(.horizontal)
//                
//                // Add more content here as needed
//            }
//            .padding()
//            .background(Color.white)
//            .cornerRadius(10)
//            .shadow(radius: 5)
//            .offset(y: dragOffset)
//            .gesture(
//                DragGesture()
//                    .onChanged { value in
//                        dragOffset = value.translation.height
//                        sheetHeight = geometry.size.height - dragOffset
//                    }
//                    .onEnded { _ in
//                        dragOffset = 0
//                    }
//            )
//            .onChange(of: geometry.frame(in: .global).height) { newHeight in
//                sheetHeight = newHeight
//            }
//        }
//    }
//}
//
//struct ImageHalfwayScrollTargetBehavior: ScrollTargetBehavior {
//    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
//        let velocity = context.velocity.dy
//        
//        if target.rect.origin.y < 300 {
//            if velocity > 0 {
//                target.rect.origin.y = 300
//            } else {
//                target.rect.origin.y = 0
//            }
//        }
//    }
//}
//
//struct ImageViewer_Previews: PreviewProvider {
//    static var previews: some View {
//        ImageViewer()
//    }
//}
