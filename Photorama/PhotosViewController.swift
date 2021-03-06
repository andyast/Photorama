//
//  PhotosViewController.swift
//  Photorama
//
//  Created by Andy Steinmann on 3/30/17.
//  Copyright © 2017 DLS. All rights reserved.
//


import UIKit



class PhotosViewController: UIViewController {
    @IBOutlet var collectionView: UICollectionView!

    fileprivate var itemsPerRow: CGFloat = 3


    var store: PhotoStore!
    let photoDataSource = PhotoDataSource()
    var currentFeedType: FeedType = .interesting





    override func viewDidLoad() {
        super.viewDidLoad()

        store = PhotoStore()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(PhotosViewController.refreshControlAction), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.dataSource = photoDataSource
        collectionView.delegate = self

        loadFeedForType(feedType: .interesting)

    }

    func refreshControlAction(sender: UIRefreshControl) {
        loadFeedForType(feedType: currentFeedType) }

    @IBAction func stepperValueChanged(sender: UIStepper) {
        itemsPerRow = CGFloat(sender.value)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func loadFeedForType(feedType: FeedType) {
        self.collectionView.refreshControl?.beginRefreshing()
        currentFeedType = feedType
        self.updateDataSource()


        let fetchCompletion: (PhotosResult) -> Void = { photosResult in
            if case let .success(photos) = photosResult, photos.count > 0 {
                self.updateDataSource()
            }
            self.collectionView.refreshControl?.endRefreshing()
        }

        switch feedType {
        case .interesting:
            store.fetchInterestingPhotos(completion: fetchCompletion)
        case .recent:
            store.fetchRecentPhotos(completion: fetchCompletion)
        }
    }



    @IBAction func toggleView(_ sender: Any) {
        let newFeedType: FeedType = currentFeedType == .interesting ? .recent : .interesting
        loadFeedForType(feedType: newFeedType)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto"?:
            if let selectedIndexPath =
                collectionView.indexPathsForSelectedItems?.first {
                    let photo = photoDataSource.photos[selectedIndexPath.row]
                    let destinationVC = segue.destination as! PhotoInfoViewController
                    destinationVC.photo = photo
                    destinationVC.store = store
            }
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }


    private func updateDataSource() {
        store.fetchAllPhotos(fromFeed: currentFeedType) {
            (photosResult) in
            switch photosResult {
            case let .success(photos):

                let sortedPhotos = photos.sorted(by: { (a, b) in
                    if let aDate = a.dateUploaded as Date?, let bDate = b.dateUploaded as Date? {
                        return aDate > bDate
                    }
                    return false
                })

                self.photoDataSource.photos = sortedPhotos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
}


extension PhotosViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = 20.0 * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow

        return CGSize(width: widthPerItem, height: widthPerItem)
    }

}


extension PhotosViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = photoDataSource.photos[indexPath.row]
        // Download the image data, which could take some time
        store.fetchImage(for: photo) { (result) -> Void in
            // The index path for the photo might have changed between the
            // time the request started and finished, so find the most
            // recent index path
            guard let photoIndex = self.photoDataSource.photos.index(of: photo),
                case let .success(image) = result else {
                    return
            }
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            // When the request finishes, only update the cell if it's still visible
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(with: image, photo: photo)
            }
        }
    }
}
