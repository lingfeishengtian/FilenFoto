import CoreLocation
import SwiftUI
import UIKit

class GridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate
{
    var collectionView: UICollectionView!
    var photoEnvironment: PhotoEnvironment
    var selectedIndexPath: IndexPath?
    var cellsPerRow: Int

    var startWithIndexPath: IndexPath?

    var generateViewForItem: ((DBPhotoAsset) -> any View)
    var onCellSelected: ((DBPhotoAsset) -> Void)

    init(
        photoEnvironment: PhotoEnvironment, cellsPerRow: Int = 3,
        startWithIndexPath: IndexPath? = nil,
        generateViewForItem: @escaping ((DBPhotoAsset) -> any View),
        onCellSelected: @escaping ((DBPhotoAsset) -> Void)
    ) {
        self.photoEnvironment = photoEnvironment
        self.cellsPerRow = cellsPerRow
        self.startWithIndexPath = startWithIndexPath
        self.generateViewForItem = generateViewForItem
        self.onCellSelected = onCellSelected
        super.init(nibName: nil, bundle: nil)
    }

    func collectionView(
        _ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {

        if let startWithIndexPath = startWithIndexPath {
            //           if collectionView.isValidIndexPath(indexpath: startWithIndexPath) {
            print("Start")
            self.collectionView.scrollToItem(at: startWithIndexPath, at: .top, animated: false)
            //           }
            self.startWithIndexPath = nil
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up layout for UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 3
        layout.minimumLineSpacing = 3
        layout.scrollDirection = .vertical

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isUserInteractionEnabled = true
//        collectionView.register(
//            HostingCollectionViewCell.self, forCellWithReuseIdentifier: "HostingCollectionViewCell")
        collectionView.register(HostingCollectionViewCell.self, forCellWithReuseIdentifier: "HostingCollectionViewCell")

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // make background color clear
        view.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        super.viewDidLoad()
        
        loadInitialPhotoAssets()
    }

    func scrollToSelected() {
        if let selectedDbPhotoAsset = photoEnvironment.selectedDbPhotoAsset {
            let index = photoEnvironment.lazyArray.binSearch(selectedDbPhotoAsset)
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.scrollToItem(
                at: indexPath, at: .centeredVertically, animated: true)
        }
    }

    // MARK: - Lazy loading of photo assets
    func loadInitialPhotoAssets() {
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        return photoEnvironment.lazyArray.sortedArray.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "HostingCollectionViewCell", for: indexPath)
            as! HostingCollectionViewCell
        let item = photoEnvironment.lazyArray.sortedArray[indexPath.item]
        
        let hostingController = UIHostingController(rootView: AnyView(generateViewForItem(item)))
        cell.host(hostingController)

        if let selectedAsset = photoEnvironment.selectedDbPhotoAsset,
            indexPath.item == photoEnvironment.lazyArray.binSearch(selectedAsset)
        {
            selectedIndexPath = indexPath
            cell.alpha = 0
        } else {
            cell.alpha = 1
        }

        cell.backgroundColor = .clear

        // Add a transparent overlay view that passes through touch events
//        let overlayView = UIView(frame: cell.bounds)
//        overlayView.backgroundColor = .clear
//        overlayView.isUserInteractionEnabled = false
//        cell.contentView.addSubview(overlayView)

        return cell
    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
//        -> UICollectionViewCell
//    {
//        let cell =
//            collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailCell", for: indexPath)
//            as! ThumbnailCell
//        let item = photoEnvironment.lazyArray.sortedArray[indexPath.item]
//        cell.configure(with: item)
//        
//        print("Get cell \(indexPath.item)")
//        if let selectedAsset = photoEnvironment.selectedDbPhotoAsset, indexPath.item == photoEnvironment.lazyArray.binSearch(selectedAsset) {
//            selectedIndexPath = indexPath
//            print("Set cell \(indexPath.item)")
//            cell.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
//        } else {
//            cell.transform = CGAffineTransform.identity
//        }
//
//        cell.backgroundColor = .clear
//
//        return cell
//    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = photoEnvironment.lazyArray.sortedArray[indexPath.item]
        print(selectedItem.localIdentifier)
//        photoEnvironment.selectedDbPhotoAsset = selectedItem
        
        onCellSelected(selectedItem)
//
//        // Animate the selection
//        if let previousIndexPath = selectedIndexPath, let previousCell = collectionView.cellForItem(at: previousIndexPath) {
//            UIView.animate(withDuration: 0.3) {
//                previousCell.transform = CGAffineTransform.identity
//            }
//        }
//
//        if let selectedCell = collectionView.cellForItem(at: indexPath) {
//            UIView.animate(withDuration: 0.3) {
//                selectedCell.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
//            }
//        }
//
//        selectedIndexPath = indexPath
//        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        print(selectedItem.localIdentifier)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = (CGFloat(cellsPerRow - 1) * 3)  // 3 is the spacing between cells
        let width = (collectionView.frame.width - totalSpacing) / CGFloat(cellsPerRow)
        return CGSize(width: width, height: width)
    }
}

class HostingCollectionViewCell: UICollectionViewCell {
    private var hostingController: UIHostingController<AnyView>?
//    private let uiView = UIView()

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(uiView)
//        uiView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            uiView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            uiView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            uiView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            uiView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
//        //disable hit testing on the cell so that touch events are passed to the collection view
//        isUserInteractionEnabled = true
//        uiView.isUserInteractionEnabled = false
//    }
    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
    // disable hit testing on the cell so that touch events are passed to the collection view
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        nil
//    }

