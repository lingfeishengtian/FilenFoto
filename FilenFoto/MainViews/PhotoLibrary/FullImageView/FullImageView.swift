import CoreLocation
import MapKit
import SwiftUI

struct FullImageView: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @StateObject var fullImageState: FullImageViewState = FullImageViewState()
    @State var sheetTopAnchor: CGPoint = .zero
    
    @State var localScale: CGFloat = 1.0
    @State var localOffset: CGSize = .zero
    
    let animation: Namespace.ID
    
    init(animation: Namespace.ID) {
        //        self.currentDbPhotoAsset = currentDbPhotoAsset
        self.animation = animation
    }
    
    func getImageRatio() -> CGFloat {
        if let selected = photoEnvironment.selectedDbPhotoAsset,
           let uiImage = UIImage(contentsOfFile: selected.thumbnailURL.path)
        {
            // if height is greater than width
            if uiImage.size.height > uiImage.size.width {
                return 1.3
            } else {
                return 1.6
            }
        } else {
            return 1.0
        }
    }
    
    var isImageDismissMode: Bool {
        fullImageState.shouldHideBars || localScale != 1.0 || localOffset.height < 0
    }
    
    let maxTopHUDHeight: CGFloat = 50
    let maxBottomHUDHeight: CGFloat = 120

    //TODO: Add loading icon on top
    var body: some View {
        //        let selectOrCurrent = photoEnvironment.selectedDbPhotoAsset ?? currentDbPhotoAsset
        ZStack {
            if fullImageState.showBurstImages {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                fullImageState.showBurstImages = false
                            }
                        } label: {
                            IconView(size: .small, iconSystemName: "xmark")
                        }
                    }.padding([.leading, .trailing], 30)
//                    BurstPageView(matchedAnimationLocalIdentifier: photoEnvironment.selectedDbPhotoAsset!.localIdentifier, animation: animation, dbPhotoAssets: getBurstImageArray())
                }
                .background {
                    Color.black.opacity(
                        Double(1)
                    ).ignoresSafeArea(.all)
                }
            } else {
                ZStack {
                    GeometryReader { reader in
                        PagedImageView(animation: animation, currentIndex: photoEnvironment.getCurrentPhotoAssetIndex() ?? 0, globalScale: $localScale, localOffset: $localOffset, baseOffset: maxTopHUDHeight, imageFrameHeight: reader.size.height - maxTopHUDHeight - maxBottomHUDHeight)
//                            .frame(maxHeight: reader.size.height - maxTopHUDHeight - maxBottomHUDHeight)
//                            .offset(.init(width: 0, height: maxTopHUDHeight))
                    }
                    .ignoresSafeArea(.all)
                    .zIndex(15)
                    .alignmentGuide(VerticalAlignment.center) { $0[VerticalAlignment.center] }
                    VStack {
                        FullImageViewTopBar()
                        //                        .frame(maxHeight: isImageDismissMode ? 0 : nil)
                            .opacity(isImageDismissMode ? 0 : 1)
                            .frame(maxHeight: maxTopHUDHeight)
                        Spacer()
                        // TODO: scrubber causing lag during update..
                        VStack {
                            PhotoScrubberView(itemsToShow: 5, spacing: 10) {
                                Task {
                                    await self.fullImageState.getView(
                                        selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset)
                                }
                            }
                            .frame(height: 60)
                            .opacity(
                                isImageDismissMode ? 0 : 1
                            )
                            FullImageViewQuickActions()
                                .opacity(isImageDismissMode ? 0 : 1)
                        }.frame(maxHeight: maxBottomHUDHeight)
                    }
                    // TODO: MAKE THIS DEPEND ON SCREEN HEIGHT
                    // TODO: DEPRECATE OLD WAY OF DRAGGING
                    .statusBarHidden(localScale != 1.0)
                    .background {
                        Color.black.opacity(
                            //                        Double(1 - (localOffset.height / fullImageState.dismissThreshold))
                            Double(localScale != 1.0 ? 0.5 : 1.0)
                        )
                        .ignoresSafeArea(.all)
                        .allowsHitTesting(photoEnvironment.shouldShowFullImageView)
                    }
                    .onAppear {
                        Task {
                            await fullImageState.getView(
                                selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset)
                        }
                    }
                }
            }
        }
        .environmentObject(fullImageState)
    }
}

struct PhotoDetails: View {
//    @EnvironmentObject var photoEnvironment: PhotoEnvironment
//    @EnvironmentObject var fullImageState: FullImageViewState
    
