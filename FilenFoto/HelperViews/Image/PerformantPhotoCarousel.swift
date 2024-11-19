import CoreLocation
import SwiftUI
import UIKit

class PhotoScrubberViewController: UIViewController, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, UIScrollViewDelegate
{

    var collectionView: UICollectionView!
    let itemsToShow = 10
    let spacing: CGFloat = 5
    let selectedPadding: CGFloat = 10
    let scaleEffectSelected: CGFloat = 1.8
    var isLoading = false

    var photoEnvironment: PhotoEnvironment
    var startWithIndexPath: IndexPath?
    let onShouldFullImageLoad: () -> Void
    var numberOfPhotos: Int

    init(
        photoEnvironment: PhotoEnvironment, dbAssetForFirstIndex: DBPhotoAsset?,
        onShouldFullImageLoad: @escaping () -> Void
    ) {
        self.photoEnvironment = photoEnvironment
        if let dbAssetForFirstIndex {
            self.startWithIndexPath = .init(
                item: photoEnvironment.getCurrentPhotoAssetIndex() ?? 0, section: 0
            )
        } else {
            self.startWithIndexPath = nil
        }
        self.onShouldFullImageLoad = onShouldFullImageLoad
        self.numberOfPhotos = photoEnvironment.countOfPhotos
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collectionView(
        _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {

        if let startWithIndexPath = startWithIndexPath {
            //           if collectionView.isValidIndexPath(indexpath: startWithIndexPath) {
            self.collectionView.scrollToItem(at: startWithIndexPath, at: .left, animated: false)
            //            self.scrollToSelected()
            //           }
            self.startWithIndexPath = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up layout for UICollectionView
        let layout = SnappingCollectionViewLayout(photoEnviornment: photoEnvironment)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = spacing

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: "ThumbnailCell")

        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.decelerationRate = .fast
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.heightAnchor.constraint(equalToConstant: 50),
        ])

        // make background color clear
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear

        let itemWidth = calculateSizeOfSingle(collectionView.frame.size)
        let leadingInset = (view.frame.width - itemWidth) / 2
        collectionView.contentInset = UIEdgeInsets(
            top: 0, left: leadingInset, bottom: 0, right: leadingInset)

        // Initial load of photo assets
        loadInitialPhotoAssets()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let targetSize = CGSize(width: view.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        self.preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }

    // MARK: - Lazy loading of photo assets
    func loadInitialPhotoAssets() {
        collectionView.reloadData()
    }

    func loadMorePhotoAssets(startIndex: Int, direction: Int) {
        guard !isLoading else { return }
        isLoading = true

        collectionView.reloadData()
        isLoading = false
    }

    func scrollToSelected() {
        if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset
            //, startWithIndexPath != nil
        {
            let index = photoEnvironment.getCurrentPhotoAssetIndex() ?? 0
            let indexPath = IndexPath(item: index, section: 0)
            if index != selectedIndexPath?.item {
                collectionView.scrollToItem(
                    at: indexPath, at: .centeredHorizontally, animated: false)
                //animate the change
//                UIView.animate(withDuration: 0.3) {
//                    self.collectionView.collectionViewLayout.invalidateLayout()
//                }
                //                startWithIndexPath = nil
            }
        }
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return numberOfPhotos
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath)
            as! ThumbnailCell
        let item = PhotoDatabase.shared.getDBPhotoSync(atOffset: indexPath.item)!
        cell.configure(with: item)

        if let selectedAsset = photoEnvironment.selectedDbPhotoAsset,
           indexPath.item == photoEnvironment.getCurrentPhotoAssetIndex()
        {
            selectedIndexPath = indexPath
            cell.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } else {
            cell.transform = CGAffineTransform.identity
        }

        cell.backgroundColor = .clear

        return cell
    }

