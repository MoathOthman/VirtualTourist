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
let NO_PIN_IMAGES = "This pin has no images"
let DELETE_SELECTED_PHOTOS = "Remove Selected Pictures"
let NEW_COLLECTION = "New Collection"

class PhotosViewController: UIViewController,MKMapViewDelegate, UICollectionViewDataSource,UICollectionViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    var currentannotation:MKAnnotation?
    var currentPin: Pin?
    var photos = [Photo]()
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    var blockOperations: [NSBlockOperation] = [NSBlockOperation]()
    var indicesSelected = [NSIndexPath:Photo]()
    //MARK: Outlets
    @IBOutlet weak var photosAlbumCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomActionbarButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var noteLabel: UILabel!

    //MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.addAnnotation(currentannotation)
        if currentPin?.photos.count > 0 {
            //get from db
            self.bottomActionbarButton.enabled = true
        } else {
            //case: when downloading images already done with no images
            if currentPin?.isPhotosDownloaded == true {
                noteLabel.hidden = false
            }
            
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("photosHaveBeenFetched:"), name: FETCHING_PHOTOS_FOR_PIN, object: nil)

        collectionView.allowsMultipleSelection = true

        // Step 2: Perform the fetch
        fetchedResultsController.performFetch(nil)

        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self

        // back button
        var backbutton = UIBarButtonItem()
        backbutton.title = "OK"
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backbutton

    }
    override func viewDidAppear(animated: Bool) {
        let clocation = CLLocation(latitude: currentannotation!.coordinate.latitude, longitude: currentannotation!.coordinate.longitude)
        centerMapOnLocation(clocation)
    }
    func photosHaveBeenFetched(notification: NSNotification) {
        let object: AnyObject?  = notification.object
        let err: Int? = object?.valueForKey("error") as? Int
        let finished = object?.valueForKey("finished") as? Int

        if let erro = err where erro == 1 && finished == 1 {
            noteLabel.hidden = false
        } else {
            noteLabel.hidden = true
        }
        self.bottomActionbarButton.enabled = true

    }

    lazy var fetchedResultsController: NSFetchedResultsController = {

        let fetchRequest = NSFetchRequest(entityName: "Photo")

        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.currentPin!);

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        return fetchedResultsController

        }()

    //MARK: New Collection button
    @IBAction func bottomBarButtonTapped(sender: UIBarButtonItem) {
        if isThereAnySelectedPhoto() {
            deleteCells(UIButton())
        } else {
            //Delete all photos and cells
//            unHighLighAll()
            cancelAllImagesDownloadTasks()
            deleteAllPhotos()
            self.bottomActionbarButton.enabled = false
            VLTPhotosFetcher.fetchPhotosForPin(self.currentPin!, context: sharedContext)
            
        }
    }

    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 10000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            regionRadius , regionRadius )
        mapView.setRegion(coordinateRegion, animated: true)
    }


    //MARK: MapView Delegate
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation   {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
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
        return nil
    }

    

    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepCapacity: false)
    }




}
//MARK: UICollectionViewDelegateFlowLayout - orientation
extension PhotosViewController {
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.collectionView.performBatchUpdates(nil, completion: { (bo) -> Void in
            })
            }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
                println("rotation completed")
        })
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size = CGSizeMake(UIScreen.mainScreen().bounds.size.width/3 - 7.5, UIScreen.mainScreen().bounds.size.width/3 - 7.5) ;
        return size
    }

}


//MARK: Utility 

extension PhotosViewController {
    func cancelAllImagesDownloadTasks() {
        let count = countOfEntities()
        if count == 0 {return}

        for i  in collectionView.indexPathsForVisibleItems() {
            let cell = collectionView.cellForItemAtIndexPath(i as! NSIndexPath) as! VLTPhotoCollectionViewCell
            cell.taskToCancelifCellIsReused = cell.task
        }

    }
    func deleteAllPhotos() {
        //FIXME: Should not be fixed number
        let count = countOfEntities()
        if count == 0 {return}
        for i  in 0...countOfEntities()-1 {
            let photo = fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! Photo
            deletePhoto(photo)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    func deletePhoto(_photo: Photo) {
        self.sharedContext.deleteObject(_photo)
    }
    func countOfEntities() -> Int {
        let context = sharedContext
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.currentPin!);
        let count = context.countForFetchRequest(fetchRequest, error: nil)
        return count
    }

    func photoForIndex(indexPath: NSIndexPath) -> Photo {
        return fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
    }

    
}