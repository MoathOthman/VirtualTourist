//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 8/25/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import UIKit
import MapKit
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

let NO_PIN_IMAGES = "This pin has no images"
let DELETE_SELECTED_PHOTOS = "Remove Selected Pictures"
let NEW_COLLECTION = "New Collection"

class PhotosViewController: UIViewController,MKMapViewDelegate, UICollectionViewDataSource,UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    var currentannotation:MKAnnotation?
    var currentPin: Pin?
    var photos = [Photo]()
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    var blockOperations: [BlockOperation] = [BlockOperation]()
    var indicesSelected = [IndexPath:Photo]()
    //MARK: Outlets
    @IBOutlet weak var photosAlbumCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomActionbarButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noteLabel: UILabel!

    //MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.addAnnotation(currentannotation!)
        if currentPin?.photos.count > 0 {
            //get from db
            self.bottomActionbarButton.isEnabled = true
        } else {
            //case: when downloading images already done with no images
            if currentPin?.isPhotosDownloaded == true {
                noteLabel.isHidden = false
            }
            
        }

        NotificationCenter.default.addObserver(self, selector: #selector(PhotosViewController.photosHaveBeenFetched(_:)), name: NSNotification.Name(rawValue: FETCHING_PHOTOS_FOR_PIN), object: nil)

        collectionView.allowsMultipleSelection = true

        do {
            // Step 2: Perform the fetch
            try fetchedResultsController.performFetch()
        } catch _ {
        }

        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self

        // back button
        let backbutton = UIBarButtonItem()
        backbutton.title = "OK"
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backbutton

    }
    override func viewDidAppear(_ animated: Bool) {
        let clocation = CLLocation(latitude: currentannotation!.coordinate.latitude, longitude: currentannotation!.coordinate.longitude)
        centerMapOnLocation(clocation)
    }
    func photosHaveBeenFetched(_ notification: Notification) {
        let object: AnyObject?  = notification.object as AnyObject?
        let err: Int? = object?.value(forKey: "error") as? Int
        let finished = object?.value(forKey: "finished") as? Int

        if let erro = err , erro == 1 && finished == 1 {
            noteLabel.isHidden = false
        } else {
            noteLabel.isHidden = true
        }
        self.bottomActionbarButton.isEnabled = true

    }

    lazy var fetchedResultsController: NSFetchedResultsController<Photo>  = {
        let fetchRequest =  NSFetchRequest<Photo>(entityName: "Photo")
 
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.currentPin!);

        let fetchedResultsController = NSFetchedResultsController<Photo>(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController

        }()

    //MARK: New Collection button
    @IBAction func bottomBarButtonTapped(_ sender: UIBarButtonItem) {
        if isThereAnySelectedPhoto() {
            deleteCells(UIButton())
        } else {
            //Delete all photos and cells
//            unHighLighAll()
            cancelAllImagesDownloadTasks()
            deleteAllPhotos()
            self.bottomActionbarButton.isEnabled = false
            VLTPhotosFetcher.fetchPhotosForPin(self.currentPin!, context: sharedContext)
            
        }
    }

    func centerMapOnLocation(_ location: CLLocation) {
        let regionRadius: CLLocationDistance = 10000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius , regionRadius )
        mapView.setRegion(coordinateRegion, animated: true)
    }


    //MARK: MapView Delegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
             let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // 2
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.animatesDrop = true
            }
            return view
    }

    

    deinit {
        // Cancel all block operations when VC deallocates
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepingCapacity: false)
    }




}
//MARK: UICollectionViewDelegateFlowLayout - orientation
extension PhotosViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.collectionView.performBatchUpdates(nil, completion: { (bo) -> Void in
            })
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                print("rotation completed")
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    @objc(collectionView:layout:sizeForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = CGSize(width: UIScreen.main.bounds.size.width/3 - 7.5, height: UIScreen.main.bounds.size.width/3 - 7.5) ;
        return size
    }

}


//MARK: Utility 

extension PhotosViewController {
    func cancelAllImagesDownloadTasks() {
        let count = countOfEntities()
        if count == 0 {return}

        for i  in collectionView.indexPathsForVisibleItems {
            let cell = collectionView.cellForItem(at: i ) as! VLTPhotoCollectionViewCell
            cell.taskToCancelifCellIsReused = cell.task
        }

    }
    func deleteAllPhotos() {
        //FIXME: Should not be fixed number
        let count = countOfEntities()
        if count == 0 {return}
        for i  in 0...countOfEntities()-1 {
            let photo = fetchedResultsController.object(at: IndexPath(row: i, section: 0))
            deletePhoto(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    func deletePhoto(_ _photo: Photo) {
        self.sharedContext.delete(_photo)
    }
    func countOfEntities() -> Int {
        let context = sharedContext
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.currentPin!);
        let count = try! context.count(for: fetchRequest)
        return count
    }

    func photoForIndex(_ indexPath: IndexPath) -> Photo {
        return fetchedResultsController.object(at: indexPath)
    }

    
}