    var selectedIndexPath: IndexPath?

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item != photoEnvironment.getCurrentPhotoAssetIndex() {
            let selectedItem = PhotoDatabase.shared.getDBPhotoSync(atOffset: indexPath.item)!
            photoEnvironment.setCurrentSelectedDbPhotoAsset(selectedItem, index: indexPath.item, animate: false)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        selectCenteredItem()
        onShouldFullImageLoad()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            selectCenteredItem()
            onShouldFullImageLoad()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        selectCenteredItem()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        selectCenteredItem()
        onShouldFullImageLoad()
    }
    
    var performingUpdates: Bool = false

    private func selectCenteredItem() {
        if performingUpdates {
            return
        }
        let centerPoint = view.convert(collectionView.center, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: centerPoint),
            indexPath != selectedIndexPath
        {
            //            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            let selectedItem = PhotoDatabase.shared.getDBPhotoSync(atOffset: indexPath.item)!
            photoEnvironment.setCurrentSelectedDbPhotoAsset(selectedItem, index: indexPath.item, animate: false)

            // Animate the selection
            if let previousIndexPath = selectedIndexPath,
                let previousCell = collectionView.cellForItem(at: previousIndexPath)
            {
                UIView.animate(withDuration: 0.3) {
                    previousCell.transform = CGAffineTransform.identity
                }
            }

            if let selectedCell = collectionView.cellForItem(at: indexPath) {
                UIView.animate(withDuration: 0.3) {
                    selectedCell.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }
            }
            
            // haptic feedback
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()

            selectedIndexPath = indexPath
        }
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
//        let itemWidth = indexPath.item == photoEnvironment.getCurrentPhotoAssetIndex() ?
//        calculateSizeOfSingle(collectionView.bounds.size) * scaleEffectSelected :
//        calculateSizeOfSingle(collectionView.bounds.size)
        return CGSize(width: 30, height: 30)
    }

    // MARK: - Helper Methods
    func calculateSizeOfSingle(_ size: CGSize) -> CGFloat {
        return (size.width - spacing * CGFloat(itemsToShow)) / CGFloat(itemsToShow)
    }
}

class SnappingCollectionViewLayout: UICollectionViewFlowLayout {
    let photoEnvironment: PhotoEnvironment

    init(photoEnviornment: PhotoEnvironment) {
        self.photoEnvironment = photoEnviornment
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let collectionView = collectionView else {
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let collectionViewSize = collectionView.bounds.size
        let proposedContentOffsetCenterX = proposedContentOffset.x + collectionViewSize.width / 2

        let targetRect = CGRect(
            x: proposedContentOffset.x, y: 0, width: collectionViewSize.width,
            height: collectionViewSize.height)

        guard let layoutAttributesArray = super.layoutAttributesForElements(in: targetRect) else {
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        var closestAttribute: UICollectionViewLayoutAttributes?
        for layoutAttributes in layoutAttributesArray {
            if closestAttribute == nil
                || abs(layoutAttributes.center.x - proposedContentOffsetCenterX)
                    < abs(closestAttribute!.center.x - proposedContentOffsetCenterX)
            {
                closestAttribute = layoutAttributes
            }
        }

        guard let closest = closestAttribute else {
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let targetContentOffset = CGPoint(
            x: closest.center.x - collectionViewSize.width / 2, y: proposedContentOffset.y)

        // Update the selected item
        let indexPath = collectionView.indexPathForItem(
            at: CGPoint(x: closest.center.x, y: closest.center.y))
        if let indexPath = indexPath {
            collectionView.selectItem(
                at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            //            let selectedItem = photoEnvironment.lazyArray.sortedArray[indexPath.item]
            //            photoEnvironment.selectedDbPhotoAsset = selectedItem
        }
        return targetContentOffset
    }
}

// MARK: - ThumbnailCell
class ThumbnailCell: UICollectionViewCell {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // the image should crop to fit the cell
    func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // rounded
        imageView.layer.cornerRadius = 5
        
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    func configure(with asset: DBPhotoAsset) {
        var uiImage = UIImage(contentsOfFile: asset.thumbnailURL.path)
        // imageView.image = UIImage.init(named: "IMG_3284")!
        #if targetEnvironment(simulator)
            if let isPrev = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"],
                isPrev == "1"
            {
                let randomColors = [
                    UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.orange,
                    UIColor.purple, UIColor.cyan, UIColor.magenta,
                ]

                // generate uiimage with text from asset.id
                uiImage = asset.localIdentifier.image(withAttributes: [
                    .foregroundColor: UIColor.red,
                    .font: UIFont.systemFont(ofSize: 10.0),
                    .backgroundColor: randomColors.randomElement()!,
                ])
            }
        #endif
        imageView.image = uiImage
        //        print("configuring aset with \(asset.localIdentifier)")
    }
}

extension String {

    /// Generates a `UIImage` instance from this string using a specified
    /// attributes and size.
    ///
    /// - Parameters:
    ///     - attributes: to draw this string with. Default is `nil`.
    ///     - size: of the image to return.
    /// - Returns: a `UIImage` instance from this string using a specified
    /// attributes and size, or `nil` if the operation fails.
    func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil)
        -> UIImage?
    {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString).draw(
                in: CGRect(origin: .zero, size: size),
                withAttributes: attributes)
        }
    }

}

// SwiftUI Wrapper for PhotoScrubberViewController
struct PhotoScrubberView: UIViewControllerRepresentable {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    let itemsToShow: Int
    let spacing: CGFloat
    let onLoadFullImage: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = PhotoScrubberViewController(
            photoEnvironment: photoEnvironment,
            dbAssetForFirstIndex: photoEnvironment.selectedDbPhotoAsset,
            onShouldFullImageLoad: onLoadFullImage
            )
        
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the view controller with new data or state changes if needed
        let photoScrubberController = uiViewController as! PhotoScrubberViewController
        if photoScrubberController.collectionView == nil {
            return
        }
        
