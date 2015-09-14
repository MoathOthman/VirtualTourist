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

    //MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.addAnnotation(currentannotation)
        if currentPin?.photos.count > 0 {
            //get from db
        } else {
            callAPIAndSaveToDB()

        }
        collectionView.allowsMultipleSelection = true

        // Step 2: Perform the fetch
        fetchedResultsController.performFetch(nil)

        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self

    }
    override func viewDidAppear(animated: Bool) {
        let clocation = CLLocation(latitude: currentannotation!.coordinate.latitude, longitude: currentannotation!.coordinate.longitude)
        centerMapOnLocation(clocation)
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

    func callAPIAndSaveToDB() {
        VLTFlickerClient.sharedInstance().getphotosOfLocation(currentPin!.lat.floatValue, longitude: currentPin!.lon.floatValue) { (response, error) -> Void in
            // Handle the error case
            if let error = error {
                println("Error searching for actors: \(error.localizedDescription)")
                return
            }

            // Get a Swift dictionary from the JSON data
            if let photos = response  as? [[String : AnyObject]] {
                 // Create an array of Person instances from the JSON dictionaries
                self.photos = photos.map() {
                    Photo(dictionary: $0, context: self.sharedContext)
                }
                self.currentPin!.photos = NSSet(array: self.photos)
               }
            
        }
    }


    @IBAction func bottomBarButtonTapped(sender: UIBarButtonItem) {
        if isThereAnySelectedPhoto() {
            deleteCells(UIButton())
        } else {
            //Delete all photos and cells
            for i  in 0...19  {
                self.sharedContext.deleteObject(fetchedResultsController.objectAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as! Photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
            callAPIAndSaveToDB()
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

    //MARK:CollectionView Datasource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as!
        NSFetchedResultsSectionInfo
        if sectionInfo.numberOfObjects == 0 {
            collectionView.backgroundColor = UIColor.clearColor()
        }else {
            collectionView.backgroundColor = UIColor.whiteColor()
        }

        return sectionInfo.numberOfObjects

    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let CellIdentifier = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! VLTPhotoCollectionViewCell
        configureCell(cell, photo: photoForIndex(indexPath))
        return cell
    }

    func photoForIndex(indexPath: NSIndexPath) -> Photo {
       return fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
    }
    func configureCell(cell: VLTPhotoCollectionViewCell, photo: Photo) {
        var imageView = cell.contentView.viewWithTag(1) as! UIImageView

        var pinImage = UIImage(named: "posterPlaceHoldr")

        if  photo.url_m == "" {
            pinImage = UIImage(named: "noImage")
        } else if photo.image != nil {
            pinImage = photo.image
        } else {
          let task =  VLTFlickerClient.sharedInstance().taskForImageWithURL(photo.url_m, completionHandler: { (imageData, error) -> Void in
            if let error = error {
                println("Poster download error: \(error.localizedDescription)")
            }

            if let data = imageData {
                // Craete the image
                let image = UIImage(data: data)
                photo.image = image
                 dispatch_async(dispatch_get_main_queue()) {
                     imageView.image = image
                }
            }

        })

        cell.taskToCancelifCellIsReused = task
        }
        imageView.image = pinImage
    }



    //MARK: CollectionView Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
         highlightCell(indexPath, flag: !checkIfPhotoIsAlreadySelected(indexPath))
        bottomActionbarButton.title = "Delete Selected Photos"
    }
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        highlightCell(indexPath, flag: !checkIfPhotoIsAlreadySelected(indexPath))
    }
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }


    //MARK: heighlight cells
    func highlightCell(indexPath : NSIndexPath, flag: Bool) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        let coverView: UIView = cell!.contentView.viewWithTag(2)!
        if flag {
            coverView.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
            indicesSelected[indexPath] = self.photoForIndex(indexPath)
        } else {
            coverView.backgroundColor = nil
            indicesSelected.removeValueForKey(indexPath)
//            indicesSelected.removeAtIndex(indexPath.row)
        }

    }
    func checkIfPhotoIsAlreadySelected(indx: NSIndexPath) -> Bool {
        for foto in indicesSelected.keys {
            if foto == indx {
                return true
            }
        }
        return false
    }
    func isThereAnySelectedPhoto() -> Bool {
        if indicesSelected.count > 0 {
            return true
        }
        return false
    }
    func deleteCells(sender: AnyObject) {

        var deletedPhotos:[Photo] = []

        let indexpaths = collectionView?.indexPathsForSelectedItems()

        if let indexpaths = indexpaths {

        for item  in indexpaths {
        let cell = collectionView!.cellForItemAtIndexPath(item as! NSIndexPath)

        collectionView?.deselectItemAtIndexPath(item as? NSIndexPath, animated: true)
        // fruits for section
        let sectionfruits = indicesSelected[item as! NSIndexPath]
        deletedPhotos.append(sectionfruits!)
            sharedContext.deleteObject(indicesSelected[item as! NSIndexPath]!)
            CoreDataStackManager.sharedInstance().saveContext()
            indicesSelected.removeValueForKey(item as! NSIndexPath)

        }

        collectionView?.deleteItemsAtIndexPaths(indexpaths)
        }
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

//MARK: FetchController Delegate
extension PhotosViewController {
    // MARK: - Fetched Results Controller Delegate


    // In the did change object method:
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        if type == NSFetchedResultsChangeType.Insert {
            println("Insert Object: \(newIndexPath)")

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Update {
            println("Update Object: \(indexPath)")
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Move {
            println("Move Object: \(indexPath)")

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
            println("Delete Object: \(indexPath)")

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
        }
    }

    // In the did change section method:
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

        if type == NSFetchedResultsChangeType.Insert {
            println("Insert Section: \(sectionIndex)")

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Update {
            println("Update Section: \(sectionIndex)")
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
        else if type == NSFetchedResultsChangeType.Delete {
            println("Delete Section: \(sectionIndex)")

            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex))
                    }
                    })
            )
        }
    }

    // And finally, in the did controller did change content method:
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
                collectionView!.performBatchUpdates({ () -> Void in
                    for operation: NSBlockOperation in self.blockOperations {
                        operation.start()
                    }
                    }, completion: { (finished) -> Void in
        //                self.blockOperations.removeAll(keepCapacity: false)
                })


    }




}