    func host(_ hostingController: UIHostingController<AnyView>) {
        if let hostingController = self.hostingController {
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
        }

        self.hostingController = hostingController
        hostingController.view.isUserInteractionEnabled = false
        contentView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}

struct GridView: UIViewControllerRepresentable {
    @EnvironmentObject var photoEnvironment: PhotoEnvironment
    var cellsPerRow: Int = 3
    let generateViewForItem: ((DBPhotoAsset) -> any View)
    let onCellSelected: ((DBPhotoAsset) -> Void)

    func makeUIViewController(context: Context) -> GridViewController {
        let index =
            (photoEnvironment.selectedDbPhotoAsset != nil)
            ? (photoEnvironment.lazyArray.binSearch(photoEnvironment.selectedDbPhotoAsset!)) : 0
        let viewController = GridViewController(
            photoEnvironment: photoEnvironment, cellsPerRow: cellsPerRow,
            startWithIndexPath: IndexPath(item: index, section: 0),
            generateViewForItem: generateViewForItem, onCellSelected: onCellSelected)
        return viewController
    }

    func updateUIViewController(_ uiViewController: GridViewController, context: Context) {
        // Update the view controller with new data or state changes if needed
        uiViewController.collectionView.reloadData()
        uiViewController.scrollToSelected()
    }

    // Coordinator to handle events if needed
    class Coordinator: NSObject, UICollectionViewDelegate {
        var parent: GridView

        init(parent: GridView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

struct PreviewGridView: PreviewProvider {
    static var previews: some View {
        let photoEnvironment: PhotoEnvironment = PhotoEnvironment()
        for i in 0..<200 {
            let dbPhotoAsset: DBPhotoAsset = .init(
                id: -1, localIdentifier: String(i), mediaType: .image, mediaSubtype: .photoHDR,
                creationDate: Date.now - 1_000_000, modificationDate: Date.now,
                location: CLLocation(latitude: 0, longitude: 0), favorited: false, hidden: false,
                thumbnailFileName: "meow.jpg")
            photoEnvironment.lazyArray.insert(
                dbPhotoAsset
            )
        }

        photoEnvironment.selectedDbPhotoAsset = photoEnvironment.lazyArray.sortedArray.last!
        return VStack {
            Text("Hello")
            GridView { asset in
                ThumbnailView(thumbnailName: asset.thumbnailFileName)
            } onCellSelected: { asset in
                print(asset.localIdentifier)
            }.environmentObject(photoEnvironment)
        }
    }
}
