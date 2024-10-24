import CoreLocation
import MapKit
import SwiftUI
import SwiftUIPager

struct FullImageView: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @StateObject var fullImageState: FullImageViewState = FullImageViewState()

    let animation: Namespace.ID

    init(currentDbPhotoAsset: DBPhotoAsset, animation: Namespace.ID) {
        //        self.currentDbPhotoAsset = currentDbPhotoAsset
        self.animation = animation
    }

    func getImageRatio() -> CGFloat {
        if let selected = photoEnvironment.selectedDbPhotoAsset,
            let uiImage = UIImage(contentsOfFile: selected.thumbnailURL.path)
        {
            // if height is greater than width
            if uiImage.size.height > uiImage.size.width {
                return 1.2
            } else {
                return 1.6
            }
        } else {
            return 1.0
        }
    }

    func getHeightOffset(_ height: CGFloat) -> CGFloat {
        if let selected = photoEnvironment.selectedDbPhotoAsset,
            let uiImage = UIImage(contentsOfFile: selected.thumbnailURL.path)
        {
            // if height is greater than width
            if uiImage.size.height > uiImage.size.width {
                return -height / 14
            } else {
                return -height / 7
            }
        } else {
            return 1.0
        }
    }

    //TODO: Add loading icon on top
    var body: some View {
        //        let selectOrCurrent = photoEnvironment.selectedDbPhotoAsset ?? currentDbPhotoAsset
        VStack {
            FullImageViewTopBar()
            Spacer()
            GeometryReader { reader in
                PagedImageView(animation: animation)
                    .offset(
                        fullImageState.showDetail
                            ? .init(width: 0, height: getHeightOffset(reader.size.height)) : .zero
                    )
                    .scaleEffect(fullImageState.showDetail ? getImageRatio() : 1.0)
            }
            Spacer()
            PhotoScrubberView(itemsToShow: 5, spacing: 10) {
                Task {
                    await self.fullImageState.getView(
                        selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset)
                }
            }
            .frame(height: 60)
            .opacity(
                fullImageState.showDetail ? 0 : 1
            )
            .disabled(fullImageState.showDetail)
            FullImageViewQuickActions()
            //                         }
            //                 }
            //                 .ignoresSafeArea(.all)
        }
        // TODO: MAKE THIS DEPEND ON SCREEN HEIGHT
        .statusBarHidden(fullImageState.offset.height * 2 < -550)
        .background {
            Color.black.opacity(
                Double(1 - (fullImageState.offset.height / fullImageState.dismissThreshold))
            )
            .ignoresSafeArea(.all)
            .allowsHitTesting(photoEnvironment.shouldShowFullImageView)
        }
        .ignoresSafeArea(fullImageState.showDetail ? .all : .keyboard)
        .sheet(
            isPresented: .constant(fullImageState.showDetail),
            onDismiss: {
                withAnimation {
                    fullImageState.showDetail = false
                }
            }
        ) {
            //            if fullImageState.showDetail {
            GeometryReader { reader in
                VStack {
                    PhotoDetails(animation: animation)
                        .gesture(
                            DragGesture().onChanged { value in
                                //                                 sheetOffset = value.translation
                                //                            print("Sheet offset \(value.translation)")
                                //                            print(" offset \(offset)")
                                //                                 if sheetOffset.height + offset.height > 0 {
                                //                                     print("Detail stopped ", sheetOffset.height, offset.height)
                                //                                     self.showDetail = false
                                //                                     sheetOffset = .zero
                                //                                 }
                            })
                    //                }
                    //                .offset(.init(width: 0, height: reader.size.height + (fullImageState.offset.height > -150 ? fullImageState.offset.height * 2 : fullImageState.offset.height - 150))) // TODO: Change to carousel height
                    //                     .frame(maxWidth: reader.size.width, maxHeight: showDetail ? .infinity : 0)
                }.environmentObject(fullImageState)

            }.presentationDetents([.medium])
        }
        .onAppear {
            Task {
                await fullImageState.getView(
                    selectedDbPhotoAsset: photoEnvironment.selectedDbPhotoAsset)
            }
        }
        .environmentObject(fullImageState)
    }
}

