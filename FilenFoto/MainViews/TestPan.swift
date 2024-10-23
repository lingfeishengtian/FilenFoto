 import SwiftUI

 struct ImageViewer: View {
     @State var showDetails: Bool = false
    
     @State var scale: CGFloat = 1.0
     @State var offset: CGSize = .zero
    
     private func scaleAmount(for phase: ScrollTransitionPhase) -> CGFloat {
         print(phase.value)
         return 1 - (abs(phase.value) * 0.1)
     }
    
     var body: some View {
         let _ = print(showDetails)
         ScrollView {
             VStack {
                 Text("Hello")
                     .scrollTransition { content, phase in
                         print(phase)
                         return content.opacity(phase.isIdentity ? 1 : 0)
                             .offset(y: phase.isIdentity ? 0 : 400)
                     }
                     .frame(height: 200)
                     .background(Color.red)
                 ZoomablePhoto(scale: $scale, offset: $offset, onSwipeUp: {}, onSwipeDown: {}, image: .constant(UIImage(named: "IMG_3284")!))
                     .scaledToFill()
                     .scaleEffect(scale, anchor: .bottom)
                     .offset(y: offset.height)
                     .scrollTransition { content, phase in
                         return content.scaleEffect(phase.isIdentity ? 1 : 1.2, anchor: .bottom)
                     }
                 ZStack {
                     if showDetails {
                         VStack(alignment: .leading, spacing: 10) {
                             Text("More Information")
                                 .font(.title)
                                 .padding(.top)
                            
                             Text("Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.ut the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.ut the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.ut the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.ut the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.ut the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.Here is some more information about the image. You can add any details you want here.")
                                 .padding(.horizontal)
                            
                             // Add more content here as needed
                         }
                         .padding()
                     } else {
                         VStack {
                             Color.blue.frame(height: 500)
                                 .scrollTransition { content, phase in
                                     withAnimation {
                                         if phase.isIdentity {
                                             return content.opacity(1)
                                         } else {
                                             return content.opacity(0)
                                         }
                                     }
                                 }
                             Spacer()
                         }
                     }
                 }
             }.scrollTargetLayout()
         }
         .scrollTargetBehavior(ImageHalfwayScrollTargetBehavior(isShowingDetails: $showDetails))
         .ignoresSafeArea(.all)
     }
 }

 struct ImageHalfwayScrollTargetBehavior: ScrollTargetBehavior {
     @Binding var isShowingDetails: Bool
    
     func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
         let velocity = context.velocity.dy
         print(velocity)
        
 //        if target.rect.origin.y >= 50 {
 //            withAnimation {
 //                isShowingDetails = true
 //                print("Show")
 //            }
 //        } else {
 //            withAnimation {
 //                isShowingDetails = false
 //                print("Show")
 //            }
 //        }
        
         if target.rect.origin.y < 300 {
             if velocity > 0 {
                 target.rect.origin.y = 300
             } else {
                 target.rect.origin.y = 0
             }
         }
     }
 }

 struct ImageViewer_Previews: PreviewProvider {
     static var previews: some View {
         ImageViewer()
     }
 }