    fileprivate let fullDateTimeFormatter: Date.FormatStyle = {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.abbreviated)
            .day(.twoDigits)
            .hour(.defaultDigits(amPM: .abbreviated))
            .minute(.twoDigits)
            .second(.twoDigits)
            .timeZone(.identifier(.long))
            .era(.wide)
            .weekday(.wide)
            .locale(Locale(identifier: "ja_JP"))
    }()
    
    let currentDbPhotoAsset: DBPhotoAsset
    let animation: Namespace.ID
    
    func generateTagsFromMediaSubtype() -> [String] {
        var includedSubtypes = [String]()
        
        for s in currentDbPhotoAsset.mediaSubtype.includedTypes {
            switch s.0 {
            case .photoHDR:
                includedSubtypes.append("HDR")
            case .photoLive:
                includedSubtypes.append("Live")
            case .photoScreenshot:
                includedSubtypes.append("Screenshot")
            case .videoTimelapse:
                includedSubtypes.append("Timelapse")
            case .videoHighFrameRate:
                includedSubtypes.append("Slo-Mo")
            default:
                break
            }
        }
        
        return includedSubtypes
    }
    
    var isMediaImage: Bool {
        currentDbPhotoAsset.mediaType == .image
    }
    
    var body: some View {
        VStack {
            List {
                Section {
                    Label {
                        HStack {
                            if generateTagsFromMediaSubtype().isEmpty {
                                if isMediaImage {
                                    Text("Image")
                                } else {
                                    Text("Video")
                                }
                            } else {
                                ForEach(generateTagsFromMediaSubtype(), id: \.self) { tag in
                                    Text(tag)
                                }
                            }
                        }
                    } icon: {
                        if isMediaImage {
                            if currentDbPhotoAsset.mediaSubtype.contains(.photoLive)
                            {
                                Image(systemName: "livephoto")
                            } else {
                                Image(systemName: "photo")
                            }
                        } else {
                            Image(systemName: "video")
                        }
                    }
                    Label {
                        Text(
                            currentDbPhotoAsset.creationDate.formatted(
                                fullDateTimeFormatter) ?? "")
                        Text(
                            "Last modified: \(currentDbPhotoAsset.modificationDate.formatted(fullDateTimeFormatter) ?? "")"
                        )
                    } icon: {
                        
                    }
                    
                    if let location = currentDbPhotoAsset.location {
                        MapView(location: location)
                            .frame(height: 200)
                            .cornerRadius(20)
                    }
                }
            }.scrollDisabled(true)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom))
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom))
    }
}

struct MapView: View {
    var location: CLLocation
    
    @State private var region: MKCoordinateRegion
    
    init(location: CLLocation) {
        self.location = location
        _region = State(
            initialValue: MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, interactionModes: .pitch, annotationItems: [location]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            if let url = URL(string: "http://maps.apple.com/?ll=\(location.coordinate.latitude),\(location.coordinate.longitude)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

extension CLLocation: Identifiable {
    public var id: CLLocation {
        self
    }
}

private let formatter: RelativeDateTimeFormatter = {
    let rdtf = RelativeDateTimeFormatter()
    
    rdtf.unitsStyle = .full
    rdtf.locale = Locale(identifier: "ja_JP")
    
    return rdtf
}()

struct FullImageViewTopBar: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
    
    func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date.now
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDayOnDate = calendar.startOfDay(for: date)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        
        let daysFromToday = calendar.dateComponents([.day], from: startOfToday, to: startOfDayOnDate).day!
        
        if abs(daysFromToday) <= 1 {
            // Yesterday, today or tomorrow
            formatter.dateStyle = .full
            formatter.doesRelativeDateFormatting = true
        }
        else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            // Another date this year
            formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        }
        else {
            // Another date in another year
            formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMMyyyy")
        }
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current // Adapts to the user's locale
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .medium
        
        return timeFormatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            VStack {
                Text(
                    formatDate(photoEnvironment.selectedDbPhotoAsset?.creationDate ?? .now)
                )
                .font(.title3)
                .bold()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(
                    formatTime(photoEnvironment.selectedDbPhotoAsset?.creationDate ?? .now)
                )
                .font(.caption)
                .bold()
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            Button {
                withAnimation {
                    photoEnvironment.clearSelectedDbPhotoAsset()
                }
            } label: {
                IconView(size: .small, iconSystemName: "xmark")
            }
        }.padding([.leading, .trailing], 30)
    }
}

struct FullImageViewQuickActions: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState
    
    @State private var showDeleteAlert: Bool = false
    
    var body: some View {
        HStack {
            if let assetFileUrl = fullImageState.assetFileUrl {
                ShareLink(item: assetFileUrl) {
                    Image(systemName: "square.and.arrow.up")
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "square.and.arrow.up")
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .disabled(fullImageState.assetFileUrl == nil)
            }
            
            Spacer()
            HStack {
                Button {
                    withAnimation {
                        //                        fullImageState.showDetail = true
                    }
                } label: {
                    Image(systemName: "heart")
                }
                .padding([.trailing])
                
                Button {
                    withAnimation {
                        fullImageState.showDetail = true
                    }
                } label: {
                    Image(systemName: "info.circle")
                }
                //                            .padding(.horizontal)
                //                        Image(systemName: "slider.horizontal.3")
                if let isBurst = photoEnvironment.selectedDbPhotoAsset?.isBurst, isBurst {
                    Button {
                        withAnimation {
                            fullImageState.showBurstImages = true
                        }
                    } label: {
                        Image(systemName: "laser.burst")
                    }.padding([.leading])
                }
            }
            .padding(10)
            .padding(.horizontal, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            
            Spacer()
            
            Image(systemName: "trash")
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding(.horizontal)
        .confirmationDialog("Trash Item", isPresented: $showDeleteAlert) {
            Button("Confirm (this does nothing rn)", role: .destructive) {
                
            }
            Button("Cancel", role: .cancel) {
                
            }
        }
    }
}