struct PhotoDetails: View {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    @EnvironmentObject var fullImageState: FullImageViewState

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

    let animation: Namespace.ID

    func generateTagsFromMediaSubtype() -> [String] {
        var includedSubtypes = [String]()

        if let subTypes = photoEnvironment.selectedDbPhotoAsset?.mediaSubtype {
            for s in subTypes.includedTypes {
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
        }

        return includedSubtypes
    }

    var isMediaImage: Bool {
        photoEnvironment.selectedDbPhotoAsset?.mediaType == .image
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
                            if let hasLive = photoEnvironment.selectedDbPhotoAsset?.mediaSubtype
                                .contains(.photoLive), hasLive
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
                            photoEnvironment.selectedDbPhotoAsset?.creationDate.formatted(
                                fullDateTimeFormatter) ?? "")
                        Text(
                            "Last modified: \(photoEnvironment.selectedDbPhotoAsset?.modificationDate.formatted(fullDateTimeFormatter) ?? "")"
                        )
                    } icon: {

                    }

                    if let location = photoEnvironment.selectedDbPhotoAsset?.location {
                        MapView(location: location)
                            .frame(height: 200)
                            .cornerRadius(20)
                    }
                }
            }.scrollDisabled(false)
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
        Map(coordinateRegion: $region, annotationItems: [location]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title)
            }
        }
        .disabled(true)
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

#Preview {
    @Previewable @Namespace var animation
    let photoEnviornment = PhotoEnvironment()
    let dbPhotoAsset: DBPhotoAsset = .init(
        id: -1, localIdentifier: "testImage", mediaType: .image, mediaSubtype: .photoHDR,
        creationDate: Date.now - 1_000_000, modificationDate: Date.now,
        location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
        thumbnailFileName: "meow.jpg")
    photoEnviornment.lazyArray.insert(
        dbPhotoAsset
    )
    photoEnviornment.selectedDbPhotoAsset = dbPhotoAsset
    //    return FullImageView(currentDbPhotoAsset: dbPhotoAsset, animation: animation)
    //        .environmentObject(photoEnviornment)
    return FullImageView(currentDbPhotoAsset: dbPhotoAsset, animation: animation)
        .environmentObject(photoEnviornment)
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

    var body: some View {
        HStack {
            Text(
                formatter.localizedString(
                    for: photoEnvironment.selectedDbPhotoAsset?.creationDate ?? .now,
                    relativeTo: Date.now)
            )
            .font(.largeTitle)
            .foregroundStyle(.white)
            Spacer()
            Button {
                withAnimation {
                    photoEnvironment.shouldShowFullImageView = false
                }
            } label: {
                IconView(size: .small, iconSystemName: "xmark")
            }
        }.padding([.leading, .trailing], 30)
            .frame(maxHeight: fullImageState.showDetail ? 0 : nil)
            .opacity(fullImageState.showDetail ? 0 : 1)
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
                    IconView(size: .medium, iconSystemName: "square.and.arrow.up")
                }
            } else {
                IconView(size: .medium, iconSystemName: "square.and.arrow.up")
                    .disabled(fullImageState.assetFileUrl == nil)
            }
            Spacer()
            Button {
                withAnimation {
                    fullImageState.showDetail = true
                }
            } label: {
                IconView(size: .medium, iconSystemName: "info.circle")
            }
            Spacer()
            Button {
                showDeleteAlert = true
            } label: {
                IconView(size: .medium, iconSystemName: "trash")
            }
        }.padding()
            .padding(.horizontal, 10)
            .confirmationDialog("Trash Item", isPresented: $showDeleteAlert) {
                Button("Confirm (this does nothing rn)", role: .destructive) {

                }
                Button("Cancel", role: .cancel) {

                }
            }
    }
}
