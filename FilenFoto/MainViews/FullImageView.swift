//import SwiftUI
//import CoreLocation
//import MapKit
//
// struct FullImageView: View {
//     @EnvironmentObject var photoEnvironment: PhotoEnvironment
//
//     @State private var currentDbPhotoAsset: DBPhotoAsset
//
//     @State private var scale: CGFloat = 1.0
//     @State private var offset: CGSize = .zero
//     @State private var sheetOffset: CGSize = .zero
//     @State private var isDragging = false
//     @State private var dismissThreshold: CGFloat = 200
//     @State private var isScrolling = true
//    
//     @State private var assetFileUrl: URL?
//     @State private var showDeleteAlert: Bool = false
//     @State private var showDetail: Bool = true
//
//     let formatter = RelativeDateTimeFormatter()
//
//     let animation: Namespace.ID
//
//     init(currentDbPhotoAsset: DBPhotoAsset, animation: Namespace.ID) {
//         self.currentDbPhotoAsset = currentDbPhotoAsset
//         self.animation = animation
//         formatter.unitsStyle = .full
//         formatter.locale = Locale(identifier: "ja_JP")
//     }
//
//     var body: some View {
////         let showDetail = offset.height < 0
//         VStack {
//             VStack {
//                 if !showDetail {
//                     HStack {
//                         Text(
//                            formatter.localizedString(
//                                for: currentDbPhotoAsset.creationDate, relativeTo: Date.now)
//                         )
//                         .font(.largeTitle)
//                         .foregroundStyle(.white)
//                         Spacer()
//                         Button {
//                             withAnimation {
//                                 photoEnvironment.selectedDbPhotoAsset = nil
//                             }
//                         } label: {
//                             IconView(size: .small, iconSystemName: "xmark")
//                         }
//                     }.padding([.leading, .trailing], 30)
//                     Spacer()
//                 }
//                 //             ScrollView {
//                 VStack {
//                     //                     ZoomablePhoto(scale: $scale, offset: $offset, onSwipeUp: {}, onSwipeDown: {}, image: .constant(UIImage(named: "IMG_3284")!))
//                     //                         .scaledToFill()
//                     //                         .scaleEffect(scale, anchor: .bottom)
//                     //                         .offset(y: offset.height)
//                     //                         .scrollTransition { content, phase in
//                     //                             return content.scaleEffect(phase.isIdentity ? 1 : 1.2, anchor: .bottom)
//                     //                         }
//                     ViewManager(
//                        scale: $scale, offset: $offset, onSwipeUp: {
//                            //                     withAnimation {
//                            //                         offset.height = 60
//                            //                     }
//                        }, isScrolling: $isScrolling,
//                        onSwipeDown: {
//                            print("swipe down: \(offset.height) \(showDetail)")
//                            if showDetail {
//                                withAnimation {
//                                    showDetail = false
//                                }
//                            } else {
//                                offset.height = dismissThreshold
//                                withAnimation(.snappy) {
//                                    photoEnvironment.selectedDbPhotoAsset = nil
//                                }
//                            }
//                        }, assetFileUrl: $assetFileUrl
//                     ).offset(showDetail ? .init(width: 0, height: sheetOffset.height) : .zero)
//                     //                         .frame(maxWidth: .infinity, maxHeight: .infinity)
//                         .onChange(of: offset) {
//                             if offset.height < -10 {
//                                 withAnimation {
//                                     print("Showing Detail")
//                                     self.showDetail = true
//                                     sheetOffset = .zero
//                                 }
//                             } else if offset.height > 10 {
//                                 withAnimation {
//                                     print("hiding Detail")
//                                     self.showDetail = false
//                                     sheetOffset = .zero
//                                 }
//                             }
//                         }
//                     //                 .frame(width: 200, height: 200)
//                         .matchedGeometryEffect(
//                            id: "thumbnailImageTransition"
//                            + currentDbPhotoAsset.localIdentifier, in: animation)
//                     if !showDetail {
//                         Spacer()
//                         PhotoScrubberView(itemsToShow: 5, spacing: 10, scrollState: $isScrolling)
//                         //                 PhotoCarousel(startDbPhotoAsset: currentDbPhotoAsset)
//                             .frame(height: 60)
//                             .opacity(
//                                Double(
//                                    1 - ((abs(offset.height) + (scale - 1) * dismissThreshold)
//                                         / dismissThreshold)))
//                         HStack {
//                             if let assetFileUrl {
//                                 ShareLink(item: assetFileUrl) {
//                                     IconView(size: .medium, iconSystemName: "square.and.arrow.up")
//                                 }
//                             } else {
//                                 IconView(size: .medium, iconSystemName: "square.and.arrow.up")
//                                     .disabled(assetFileUrl == nil)
//                             }
//                             Spacer()
//                             Button {
//                                 withAnimation {
//                                     offset = .init(width: 0, height: -300)
//                                 }
//                             } label: {
//                                 IconView(size: .medium, iconSystemName: "info.circle")
//                             }
//                             Spacer()
//                             Button {
//                                 showDeleteAlert = true
//                             } label: {
//                                 IconView(size: .medium, iconSystemName: "trash")
//                             }
//                         }.padding()
//                             .padding(.horizontal, 10)
//                     }
//                     //                 }
//                     //                 .ignoresSafeArea(.all)
//                 }
//                 
//                 VStack {
//                     PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset, showDetail: .constant(showDetail), offset: $offset, animation: animation)
//                         .gesture(DragGesture().onChanged { value in
//    //                                 sheetOffset = value.translation
//                             print("Sheet offset \(value.translation)")
//                             print(" offset \(offset)")
//    //                                 if sheetOffset.height + offset.height > 0 {
//    //                                     print("Detail stopped ", sheetOffset.height, offset.height)
//    //                                     self.showDetail = false
//    //                                     sheetOffset = .zero
//    //                                 }
//                         })
//                 }.offset(showDetail ? .init(width: 0, height: sheetOffset.height + offset.height) : .init(width: 0, height: 100))
//                     .frame(maxHeight: showDetail ? .infinity : 0)
//             }
//             
//         }
////         .sheet(isPresented: .constant(showDetail), onDismiss: {
////             withAnimation {
////                 offset = .zero
////             }
////         }) {
////             let maxHeight: CGFloat = 600
////             let shouldHeight: CGFloat = abs(offset.height * 2) < maxHeight ? abs(offset.height * 2) : maxHeight
////             let minHeight: CGFloat = 80
////                 VStack {
////                     PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset, showDetail: .constant(showDetail), offset: $offset, animation: animation)
////                        //  .gesture(DragGesture().onChanged { value in
////                        //      if oldOffset == .zero {
////                        //          oldOffset = offset
////                        //      }
////                        //      print("Height: \(value.translation.height)")
////                        //      offset = CGSize(width: oldOffset.width, height: value.translation.height)
////                        //      print(offset)
////                        //  }.onEnded { value in
////                        //      oldOffset = .zero
////                        //  })
////                 }
////                 //                    .presentationDetents([.height(abs(translation.height * 3))])
////                 .presentationDetents([.height(max(shouldHeight, minHeight))])
////                 .presentationBackgroundInteraction(
////                    .enabled(upThrough: .height(max(shouldHeight, minHeight)))
////                 )
////                 .frame(maxWidth: .infinity)
////                 .transition(.move(edge: .bottom))
////         }
//         .statusBarHidden(offset.height * 2 < -550)
//         .background {
//             Color.black.opacity(Double(1 - (offset.height / dismissThreshold)))
//                 .ignoresSafeArea(.all)
//                 .allowsHitTesting(photoEnvironment.selectedDbPhotoAsset != nil)
//         }.confirmationDialog("Trash Item", isPresented: $showDeleteAlert)
//         {
//             Button("Confirm (this does nothing rn)", role: .destructive) {
//                 
//             }
//             Button("Cancel", role: .cancel) {
//
//             }
//         }
//         //            GeometryReader { reader in
//         //                let heightConstraint = offset.height * 3
// //                let _ = print(heightConstraint)
// //
// //                VStack {
// //                    Spacer()
// //                    PhotoDetails(currentDbPhotoAsset: $currentDbPhotoAsset)
// //                        .frame(height: 400)
// //                        .background(Color.white)
// //                        .cornerRadius(20)
// //                        .shadow(radius: 10)
// //                        .offset(
// //                            x: 0,
// //                            y: reader.size.height
// //                                - (showDetail ? 400 - heightConstraint : -heightConstraint)
// //                        )
// //                        .transition(.move(edge: .bottom))
// //                }
// //                .ignoresSafeArea(.all)
// //            }
//     }
// }
//
// struct PhotoDetails: View {
//     @Binding var currentDbPhotoAsset: DBPhotoAsset
//     @Binding var showDetail: Bool
//     @Binding var offset: CGSize
//     let animation: Namespace.ID
//
//     var body: some View {
// //        Image(uiImage: UIImage(contentsOfFile: FullSizeImageCache.getFullSizeImageOrThumbnail(for: currentDbPhotoAsset).path) ?? UIImage())
//         VStack {
//             List {
//                 Section {
//                     Label {
//                         Text("Creation")
//                         Text(currentDbPhotoAsset.creationDate.formatted())
//                     } icon: {
//                         if currentDbPhotoAsset.mediaType == .image {
//                             if currentDbPhotoAsset.mediaSubtype.contains(.photoLive) {
//                                 Image(systemName: "livephoto")
//                             } else {
//                                 Image(systemName: "photo")
//                             }
//                         } else {
//                             Image(systemName: "video")
//                         }
//                     }
//                     
//                     if let location = currentDbPhotoAsset.location {
//                         MapView(location: location)
//                             .frame(height: 200)
//                             .cornerRadius(20)
//                     }
//                 }
//             }.scrollDisabled(true)
//                 .frame(maxWidth: .infinity)
//                 .transition(.move(edge: .bottom))
//         }
//         .frame(maxWidth: .infinity)
//         .transition(.move(edge: .bottom))
//     }
// }
//
// struct MapView: View {
//     var location: CLLocation
//
//     @State private var region: MKCoordinateRegion
//
//     init(location: CLLocation) {
//         self.location = location
//         _region = State(
//             initialValue: MKCoordinateRegion(
//                 center: location.coordinate,
//                 span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//             ))
//     }
//
//     var body: some View {
//         Map(coordinateRegion: $region, annotationItems: [location]) { location in
//             MapAnnotation(coordinate: location.coordinate) {
//                 Image(systemName: "mappin.circle.fill")
//                     .foregroundColor(.red)
//                     .font(.title)
//             }
//         }
//         .edgesIgnoringSafeArea(.all)
//     }
// }
//
// extension CLLocation: Identifiable {
//     public var id: CLLocation {
//         self
//     }
// }
//
//
//#Preview {
//    @Previewable @Namespace var animation
//    let photoEnviornment = PhotoEnvironment()
//    let dbPhotoAsset: DBPhotoAsset = .init(
//        id: -1, localIdentifier: "testImage", mediaType: .image, mediaSubtype: .photoHDR,
//        creationDate: Date.now - 1_000_000, modificationDate: Date.now,
//        location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
//        thumbnailFileName: "meow.jpg")
//    photoEnviornment.lazyArray.insert(
//        dbPhotoAsset
//    )
//    photoEnviornment.selectedDbPhotoAsset = dbPhotoAsset
//    //    return FullImageView(currentDbPhotoAsset: dbPhotoAsset, animation: animation)
//    //        .environmentObject(photoEnviornment)
//    return FullImageView(currentDbPhotoAsset: dbPhotoAsset, animation: animation)
//        .environmentObject(photoEnviornment)
//}
