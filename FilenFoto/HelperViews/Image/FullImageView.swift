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
                return 1.3
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
                return -height / 12
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
                .frame(maxHeight: fullImageState.shouldHideBars ? 0 : nil)
                .opacity(fullImageState.shouldHideBars ? 0 : 1)
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
                fullImageState.shouldHideBars ? 0 : 1
            )
            .frame(maxHeight: fullImageState.shouldHideBars ? 0 : nil)
            .opacity(fullImageState.shouldHideBars ? 0 : 1)
            .disabled(fullImageState.shouldHideBars)
            FullImageViewQuickActions()
                .frame(maxHeight: fullImageState.shouldHideBars ? 0 : nil)
                .opacity(fullImageState.shouldHideBars ? 0 : 1)
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
        .ignoresSafeArea(fullImageState.shouldHideBars ? .all : .keyboard)
        .sheet(
            isPresented: .constant(fullImageState.showDetail),
            onDismiss: {
                withAnimation {
                    fullImageState.showDetail = false
                }
            }
        ) {
            GeometryReader { reader in
                VStack {
                    PhotoDetails(animation: animation)
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
                    photoEnvironment.shouldShowFullImageView = false
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
//        HStack {
//            if let assetFileUrl = fullImageState.assetFileUrl {
//                ShareLink(item: assetFileUrl) {
//                    IconView(size: .medium, iconSystemName: "square.and.arrow.up")
//                }
//            } else {
//                IconView(size: .medium, iconSystemName: "square.and.arrow.up")
//                    .disabled(fullImageState.assetFileUrl == nil)
//            }
//            Spacer()
//            Button {
//                withAnimation {
//                    fullImageState.showDetail = true
//                }
//            } label: {
//                IconView(size: .medium, iconSystemName: "info.circle")
//            }
//            Spacer()
//            Button {
//                showDeleteAlert = true
//            } label: {
//                IconView(size: .medium, iconSystemName: "trash")
//            }
//        }
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
        .padding()
            .padding(.horizontal, 10)
            .confirmationDialog("Trash Item", isPresented: $showDeleteAlert) {
                Button("Confirm (this does nothing rn)", role: .destructive) {

                }
                Button("Cancel", role: .cancel) {

                }
            }
    }
}