        let numPhotos = photoEnvironment.countOfPhotos
        let changeItemsCount = photoScrubberController.collectionView.numberOfItems(inSection: 0) - numPhotos
        
        // TODO: Fix indexing insert
        if changeItemsCount == 0 {
            photoScrubberController.scrollToSelected()
        } else {
            photoScrubberController.performingUpdates = true
            photoScrubberController.collectionView.performBatchUpdates({
                if changeItemsCount > 0 {
                    // generate changeitemscount number of indexpaths to delete
                    let indexPathsToDelete = (0..<abs(changeItemsCount)).map { IndexPath(item: $0, section: 0) }
                    photoScrubberController.collectionView.deleteItems(at: indexPathsToDelete)
                } else {
                    // generate changeitemscount number of indexpaths to insert
                    let indexPathsToInsert = photoEnvironment.retrieveAndClearPhotoInsertQueue()
                    photoScrubberController.collectionView.insertItems(at: indexPathsToInsert)
                }
                
                photoScrubberController.numberOfPhotos = numPhotos
//                uiViewController.collectionView.reloadData()
            }, completion: { _ in
//                uiViewController.scrollToSelected()
                photoScrubberController.performingUpdates = false
            })
        }
    }

    // Coordinator to handle events if needed
    class Coordinator: NSObject, UICollectionViewDelegate {
        var parent: PhotoScrubberView

        init(parent: PhotoScrubberView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

//struct PreviewPhotoCarouselUIKit: PreviewProvider {
//    static var previews: some View {
//        let photoEnvironment: PhotoEnvironment = PhotoEnvironment()
//        for i in 0..<200 {
//            let dbPhotoAsset: DBPhotoAsset = .init(
//                id: -1, localIdentifier: String(i), mediaType: .image, mediaSubtype: .photoHDR,
//                creationDate: Date.now - 1_000_000, modificationDate: Date.now,
//                location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
//                thumbnailFileName: "meow.jpg")
//            photoEnvironment.lazyArray.insert(
//                dbPhotoAsset
//            )
//        }
//
//        photoEnvironment.selectedDbPhotoAsset = photoEnvironment.lazyArray.sortedArray.last!
//        return VStack {
//            Text("Hello")
//            PhotoScrubberView(itemsToShow: 10, spacing: 10, scrollState: .constant(true))
//                .environmentObject(photoEnvironment)
//        }
//    }
//}
